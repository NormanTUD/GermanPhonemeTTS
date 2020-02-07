#!/bin/bash

function cutsilence {
		echo ffmpeg -i $1 -af "silenceremove=start_periods=0:start_duration=0:start_threshold=-60dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=0:start_duration=0:start_threshold=-50dB:detection=peak,aformat=dblp,areverse" "REDONE-$1"
		ffmpeg -i $1 -af "silenceremove=start_periods=0:start_duration=0:start_threshold=-60dB:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=0:start_duration=0:start_threshold=-50dB:detection=peak,aformat=dblp,areverse" "REDONE-$1"
		mv "REDONE-$1" $1

}

if [ $# -eq 0 ]; then
	for i in *.ogg; do
		cutsilence $i
	done
else
	if [ $1 = "git" ]; then
		for i in $(git status . | grep ".ogg" | sed -e 's/^\s*//' | sed -e 's/"?\s*$//' | sed -e 's/^"//' | sed -e 's/"\s*$//'); do
			cutsilence $i
		done
	else
		cutsilence $1
	fi
fi
