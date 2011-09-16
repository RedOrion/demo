#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use FindBin::libs;

#
# Recurse all directories to find all .pl .pm and .pod files and
# extract the pod (if any) from them
#
my $index_html = '';

my $pod_dir = "$FindBin::Bin/../root/static/pod/";
my $top_dir = "$FindBin::Bin/../";

process_dir($pod_dir, $top_dir, "pod", 1);
process_dir($pod_dir, $top_dir, "lib",1);
process_dir($pod_dir, $top_dir, "tools",1);
#process_dir($pod_dir, $top_dir, "t",1);

open FH, ">${pod_dir}index.html" or die "Cannot open pod index file for writing";
print FH index_head();
print FH $index_html;
print FH index_tail();
close FH;

sub process_dir {
    my ($pod_dir, $top_dir, $sub_dir, $recurse) = @_;

    # Ignore hidden (e.g. subversion or git) directories
    return if $sub_dir =~ m/\/\./;

    opendir DIR, $top_dir.$sub_dir or return;
    my @contents = map "${top_dir}${sub_dir}/$_", sort grep !/^\.\.?$/, readdir DIR;
    close DIR;

FILENAME:
    for my $filename (@contents) {

        # Ignore hidden (e.g. subversion or git) files
        next FILENAME if $filename =~ m/^\./;

        if (-d $filename) {
            if ($recurse) {
                $filename =~ s/^$top_dir//;
                process_dir($pod_dir, $top_dir, $filename, 1);
            }
        }
        else {
            next FILENAME if $filename !~ m/\.(pm|pl|pod|t)$/;
            my $output_filename = $filename;
            $output_filename =~ s/^$top_dir//;
            $output_filename =~ s{^../}{};
            my $display_filename = $output_filename;
            $output_filename =~ s{/}{-}g;
            $output_filename =~ s{\.}{-}g;
            $output_filename = "$output_filename.html";

            my $output = ` perldoc -ohtml $filename`;

            # Replace X<tags> with relative links to other documents
XTAG:
            while (1) {
                my ($pre,$match,$post) = $output =~ m/(^.*)(<!--\s*INDEX:\s[^\s]*\s--\>)(.*$)/s;
                last XTAG if ! $pre;

                $match =~ s/\<!--\s*INDEX:\s*//;
                $match =~ s/\s--\>//;
                my $link = $match;

                # Handle pm modules
                if ($match =~ m/\.pm$/) {
                    $match =~ s/lib\///;
                    $match =~ s/\.pm$//;
                    $match =~ s/\//::/g;
                }
                # make href
                $link =~ s{/}{-}g;
                $link =~ s{\.}{-}g;
                $link .= ".html";

                $output = $pre."<!--PODLINK--><a href='$link' class='podlinkpod'>$match</a>".$post;
            }

#            $output =~ s/\<!--\s*INDEX:\s([^\s]*)\s--\>/\<a href="$1\.html" class="podlinkpod" \>$1\<\/a\>/sm;

            if ($output) {
                # Remove the header produced by perldoc
                $output =~ s{.*-- start doc -->}{}s;

                # Remove the footer produced by perldoc
                $output =~ s{</body></html>}{};

                open FH, ">${pod_dir}$output_filename" or die "Cannot open file [$pod_dir][$output_filename]";
                print FH $output;
                close FH;
                $index_html .= index_entry($display_filename, $output_filename);
            }
            else {
                $index_html .= index_error($display_filename, $output_filename);
            }
        }
    }
}

sub index_head {
    return <<"EOS";
<ul>
EOS
}

sub index_tail {
    return <<"EOS";
</ul>
EOS
}

sub index_entry {
    my ($display_filename,$output_filename) = @_;

    return <<"EOS";
<li><a href="/pod/$output_filename">$display_filename</a></li>
EOS
}

sub index_error {
    my ($display_filename,$output_filename) = @_;

    return <<"EOS";
<li>$display_filename <strong>has no pod</strong></li>
EOS
}

=pod

=head1 NAME

Extract POD documentation

=head1 SYNOPSIS

Extracts the POD documentaton from the perl modules and
converts them to HTML ready for them to be displayed in
the application.

=head1 DESCRIPTION

  ./make_pod.pl

=head1 SEE ALSO

Full list of documents X<index>

=head1 AUTHOR

Ian Docherty

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
