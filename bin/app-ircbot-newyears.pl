#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use DateTime 1.03;
use Date::Manip 6.36;
use Number::Denominal 1.104;
use Encode 2.55;

use POE qw(Component::IRC  Component::IRC::Plugin::WWW::Google::Time
    Component::IRC Component::IRC::Plugin::Connector
    Component::IRC::Plugin::BotAddressed
);
our $VERSION = '1.001003';

 my @channels = ('#zofbot', '#freenode-newyears', '#freenode-newyears-nospam');
#my @channels = ('#zofbot');

my @Week_Days = (
    qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/
);

my @Ignore = [

];


my $Current_Year = (localtime)[5] + 1900;
my $Jan_1_Week_Day  = UnixDate("5AM January 1, $Current_Year", '%s');
my $New_Year_Week_Day =$Week_Days[ (localtime $Jan_1_Week_Day)[6] ];

my $irc = POE::Component::IRC->spawn(
    nick        => 'NewYearsBot',
     server      => 'irc.freenode.net',
    #server      => 'localhost',
    port        => 6667,
    ircname     => 'NewYearsBot',
    debug       => 1,
);

POE::Session->create(
    package_states => [
        main => [ qw(_start  irc_001  irc_google_time
            _announce_new_year
            lag_o_meter
            irc_bot_addressed
        ) ],
    ],
);

$poe_kernel->run;

sub _start {
    my ($kernel, $heap) = @_[KERNEL ,HEAP];

    $irc->yield( register => 'all' );


    $heap->{connector} = POE::Component::IRC::Plugin::Connector->new();
    $irc->plugin_add( 'BotAddressed',
        POE::Component::IRC::Plugin::BotAddressed->new()
    );
    $irc->plugin_add( 'Connector' => $heap->{connector} );
    $kernel->delay( 'lag_o_meter' => 60 );


    $irc->plugin_add(
        'google_time' =>
            POE::Component::IRC::Plugin::WWW::Google::Time->new(
                trigger => qr/^h(appy)?\s*n(ew)?\s*y(ears?)?\s+(?=\S)/i,
                auto    => 0,

            ),
    );

    $irc->yield( connect => {} );


    my @offsets = get_UTC_offsets();    my $my_offset = DateTime->now;

    my $did_announce_on_join = 0;
    for ( reverse 0..$#offsets ) {
        my $tz = $offsets[ $_ ];
        my $seconds_to_new_year = UnixDate("January 1, 2014", "%s")
            - (
                UnixDate(DateTime->now, "%s") + $tz->{offset}
            );

        print Dumper [
            $tz,
            $seconds_to_new_year,
        ];

        next if $seconds_to_new_year <= 0;

        unless ( $did_announce_on_join++ ) {
            $_[KERNEL]->alarm_set( _announce_new_year
		=> time() + 15
                => 'Next New Year is in '
                . denominal( $seconds_to_new_year,
                    \'time',
                ) . ' at ' . $tz->{tz}
            ); 
        }

        $_[KERNEL]->alarm_set( _announce_new_year
            => time() + $seconds_to_new_year
            => "Happy New Year to [$tz->{tz}] $tz->{location}",
        );

        if ( $_ == 0 ) {
            $_[KERNEL]->alarm_set(
                _announce_new_year => time() + $seconds_to_new_year + 2
                => 'That was the last new year for this year! '
                    . 'Happy New Year, everyone!',
            );
        }
        else {
            $_[KERNEL]->alarm_set(
                _announce_new_year => time() + $seconds_to_new_year + 2
                => 'Next New Year is in '
                . denominal( $offsets[$_-1]->{offset} - $tz->{offset},
                    \'time',
                ) . ' at ' . $offsets[$_-1]->{tz}
            );
        }
    }
}

# sub _default {
#     print Dumper [
#         $_[ARG0],
#         $_[ARG1],
#         $_[ARG2],
#     ];
# }

sub irc_bot_addressed {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $who = $_[ARG0];
    my $nick = ( split /!/, $_[ARG0] )[0];
    my $channel = $_[ARG1]->[0];
    my $what = $_[ARG2];

    print "$nick addressed me in channel $channel with the message '$what'\n";

    return if grep $who =~ /$_/, @Ignore;

    if ( $what =~ /^help\b/i ) {
        $_[KERNEL]->post( $irc => 'privmsg' => $channel =>
            "$nick, available commands: hny YOUR_LOCATION  and  source",
        );
    }
    elsif ( $what =~ /^source\b/i ) {
        $_[KERNEL]->post( $irc => 'privmsg' => $channel =>
            "$nick, I'm a Perl bot. You can install me by using cpan "
                . "App::IRCBot::NewYears or "
                . "see https://metacpan.org/pod/App::IRCBot::NewYears"
                . " or https://github.com/zoffixznet/App-IRCBot-NewYears"
        );
    }
    elsif ( $who =~ m{(\@unaffiliated/zoffix|\@localhost)$}i ) {
        if ( $what =~ s/^ignore\s+//i ) {
            my $ignore = qr/$what/i;
            push @Ignore, $ignore;
            $_[KERNEL]->post( $irc => 'privmsg' => $channel =>
                "$nick, all done, boss! Stuffed $ignore into ignore list."
            );
        }
        elsif ( $what eq 'clear ignore' ) {
            @Ignore = ();
            $_[KERNEL]->post( $irc => 'privmsg' => $channel =>
                "$nick, it's now clean like a fresh OS install"
            );
        }
    }
}

sub lag_o_meter {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    print 'Time: ' . time() . ' Lag: ' . $heap->{connector}->lag() . "\n";
    $kernel->delay( 'lag_o_meter' => 60 );
    return;
}

sub _announce_new_year {
    my ( $kernel, $self, $msg ) = @_[KERNEL, OBJECT, ARG0];

    $_[KERNEL]->post( $irc => privmsg => $_ => $msg )
        for @channels;
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => $_ )
        for @channels;
}

sub irc_google_time {
    my $result = $_[ARG0];

    return if grep $result->{who} =~ /$_/, @Ignore;

    my ( $who ) = split /!/, $result->{who};

    if ( $result->{error} ) {
        $_[KERNEL]->post( $irc =>
            $result->{type} eq 'public' ? 'privmsg' : $result->{type}
            => $result->{type} eq 'public' ? $result->{channel} : $who
            => "$who, where the hell is that place?",
        );

        return;
    }

    my $date = $result->{result};

    my $is_in_the_past
    = UnixDate($date->{day_of_week}, '%s') - time > 14*3600;

    my $location_time = UnixDate(
        $date->{time}
        . ( $is_in_the_past ? ' last ' : ' ' )
        . $date->{day_of_week},
        '%s',
    );

    my $ny_time = UnixDate(
        'January 1, ' . ( (localtime)[5] + 1900 ),
        '%s',
    );

    my $delta = $ny_time - $location_time;

    print Dumper [
        $date,
        ~~localtime $ny_time,
        ~~localtime $location_time,
        $delta,

    ];

    my $response = 'The New Year ';
    if ( $delta <= 0 ) {

        $response .= "already happened in $date->{where} "
            . denominal($delta, \'time') . ' ago';
    }
    else {
        $response .= "in $date->{where} will happen in "
            . denominal($delta, \'time');
    }


    print Dumper $result;

    $_[KERNEL]->post( $irc =>
        $result->{type} eq 'public' ? 'privmsg' : $result->{type}
        => $result->{type} eq 'public' ? $result->{channel} : $who
        => "$who, $response",
    );
}


sub get_UTC_offsets {
    return (
    {
        tz      => 'UTC-12:00, Y',
        offset => '-43200',
        location => 'US Minor Outlying Islands [Baker Island, Howland Island]',
    },

    {
        tz  => 'UTC-11:00, X',
        offset => '-39600',
        location => 'US [American Samoa, Hawaii], New Zealand [Niue]',
    },

    {
        tz  => 'UTC-10:00, W',
        offset => '-36000',
        location => 'France [French Polynesia], New Zealand [Cook Islands], US [Alaska, Hawaii]',
    },

    {
        tz  => 'UTC-09:30, V+',
        offset => '-34200',
        location => 'France [French Polynesia, Marquesas Islands]',
    },

    {
        tz  => 'UTC-09:00, V',
        offset => '-32400',
        location => 'France [French Polynesia, Gambier Islands], US [Alaska]',
    },

    {
        tz  => 'UTC-08:00, U',
        offset => '-28800',
        location => 'Canada [BC, YK], France [Clipperton Island], UK [Pitcairn Islands], Mexico [Baja California], US [CA, ID, NV, OR, WA]',
    },

    {
        tz  => 'UTC-07:00, T',
        offset => '-25200',
        location => 'Canada, Mexico, US',
    },

    {
        tz  => 'UTC-06:00, S',
        offset => '-21600',
        location => 'Belize, Canada, Chile, Costa Rica, Ecuador, El Salvador, Guatemala, Honduras, Mexico, Nicaragua, US',
    },

    {
        tz  => 'UTC-05:00, R',
        offset => '-18000',
        location => 'Bahamas, Brazil, Canada, Colombia, Cuba, Ecuador, Haiti, Jamaica, Panama, Peru, UK, US',
    },

    {
        tz  => 'UTC-04:30, Q+',
        offset => '-16200',
        location => 'Venezuela',
    },
    {
        tz  => 'UTC-03:30, P+',
        offset => '-12600',
        location => 'Canada [Newfoundland and Labrador]',
    },

    {
        tz  => 'UTC-03:00, P',
        offset => '-10800',
        location => 'Argentina, Brazil, Denmark, France, Suriname, UK, Uruguay',
    },

    {
        tz  => 'UTC-02:00, O',
        offset => '-7200',
        location => 'Brazil [Fernando de Noronha], UK [South Georgia and the South Sandwich Islands]',
    },

    {
        tz  => 'UTC-01:00, N',
        offset => '-3600',
        location => 'Cape Verde, Denmark [Ittoqqortoormiit and surrounding area], Portugal [Azores islands]',
    },

    {
        tz  => 'UTC±00:00, Z',
        offset => '0',
        location => 'Denmark, Gambia, Ghana, Guinea, Iceland, Ireland, Liberia, Mali, Mauritania, Morocco, Portugal, Spain, Senegal, Togo, UK, and others',
    },

    {
        tz  => 'UTC+01:00, A',
        offset => '3600',
        location => 'Albania, Algeria, Austria, Belgium, Croatia, Czech Republic, Denmark, France, Germany, Hungary, Italy, Malta, Monaco, Netherlands, Nigeria, Norway, Poland, Spain, Sweden, Switzerland, UK, and many others',
    },

    {
        tz  => 'UTC+02:00, B',
        offset => '7200',
        location => 'Bulgaria, Egypt, Estonia, Finland, Greece, Israel, Lithuania, Libya, Moldova, Romania, Rwanda, South Africa, Syria, Turkey, Ukraine, UK, Zimbabwe, and many others',
    },

    {
        tz  => 'UTC+03:00, C',
        offset => '10800',
        location => 'Belarus, Ethiopia, France, Iraq, Kenya, Kuwait, Madagascar, Russia, Somalia, South Africa, Sudan, Tanzania, Uganda, Yemen, and others',
    },

    {
        tz  => 'UTC+03:30, C+',
        offset => '12600',
        location => 'Iran [Tehran]',
    },

    {
        tz  => 'UTC+04:00, D',
        offset => '14400',
        location => 'Armenia, Azerbaijan, France, Georgia, Mauritius, Oman, Russia, Seychelles, United Arab Emirates',
    },

    {
        tz  => 'UTC+04:30, D+',
        offset => '16200',
        location => 'Afghanistan [Kabul]',
    },

    {
        tz  => 'UTC+05:00, E',
        offset => '18000',
        location => 'Australia, France [French Southern and Antarctic Lands], Kazakhstan, Maldives, Pakistan, Tajikistan, Turkmenistan, Uzbekistan',
    },

    {
        tz  => 'UTC+05:30, E+',
        offset => '19800',
        location => 'India and Sri Lanka',
    },

    {
        tz  => 'UTC+05:45, E+',
        offset => '20700',
        location => 'Nepal [Kathmandu]',
    },

    {
        tz => 'UTC+06:00, F',
        offset => '21600',
        location => 'Bangladesh, Bhutan, Kazakhstan, Kyrgyzstan, Russia, UK [British Indian Ocean Territory]',
    },

    {
        tz  => 'UTC+06:30, F+',
        offset => '23400',
        location => 'Australia [Cocos (Keeling) Islands], Myanmar',
    },

    {
        tz  => 'UTC+07:00, G',
        offset => '25200',
        location => 'Australia, Cambodia, Indonesia, Laos, Mongolia, Russia, Thailand, Vietnam',
    },

    {
        tz  => 'UTC+08:00, H',
        offset => '28800',
        location => 'Australia, Brunei, China, Indonesia, Malaysia, Mongolia, Philippines, Russia, Singapore, Taiwan',
    },

    {
        tz  => 'UTC+08:45',
        offset => '31500',
        location => 'Australia [Western Australia, Eucla]',
    },

    {
        tz  => 'UTC+09:00, I',
        offset => '32400',
        location => 'Indonesia, Japan, North Korea, South Korea, Palau, Russia, Timor-Leste',
    },

    {
        tz  => 'UTC+09:30, I+',
        offset => '34200',
        location => 'Australia [Northern Territory and South Australia, Adelaide]',
    },

    {
        tz  => 'UTC+10:00, K',
        offset => '36000',
        location => 'Australia, Federated States of Micronesia, Papua New Guinea, Russia, US [Guam, Northern Mariana Islands]',
    },

    {
        tz  => 'UTC+10:30, K+',
        offset => '37800',
        location => 'Australia [New South Wales, Lord Howe Island]',
    },

    {
        tz  => 'UTC+11:00, L',
        offset => '39600',
        location => 'Federated States of Micronesia, France, Russia, Solomon Islands, Vanuatu',
    },

    {
        tz  => 'UTC+11:30, L+',
        offset => '41400',
        location => 'Australia [Norfolk Island]',
    },

    {
        tz  => 'UTC+12:00, M',
        offset => '43200',
        location => 'Antarctica, France, Fiji, Kiribati, Marshall Islands, Nauru, New Zealand, Russia, Tuvalu, US [Wake Island]',
    },

    {
        tz  => 'UTC+12:45, M+',
        offset => '45900',
        location => 'New Zealand [Chatham Islands]',
    },

    {
        tz  => 'UTC+13:00, M+',
        offset => '46800',
        location => 'Kiribati [Phoenix Islands], New Zealand [Tokelau], Samoa, Tonga',
    },

    {
        tz  => 'UTC+14:00, M+',
        offset => '50400',
        location => 'Kiribati [Line Islands]',
    },
);
}

__END__

=pod

See perldoc App::IRCBot::NewYears or metacpan.org/pod/App::IRCBot::NewYears
for documentation

=cut