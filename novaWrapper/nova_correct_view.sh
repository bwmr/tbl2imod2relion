#! /bin/bash
# Script to perform 3D-ctfcorrection using novaCTF. (c) Benedikt Wimmer 04/2021

shopt -s nullglob

# Run from experiment folder. Enter TS ID as Argument $1 (eg. TS_01).

# Script prompts for Thickness as $thick (in px), Pixel Size (in nm) as $angpix and Z step as $stepsize (in nm).

echo "Enter thickness in pixel"
read thick

echo "Enter Z step in nm"
read stepsize

echo "Enter pixel size in nm"
read angpix

cd $1/novaCTF

# Setup CTF correction files and run in parallel (N at a time)

for FILE in *.txt_*; do
	
	ID=$(echo "$FILE" | cut -d '_' -f 3)
	
	rm "setup_ctfcorr.com_$ID"	
	touch "setup_ctfcorr.com_$ID"	
	
	echo "Algorithm ctfCorrection" >> "setup_ctfcorr.com_$ID"
	echo "InputProjections $1-ali_ali.mrc" >> "setup_ctfcorr.com_$ID"	
	echo "DefocusFile $FILE" >> "setup_ctfcorr.com_$ID"
	echo "OutputFile corrected_stack.mrc_$ID" >> "setup_ctfcorr.com_$ID"
	echo "TILTFILE $1-ali.tlt" >> "setup_ctfcorr.com_$ID"
	echo "CorrectionType phaseflip" >> "setup_ctfcorr.com_$ID"
	echo "DefocusFileFormat ctffind4" >> "setup_ctfcorr.com_$ID"
	echo "PixelSize $angpix" >> "setup_ctfcorr.com_$ID"
	echo "DefocusStep $stepsize" >> "setup_ctfcorr.com_$ID"
	echo "AmplitudeContrast 0.07" >> "setup_ctfcorr.com_$ID"
	echo "Cs 2.7" >> "setup_ctfcorr.com_$ID"
	echo "Volt 300" >> "setup_ctfcorr.com_$ID"
	echo "CorrectAstigmatism 1" >> "setup_ctfcorr.com_$ID"
	
done

N=8

for FILE in *ctfcorr.com_*; do
	((i=i%N)); ((i++==0)) && wait	
	novaCTF -param $FILE &
done

wait
