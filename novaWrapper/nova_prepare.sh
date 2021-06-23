#! /bin/bash
# Script to prepare for 3D-ctfcorrection using novaCTF. (c) Benedikt Wimmer 04/2021

shopt -s nullglob

# Run from experiment folder. Enter TS ID as Argument $1 (eg. TS_01), 

# Copy required files to separate folder, make unbinned aligned stack

cd $1

mkdir novaCTF

cp "imod/$1-ali.mrc" "novaCTF/$1-ali.mrc"
cp "imod/$1-ali.xf" "novaCTF/$1-ali.xf"
cp "imod/$1-ali.defocus" "novaCTF/$1-ali.defocus"
cp "imod/$1-ali.tlt" "novaCTF/$1-ali.tlt"
cd novaCTF

newstack -InputFile "$1-ali.mrc" -OutputFile "$1-ali_ali.mrc" -TransformFile "$1-ali.xf"

echo "Opening CTFFIND4 to find defocus and astigmatism. Enter input unaligned stack, pixel size and Minimum defocus. Exhaustive search can improve results."

ctffind4

echo "Inspect diagnostic_output.mrc to confirm accurate CTF estimation. Then, continue with script nova_setup.sh"
