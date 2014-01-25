#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 12;

BEGIN {
    use_ok('Data::Dumper');
    use_ok('DateTime');
    use_ok('Date::Manip');
    use_ok('Number::Denominal');
    use_ok('Encode');
    use_ok('POE');
    use_ok('POE::Component::IRC');
    use_ok('POE::Component::IRC::Plugin::WWW::Google::Time');
    use_ok('POE::Component::IRC');
    use_ok('POE::Component::IRC::Plugin::Connector');
    use_ok('POE::Component::IRC::Plugin::BotAddressed');

    use_ok( 'App::IRCBot::NewYears' ) || print "Bail out!\n";
}

diag( "Testing App::IRCBot::NewYears $App::IRCBot::NewYears::VERSION, Perl $], $^X" );
