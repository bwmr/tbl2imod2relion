%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Takes a .star file describing aligned particles from Relion and assigns a
% random Rotation angle (around the Z axis in the aligned model). Creates a reconstruction as a
% template as well as a .star file to be used for Refinement.
%
% This version is specifically adapted for subtomograms reconstructed using
% Warp.
%
% Based on a script by Rebecca de Leeuw.
% (c) Benedikt Wimmer, Medalia Lab, UZH, July 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

%% Input
% Which Project are you working on? Which Refine3D job should be used as an
% input?
relionDir = '/home/Medalia/BWimmer/Benedikt/04_SFB/03_Relion/210615_SFB_SLayer_Warp-Relion-M/relion';
jobID = 'job002';

% Info on the .star file. In editor, check the delimiter type (tab or
% space) and how long the header is (total number of lines before the
% entries start, incl. _loop and blank lines). Indicate, which columns you
% would like to keep. 
% Required: Micrograph Name, Coordinate XYZ, PriorRot, PriorTilt, PriorPsi,
% ImageName, CTF Volume, AngleRot, AngleTilt, AnglePsi, OriginXYZ

delimType = 'space';
headerLength = 26;
columnID = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16];

%% Processing
% If Refinement was interrupted and continued, add a _ctXX_ in the input
% filename

inputStar = readtable([relionDir '/Refine3D/' jobID '/run_ct22_data.star'],'FileType','text','Delimiter', delimType, 'MultipleDelimsAsOne', true, 'ReadVariablenames', false,'HeaderLines', headerLength);

% Make clean table with only required columnss

i = 1;

for k = columnID
    cleanStar(:,i) = inputStar(:,k);
    i = i + 1;
end

clear inputStar i delimType headerLength k columnID;

%% .star file for template
% Make clean table with random rotation angles and minimal other entries for template reconstruction.
% Assumes that the rotation angle is in column #11 of the input / column
% #10 of the cleanup file.

% Coordinate XYZ #1 - #3
templateStar(:,1:3) = cleanStar(:,1:3);

% Random rotation angle #7.

for k = 1:size(templateStar,1)
    randomRot{k} = num2str(round((rand(1)-0.5).*360));
end

templateStar(:,4) = randomRot';

% Tilt #5, Psi #6, MicrographName #7, Magnification #8, DetectorPixelSize
% #9, CtfMaxResolution #10, ImageName #11, CtfImage #12, Optics Grop #13, OriginXYZ #14 - 16
templateStar(:,5:16) = cleanStar(:,5:16);

clear randomRot cleanStar;

%% Output
% Write star file for template reconstruction with all angles as
% non-priors.

cd(relionDir);

fileID = fopen([jobID '_randomRot_template.star'],'w');
fprintf(fileID,'%s\n','data_','','loop_','_rlnCoordinateX #1','_rlnCoordinateY #2','_rlnCoordinateZ #3','_rlnAngleRot #4','_rlnAngleTilt #5','_rlnAnglePsi #6','_rlnMicrographName #7','_rlnMagnification #8','_rlnDetectorPixelSize #9','_rlnCtfMaxResolution #10','_rlnImageName #11','_rlnCtfImage #12','_rlnGroupNumber #13','_rlnOriginX #14','_rlnOriginY #15','_rlnOriginZ #16');
fclose(fileID);

writetable(templateStar,'star_export.star','FileType','text','Delimiter','tab','WriteVariableNames',false);
unix(['cat star_export.star >> ' jobID '_randomRot_template.star']);

delete star_export.star;

% Write star file for Refine3D job w/ rotation as no-prior and tilt/psi as
% prior

fileID = fopen([jobID '_randomRot_refine.star'],'w');
fprintf(fileID,'%s\n','data_','','loop_','_rlnCoordinateX #1','_rlnCoordinateY #2','_rlnCoordinateZ #3','_rlnAngleRot #4','_rlnAngleTiltPrior #5','_rlnAnglePsiPrior #6','_rlnMicrographName #7','_rlnMagnification #8','_rlnDetectorPixelSize #9','_rlnCtfMaxResolution #10','_rlnImageName #11','_rlnCtfImage #12','_rlnGroupNumber #13','_rlnOriginX #14','_rlnOriginY #15','_rlnOriginZ #16');
fclose(fileID);

writetable(templateStar,'star_export.star','FileType','text','Delimiter','tab','WriteVariableNames',false);
unix(['cat star_export.star >> ' jobID '_randomRot_refine.star']);

delete star_export.star;

%% Reconstruct template - needs sbgrid
% if pre-CTF corrected, add --ctf_multiplied true or --ctf_phase_flipped true 

unix(['relion_reconstruct --i ' jobID '_randomRot_template.star --o ' jobID '_randomRot_template.mrc --maxres 30 --ctf true --3d_rot true'])
   
