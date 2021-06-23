%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Takes a list of extracted particles from Dynamo and folder with
% reconstructed subtomograms from imod. Outputs wedge volume for masking and .star file for Relion.
% Requires:
% - Relion 3.0.x
% (c) Benedikt Wimmer, Medalia Lab, UZH, February 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

%% Input Here

relionProject = '/mnt/ome/Projects7/Benedikt/05_Relion/210514_SFB_SLayer_highmag_fullset';
boxSize = 240;
angPix = 1.755;

%% Run relion_preprocess to invert and normalize particles move to Particles_final folder. Adapt particle path in .star file.

cd(relionProject);

exportDir = strcat(relionProject,'/Particles_final');
mkdir(exportDir);

unix(['relion_preprocess_mpi --i imod2star.star --part_dir Particles_final/ --set_angpix ' num2str(angPix) ' --norm true --no_ramp true --bg_radius ' num2str(boxSize/2) ' --invert_contrast true --operate_on imod2star.star']);

unix('find -maxdepth 1 -type f -name "preprocessed*.mrc" -exec mv {} ./Particles_final \;');

starFile = readtable([relionProject '/preprocessed.star'], 'FileType','text','Delimiter', 'space', 'MultipleDelimsAsOne', true, 'ReadVariablenames', false,'HeaderLines', 14);
starFile(:,10) = [];

dirlist = dir(exportDir);
dirlist(1:2) = [];

for k = 1:size(dirlist,1)
    cleanDir{k} = strcat('Particles_final/', dirlist(k).name);
end

starFile(:,8) = cleanDir';

clear dirlist cleanDir k;

fileID = fopen('preprocessed_fixed.star','w');
fprintf(fileID,'%s\n','data_','','loop_','_rlnMicrographName #1','_rlnCoordinateX #2','_rlnCoordinateY #3','_rlnCoordinateZ #4','_rlnAngleRotPrior #5','_rlnAngleTiltPrior #6','_rlnAnglePsiPrior #7','_rlnImageName #8','_rlnCtfImage #9');
fclose(fileID);

writetable(starFile,'star_export.star','FileType','text','Delimiter','tab','WriteVariableNames',false);
unix('cat star_export.star >> preprocessed_fixed.star');

delete imod2star.star preprocessed.star star_export.star;



%% Run test

unix(['relion_reconstruct --i preprocessed_fixed.star --angpix ' num2str(angPix) ' --3d_rot true --o average_preprocessed.mrc']); 

clear;
clc;
