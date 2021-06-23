#! /bin/bash
# Script to set up 3D-ctfcorrection using novaCTF. (c) Benedikt Wimmer 04/2021

shopt -s nullglob

# Run from experiment folder. Enter TS ID as Argument $1 (eg. TS_01), 
# Script prompts for Thickness as $thick (in px), Pixel Size (in nm) as $angpix and Z step as $stepsize (in nm).

echo "Enter thickness in pixel"
read thick

echo "Enter Z step in nm"
read stepsize

echo "Enter pixel size in nm"
read angpix

cd $1/novaCTF

# Setup and run defocus array

rm setup_defocus.com
touch setup_defocus.com

echo "Algorithm defocus" >> setup_defocus.com
echo "InputProjections $1-ali_ali.mrc" >> setup_defocus.com
echo "FULLIMAGE 3708 3838" >> setup_defocus.com
echo "THICKNESS $thick" >> setup_defocus.com
echo "TILTFILE $1-ali.tlt" >> setup_defocus.com
echo "SHIFT 0.0 0.0 0.0" >> setup_defocus.com
echo "CorrectionType multiplication" >> setup_defocus.com
echo "DefocusFileFormat ctffind4" >> setup_defocus.com
echo "DefocusFile diagnostic_output.txt" >> setup_defocus.com
echo "PixelSize $angpix" >> setup_defocus.com
echo "DefocusStep $stepsize" >> setup_defocus.com
echo "CorrectAstigmatism 1" >> setup_defocus.com

novaCTF -param setup_defocus.com

