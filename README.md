# tbl2imod2relion
Subtomogram Averaging using Dynamo, imod, Relion and MatLab

## imod2warp
Currently under construction. Will allow exporting imod directories with aligned stacks for CTF estimation and subtomogram reconstruction in Warp.

## tbl2imod2relion  
A workflow which takes a model file from Dynamo, reconstructs CTF-corrected subtomograms at these positions using imod and then imports them into Relion.

- **tbl2imod.m**  
Takes the .Data folder of a Dynamo model (obtained through the crop workflow with "Just Report" checked), the base folder for which contains the desirec tilt series and the box size. Reconstructs CTF-corrected subtomograms at the positions provided. 
- **imod2star.m**  
Takes the .Data folder described above, the path containing the tilt series subdirectories and the path of the relion project. Prepares the folder structure for Relion and reconstructs CTF Volumes as described by Bharat & Scheres (2016). Also requires the modified version of the CTF Volume Python script with hard-coded pixel size and tomogram dimensions to be present in the Relion directory.
- **relion_STA_updated.py**  
A modified version of the relion_prepare_subtomograms.py provided in the Relion Wiki. Hard-code Tomogram dimensions, pixel size, etc.
- **star2average.m**  
Works in the Relion project folder. Inverts contrast and normalizes subtomograms. Creates a reconstruction as a template. 
