#!/usr/bin/perl

use strict;
use warnings;

use XML::Twig;

my ($keyword, $filename) = @ARGV;

XML::Twig->new(
    'pretty_print'  => 'indented_a',
    'twig_handlers' => {
        'service[@name="'.$keyword.'"]' => sub { $_->print }
    }
)->parsefile($filename);
