#!/home/docherti/perl5/perlbrew/perls/perl-5.12.4/bin/perl
use strict;
use warnings;

use FindBin::libs;
use Data::Dumper;

use System::Command;

my ($pid, $in, $out, $err) = System::Command->spawn('./simple_io.pl');

# An non-blocking filehandle read that returns an array of lines read
# Returns:  ($eof,@lines)
my %nonblockGetLines_last;
sub nonblockGetLines {
	my ($fh,$timeout) = @_;

	$timeout = 0 unless defined $timeout;
	my $rfd = '';
	$nonblockGetLines_last{$fh} = ''
		unless defined $nonblockGetLines_last{$fh};
#print "about to call vec\n";
	vec($rfd,fileno($fh),1) = 1;
#print "return from vec\n";
	return unless select($rfd, undef, undef, $timeout)>=0;
#print "after select\n";
	# I'm not sure the following is necessary?
	return unless vec($rfd,fileno($fh),1);
	my $buf = '';
	my $n = sysread($fh,$buf,1024*1024);
	# If we're done, make sure to send the last unfinished line
	return (1,$nonblockGetLines_last{$fh}) unless $n;
	# Prepend the last unfinished line
	$buf = $nonblockGetLines_last{$fh}.$buf;
	# And save any newly unfinished lines
	$nonblockGetLines_last{$fh} =
		(substr($buf,-1) !~ /[\r\n]/ && $buf =~ s/([^\r\n]*)$//) ? $1 : '';
	$buf ? (0,split(/\n/,$buf)) : (0);
}

{
    my $ofh = select $out;
    $| = 1;
    select $ofh;
}


#$fh = new IO::File; open($fh,"$cmd 2>&1 |");
my ($eof,@lines);

do {
	($eof,@lines) = nonblockGetLines($out);
print "got here\n";
	foreach my $line ( @lines ) {
		print "Pipe saw: [$line]\n";
	}
} until $eof;

#print $in "staohensthaou\n";

#while (my $line = <$out>) {
#    chomp $line;
#    print "### [$line] ###\n";
#}

