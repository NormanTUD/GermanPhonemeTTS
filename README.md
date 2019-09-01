# Idea

The idea for this script is very simple: record some phonemes for the german language, split words into phonemes
(done by https://github.com/bootphon/phonemizer ), and then try to find the longest matching audio file so that the
phonemes match.

The result is far from perfect, but way better than I've expected it to be.

# Requirements

Sox:

> sudo aptitude install sox

Phonemizer:

> git clone --depth=1 https://github.com/bootphon/phonemizer /tmp/phonemizer/

> cd /tmp/phonemizer

> python setup.py build

> sudo python setup.py install

Perl-Modules:
> sudo cpan -i Term::ANSIColor

> sudo cpan -i Memoize

> sudo cpan -i Digest::MD5

# How to run it

Edit the main.pl to change the text that should be said.

> perl main.pl

# Options

> --debug Enables debug mode

> --nopause Disables pauses between words (doesn't do anything yet)

> --language=de Sets the language (doesn't do anything really yet)
