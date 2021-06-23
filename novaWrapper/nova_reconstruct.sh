#! /bin/bash
# Script to reconstruct a 3D-ctfcorrected volume using novaCTF. (c) Benedikt Wimmer 04/2021

shopt -s nullglob

# Run from experiment folder. Enter TS ID as Argument $1 (eg. TS_01).

# Script prompts for Thickness as $thick (in px), Pixel Size (in nm) as $angpix and Z step as $stepsize (in nm). N is the degree of parallelization. 

echo "Enter thickness in pixel"
read thick

echo "Enter Z step in nm"
read stepsize

echo "Enter pixel size in nm"
read angpix

cd $1/novaCTF

# Flip stacks

for FILE in corrected_stack.mrc_*; do
	ID=$(echo "$FILE" | cut -d '_' -f 3)	
	clip flipyz $FILE "flipped_stack.ali_$ID"
	echo "Flipped stack $ID"
done

# Filter stacks

for FILE in flipped_stack.ali_*; do
	
	ID=$(echo "$FILE" | cut -d '_' -f 3)
	
	rm "setup_filter.com_$ID"	
	touch "setup_filter.com_$ID"	
	
	echo "Algorithm filterProjections" >> "setup_filter.com_$ID"
	echo "InputProjections $FILE" >> "setup_filter.com_$ID"	
	echo "OutputFile filtered_stack.ali_$ID" >> "setup_filter.com_$ID"
	echo "TILTFILE $1-ali.tlt" >> "setup_filter.com_$ID"
	echo "StackOrientation xz" >> "setup_filter.com_$ID"
	echo "RADIAL 0.35 0.05" >> "setup_filter.com_$ID"

done

N=3

for FILE in setup_filter.com_*; do
	((i=i%N)); ((i++==0)) && wait	
	novaCTF -param $FILE &
done

wait

# Setup and run reconstruction

rm "setup_reconstruction.com"
touch "setup_reconstruction.com"

echo "Algorithm 3dctf" >> "setup_reconstruction.com"
echo "InputProjections filtered_stack.ali" >> "setup_reconstruction.com"
echo "OutputFile $1_3drec_HQ.mrc" >> "setup_reconstruction.com"
echo "TILTFILE $1-ali.tlt"  >> "setup_reconstruction.com"
echo "THICKNESS $thick" >> "setup_reconstruction.com"
echo "FULLIMAGE 3838 3708" >> "setup_reconstruction.com"
echo "SHIFT 0.0 0.0" >> "setup_reconstruction.com"
echo "PixelSize $angpix" >> "setup_reconstruction.com"
echo "DefocusStep $stepsize" >> "setup_reconstruction.com" 

novaCTF -param setup_reconstruction.com

# Cleanup temporary files

rm *.txt_*

rm setup_ctfcorr.com_*
rm corrected_stack.mrc_*
rm flipped_stack.ali*
rm setup_filter.com_*
rm filtered_stack.ali_*
