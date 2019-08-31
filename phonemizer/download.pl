#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;

my $sounds = './sounds/';
mkdir $sounds unless -d $sounds;

my $site = get("http://www.ipachart.com/");

while ($site =~ m#<td class="interactive IPA" onclick="ipa\('([^']+)'\);">([^<]+)</td>#g) {
	my $filename_online = $1;
	my $filename_local = $2;

	my $url = "http://www.ipachart.com/ogg/$filename_online.ogg";

	my $local_path = "$sounds/$filename_local.ogg";

	my $command = "wget $url -O $local_path";
	#die "\n\n$&\n\n$command\n";
	if(!-e $local_path) {
		system($command);
	}
}
