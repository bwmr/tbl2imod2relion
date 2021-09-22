# tbl2imod2relion
Subtomogram Averaging using Dynamo, imod, Relion and MatLab

## imod2warp
Currently under construction. Will allow exporting imod directories with aligned stacks for CTF estimation and subtomogram reconstruction in Warp.

## matlabHelpers
Matlab scripts helping with small subtomogram averaging tasks. Most use the MPI-BC TOM Toolbox for MatLab.

- **Assign_random_rot.m**  
Takes a .star file and assigns random rotation angles. This can help overcome preferred orientation issues. Reconstructs a template for further Refine3D jobs. 
- **Assign_random_rot_warp.m**  
Same as above but for warp-style .star files. 
- **cylindermask.m**  
Create a cylindrical mask for Refinement in Relion.
- **FileCollector.m**
Collects and moves files according to a pattern. In this case, collects all MMMs and creates a binned version. 
- **FSC_plot.m**  
Takes Relion half-maps as input, calculates FSC curves. Plots multiple FSC curves in the same graph. 
- **reference_symref.m**  
Takes an input model, symmetrizes it as desired. 

## novaWrapper
Wrapper scripts for the novaCTF 3D CTF correction suite. Call from the parent directory of tilt series folders, e.g. Parent/TS_XX/imod. 

- **nova_prepare.sh**  
Creates a fully aligned stack and copies it and the defocus file to a new novaCTF directory. Then, opens CTFFIND4 to estimate defocus for each tilt. 
- **nova_setup.sh**  
Sets up the setup_defocus.com file for an unbinned unshifted tomogram. Prompts thickness, step size and pixel size.
- **nova_correct.sh**  
Takes the defocus com-files and performs CTF correction for shifted slabs. Paralellization is implemented. 
- **nova_reconstruct.sh**  
Takes the CTF-corrected slaps, flips them, filters them and reconstructs a full tomogram.
- **nova_XX_view.sh**  
These are alternative scripts to perform phase-flipping and SIRT-like filtering to better inspect outputs. 

## tbl2imod2relion  
A workflow which takes a model file from Dynamo, reconstructs CTF-corrected subtomograms at these positions using imod and then imports them into Relion.

- **tbl2imod.m**  
Takes the .Data folder of a Dynamo model (obtained through the crop workflow with "Just Report" checked), the base folder for which contains the desired tilt series and the box size. Reconstructs 3D-CTF-corrected subtomograms at the positions provided. 
- **imod2star.m**  
Takes the .Data folder described above, the path containing the tilt series subdirectories and the path of the relion project. Prepares the folder structure for Relion and reconstructs CTF Volumes as described by Bharat & Scheres (2016). Also requires the modified version of the CTF Volume Python script with hard-coded pixel size and tomogram dimensions to be present in the Relion directory.
- **relion_STA_updated.py**  
A modified version of the relion_prepare_subtomograms.py provided in the Relion Wiki. Hard-code Tomogram dimensions, pixel size, etc.
- **star2average.m**  
Works in the Relion project folder. Inverts contrast and normalizes subtomograms. Creates a reconstruction as a template. 
