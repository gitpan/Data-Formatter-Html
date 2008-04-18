# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Formatter-Html.t'

#########################

use Test::More tests => 6;
BEGIN { use_ok('Data::Formatter::Html') };

can_ok('Data::Formatter::Html', 'format', 'out');

like(Data::Formatter::Html->format('Hello'), qr/Hello/s, 'Simple scalar formatted');
like(Data::Formatter::Html->format(['One', 'Two', 'Three']), qr/One.*Two.*Three/s, 'Simple list formatted');
like(Data::Formatter::Html->format(\['One', 'Two', 'Three']), qr/One.*Two.*Three/s, 'Simple ordered list formatted');
like(Data::Formatter::Html->format({bob => 12, joe => 34}), qr/bob.*12.*joe.*34/s, 'Simple definition list formatted');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

