#!/bin/bash

for file in `ls Sounds-Master/*.aiff`; do
	filename=`basename $file`
	name="${filename%.*}"
	ffmpeg -y -i $file -c:a libmp3lame -abr 1 -ab 90k Sounds/$name.mp3
done
