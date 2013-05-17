#!/bin/bash

rm -rf images genimg.log
mkdir images
for i in 0 1 2 3 4 5 6; do
	echo >> genimg.log
	echo Processing mode$i.dat... >> genimg.log
	bzcat ../snapshots/mode${i}.dat.bz2 | lin.x64/rel/mkimg >> genimg.log
	convert f0000.bmp images/mode${i}a.png
	convert f0001.bmp images/mode${i}b.png
done
rm -f *.bmp
