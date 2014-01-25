package App::IRCBot::NewYears;

use 5.010;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.001003';



1; # End of App::IRCBot::NewYears

__END__

=encoding utf8

=head1 NAME

App::IRCBot::NewYears - A bot for IRC New Years parties

=head1 RELEASE NOTICE

B<PLEASE NOTE:> this release was hastily coded and several bugs
crept out while the bot ran. In particular, there was something about
several European time zones being off by an hour (summer time, etc).
Then there's also a bug where the bot breaks before (or after) the New
Years in the bot's time zone.

Since this code won't be used for the next 11 months, I'm not going
to bother hunting and fixing those bugs at the moment. Will return to
this code circa December 2014 :)

=head1 SYNOPSIS

#### Command line arguments currently do not work;
#### Channel/server are currently hardcoded
To run (script installs along with the module):

    zoffix@ZofMain:~$ app-ircbot-newyears.pl irc.SERVER.org #Channel

IRC Commands:

    HNYBot,

=head1 DESCRIPTION

The bot announces five minutes prior to the upcoming New Year, for
40 different time zones.
At the announcements, it lists a few countries/cities
in the announced time zone.

The bot can also be queries with a name of a particular place to find out
when the New Year will happen there (as long as Google can figure out
the time for that place).

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-ircbot-newyears at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-IRCBot-NewYears>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::IRCBot::NewYears

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-IRCBot-NewYears>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-IRCBot-NewYears>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-IRCBot-NewYears>

=item * Search CPAN

L<http://search.cpan.org/dist/App-IRCBot-NewYears/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Zoffix Znet.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
