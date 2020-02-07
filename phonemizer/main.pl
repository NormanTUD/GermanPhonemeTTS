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
use Memoize;
use utf8::all;

memoize 'speak_word';

my %options = (
	debug => 0,
	nocache => 0,
	language => 'de',
	pause => 1,
	text => ''
);

my $tmp = './tmp';
my $sound_path = './sounds/';
my $max_phoneme_length = length([
		sort { length($b) <=> length($a) } 
			map { s#^$sound_path/##g; s#\.ogg$##g; $_ } 
				grep { not /^\.\.?$/ } grep { -f } 
					glob("$sound_path/*.ogg")]->[0]
	); # search for longest file without $sound_path and .ogg in $sound_path
mkdir $tmp unless -d $tmp;

analyze_args(@ARGV);

my $text = $options{text};
convert_text_to_ogg($text);

sub convert_text_to_ogg {
	my $string = shift;
	my $output = shift // "output.wav";

	my $ipa = convert_string_to_ipa($string);
	$ipa =~ s#\(.*?\)# #g;
	$ipa =~ s#[\(\)]# #g;
	$ipa =~ s#:::PAUSE:::##g;
	print "$ipa\n";


	my @sounds = ();

	foreach my $word (split/\s/, $ipa) {
		my $spoken = speak_word($word);
		if($spoken) {
			push @sounds, $spoken;
		}
	}

	if(@sounds) {
		merge_sounds($output, @sounds);
		foreach (@sounds) {
			unlink $_;
		}
	} else {
		warn "\@sounds empty!!!";
	}
}

sub merge_sounds {
	my $name = shift;
	return unless $name;
	my @sounds = @_;
	@sounds = grep { $_ ne ':::PAUSE:::' } @sounds;
	foreach (@sounds) {
		die "ERROR! $_ not found" unless -e $_;
	}
	my $command = q#sox #.join(' ', @sounds).qq# $name#;
	print "$command\n";
	system($command);
	return $name;
}

sub speak_word {
	my $ipa = shift;
	return undef if !$ipa;
	my $tmp_file = "$tmp/$ipa.ogg";
	return $tmp_file if -e $tmp_file;
	my @splitted = split //, $ipa;
	my $i = 0;
	my @sounds = ();

	while ($i <= $#splitted) {
		my $ipa_laut = $splitted[$i];
		my $found = 0;
		THISFOR: for my $around (reverse(0 .. $max_phoneme_length)) {
			next if length($ipa) < $around;
			($found, $i) = check_next_n_tokens($i, $found, $around, \@sounds, \@splitted) if length($ipa) >= $around;
			last THISFOR if $found;
		}
		$i++;
	}
	merge_sounds($tmp_file, @sounds);
	return $tmp_file;
}

sub check_next_n_tokens {
	my $i = shift;
	my $found = shift;
	my $n = shift;
	my $sounds = shift;
	my $splitted = shift;

	if(($i + $n) <= (scalar @{$splitted} - 1) && !$found) {
		my $none_next_characters_empty = 1;
		CHECK_EMPTY_CHARS: foreach my $m ($i .. ($i + $n)) {
			if($splitted->[$m] =~ /\s/) {
				$none_next_characters_empty = 0;
				last CHECK_EMPTY_CHARS;
			}
		}

		if($none_next_characters_empty) {
			my $ipa_next = join('', map { $splitted->[$_] } ($i .. ($i + $n)));
			my $laut_path = "$sound_path/$ipa_next.ogg";

			warn "$ipa_next\n";
			if(-e $laut_path) {
				warn color("blue")."Found >>>$ipa_next<<<!".color("reset")."\n";
				push @{$sounds}, $laut_path;	
				$found = 1;
				$i += $n;
			}
		}
	}

	return +($found, $i);
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
			$word =~ s#[^\w\d]##g;
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
		my $command = "phonemize -l $options{language} -b espeak $normal_file -o $cache_file";
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
		} elsif (m#^--text=(.+)$#) {
			$options{text} = $1;
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
