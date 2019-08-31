#!/usr/bin/perl

sub debug (@);

use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDIN, ":utf8");
use open qw/:std :utf8/;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Term::ANSIColor;

my %options = (
	debug => 0,
	nocache => 0,
	language => 'de',
	pause => 1
);

my $tmp = './tmp';
my $sounds = './sounds/';
mkdir $tmp unless -d $tmp;

analyze_args(@ARGV);

my $text = "Das hier ist ein Beispieltext";
convert_text_to_wav($text, "example.wav");

sub convert_text_to_wav {
	my $string = shift;
	my $output = shift // "output.wav";

	my $ipa = convert_string_to_ipa($string);
	$ipa =~ s#[\(\)]# #g;
	print "$ipa\n";

	my @splitted = split //, $ipa;

	my @sounds = ();
	my $i = 0;

	while ($i != $#splitted) {
		my $ipa_laut = $splitted[$i];
		my $found = 0;

		if(($i + 3) <= $#splitted && $splitted[$i] !~ /\s/ && $splitted[$i + 1] !~ /\s/ && $splitted[$i + 2] !~ /\s/ && $splitted[$i + 3] !~ /\s/) {
			my $ipa_next = $splitted[$i].$splitted[$i + 1].$splitted[$i + 2].$splitted[$i + 3];
			my $laut_path = "$sounds/$ipa_next.ogg";

			warn "$ipa_next\n";
			if(-e $laut_path) {
				warn color("blue")."Found >>>$ipa_next<<<!".color("reset")."\n";
				push @sounds, $laut_path;	
				$found = 1;
				$i += 3;
			}
		}

		if(($i + 2) <= $#splitted && $splitted[$i] !~ /\s/ && $splitted[$i + 1] !~ /\s/ && $splitted[$i + 2] !~ /\s/) {
			my $ipa_next = $splitted[$i].$splitted[$i + 1].$splitted[$i + 2];;
			my $laut_path = "$sounds/$ipa_next.ogg";

			warn "$ipa_next\n";
			if(-e $laut_path) {
				warn color("blue")."Found >>>$ipa_next<<<!".color("reset")."\n";
				push @sounds, $laut_path;	
				$found = 1;
				$i += 2;
			}
		}


		if(($i + 1) <= $#splitted && $splitted[$i] !~ /\s/ && $splitted[$i + 1] !~ /\s/) {
			my $ipa_next = $splitted[$i].$splitted[$i + 1];
			my $laut_path = "$sounds/$ipa_next.ogg";

			warn "$ipa_next\n";
			if(-e $laut_path) {
				warn color("blue")."Found >>>$ipa_next<<<!".color("reset")."\n";
				push @sounds, $laut_path;	
				$found = 1;
				$i++;
			}
		}

		if(!$found && $ipa_laut !~ /\s+/) {
			my $laut_path = "$sounds/$ipa_laut.ogg";
			warn "$ipa_laut\n";
			if(-e $laut_path) {
				push @sounds, $laut_path;	
			} else {
				warn color("red")."!!!!!!!!!!!!!!!! $ipa_laut not found!!!!!!".color("reset")."\n";
			}
		} elsif(!$found) {
			my $laut_path = "$sounds/silence.ogg";
			#push @sounds, $laut_path;	
		}
		$i++;
	}

	if(@sounds) {
		my $command = q#sox #.join(' ', @sounds).qq#  $output#;
		print $command;
		system($command);
	} else {
		warn "\@sounds empty!!!";
	}
}

sub convert_string_to_ipa {
	my $string = shift;

	my @splitted = split(/(\b)/, $string);

	my @ipa = ();
	foreach my $word (@splitted) {
		my $ipa_string = '';
		if($word =~ m#^\s*[\.,]+\s*#) {
			if($options{pause}) {
				$ipa_string = ':::PAUSE:::';
			}
		} else {
			$ipa_string = convert_word_to_ipa($word);
		}
		push @ipa, $ipa_string;
	}

	my $ret = join(' ', map { chomp $_; s#\s# #g; $_ } @ipa);
	$ret =~ s#\s+# #g;

	return $ret;
}

sub convert_word_to_ipa {
	my $string = shift;
	return '' if $string =~ m#^\s*$#;
	debug "convert_word_to_ipa($string)";
	$string = lc($string);
	#$string =~ s#(?=![^\s])\W#XXX#g;
	my $cache_file = "$tmp/".md5_hex($string);
	if(!-e $cache_file || $options{nocache}) {
		my $normal_file = $cache_file."_normal";
		write_file($normal_file, $string);
		my $command = "phonemize -l de -b espeak $normal_file -o $cache_file";
		print "$command\n";
		system($command);
	}
	my $phonems = read_file($cache_file);
	return $phonems;
}

sub write_file {
	my ($filename, $contents) = @_;

	open my $fh, '>', $filename;
	print $fh $contents;
	close $fh;
}

sub read_file {
	my $filename = shift;
	debug "read_file($filename)";

	my $contents = '';

	open my $fh, '<', $filename;
	while (<$fh>) {
		$contents .= $_;
	}

	return $contents;
}

sub analyze_args {
	my @args = @_;

	foreach (@args) {
		if(m#^--debug$#) {
			$options{debug} = 1;
		} elsif (m#^--nocache$#) {
			$options{nocache} = 1;
		} elsif (m#^--language=(\w*)$#) {
			$options{language} = $1;
		} elsif (m#^--nopause$#) {
			$options{pause} = 0;
		} else {
			die "Unknown parameter: $_";
		}
	}
}

sub debug (@) {
	if($options{debug}) {
		foreach (@_) {
			warn "DEBUG: $_\n";
		}
	}
}
