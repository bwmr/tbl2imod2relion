%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Takes a .star file describing aligned particles from Relion and assigns a
% random Rotation angle (around the Z axis in the aligned model). Creates a reconstruction as a
% template as well as a .star file to be used for Refinement.
%
% Based on a script by Rebecca de Leeuw.
% (c) Benedikt Wimmer, Medalia Lab, UZH, April 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

%% Input
% Which Project are you working on? Which Refine3D job should be used as an
% input?
relionDir = '';
jobID = 'job001';
angPix = 1.755;

% Info on the .star file. In editor, check the delimiter type (tab or
% space) and how long the header is (total number of lines before the
% entries start, incl. _loop and blank lines). Indicate, which columns you
% would like to keep. 
% Required: Micrograph Name, Coordinate XYZ, PriorRot, PriorTilt, PriorPsi,
% ImageName, CTF Volume, AngleRot, AngleTilt, AnglePsi, OriginXYZ
delimType = 'space';
headerLength = 26;
columnID = [1 2 3 4 5 6 7 8 9 11 12 13 14 15 16];

%% Processing
% If Refinement was interrupted and continued, add a _ctXX_ in the input
% filename

inputStar = readtable([relionDir '/Refine3D/' jobID '/run_data.star'],'FileType','text','Delimiter', delimType, 'MultipleDelimsAsOne', true, 'ReadVariablenames', false,'HeaderLines', headerLength);

% Make clean table with only required columnss

i = 1;

for k = columnID
    cleanStar(:,i) = inputStar(:,k);
    i = i + 1;
end

clear inputStar i delimType headerLength k;

%% .star file for template
% Make clean table with random rotation angles and minimal other entries for template reconstruction.
% Assumes that the rotation angle is in column #11 of the input / column
% #10 of the cleanup file.

% Micrograph Name #1, Coordinate XYZ #2 - #4
templateStar(:,1:4) = cleanStar(:,1:4);

% ImageName #5, CTF Image #6
templateStar(:,5:6) = cleanStar(:,8:9);

% Random rotation angle #7.

for k = 1:size(templateStar,1)
    randomRot{k} = num2str(round((rand(1)-0.5).*360));
end

templateStar(:,7) = randomRot';

% Tilt #8, Psi #9, OriginXYZ #10 - 12
templateStar(:,8:12) = cleanStar(:,11:15);

clear randomRot;

%% .star file for Refine3D
% Make table with all post-refinement Euler angles given as prior
% information.

% Micrograph Name #1, Coordinate XYZ #2 - #4
refineStar(:,1:4) = cleanStar(:,1:4);

% ImageName #5, CTF Image #6
refineStar(:,5:6) = cleanStar(:,8:9);

% Random rotation angle #7 / use same as for template.
refineStar(:,7) = templateStar(:,7);

% Tilt #8, Psi #9, OriginXYZ #10 - 12
refineStar(:,8:12) = cleanStar(:,11:15);

clear cleanStar columnID

%% Output
% Write star file for template reconstruction
cd(relionDir);

fileID = fopen([jobID '_randomRot_template.star'],'w');
fprintf(fileID,'%s\n','data_','','loop_','_rlnMicrographName #1','_rlnCoordinateX #2','_rlnCoordinateY #3','_rlnCoordinateZ #4','_rlnImageName #5','_rlnCtfImage #6','_rlnAngleRot #7','_rlnAngleTilt #8','_rlnAnglePsi #9','_rlnOriginX #10','_rlnOriginY #11','_rlnOriginZ #12');
fclose(fileID);

writetable(templateStar,'star_export.star','FileType','text','Delimiter','tab','WriteVariableNames',false);
unix(['cat star_export.star >> ' jobID '_randomRot_template.star']);

delete star_export.star;

% Write star file for Refine3D job (move Angles to Prior, remove on Rot.
% angle)

fileID = fopen([jobID '_randomRot_refine.star'],'w');
fprintf(fileID,'%s\n','data_','','loop_','_rlnMicrographName #1','_rlnCoordinateX #2','_rlnCoordinateY #3','_rlnCoordinateZ #4','_rlnImageName #5','_rlnCtfImage #6','_rlnAngleRotPrior #7','_rlnAngleTiltPrior #8','_rlnAnglePsiPrior #9','_rlnOriginX #10','_rlnOriginY #11','_rlnOriginZ #12');
fclose(fileID);

writetable(templateStar,'star_export.star','FileType','text','Delimiter','tab','WriteVariableNames',false);
unix(['cat star_export.star >> ' jobID '_randomRot_refine.star']);

delete star_export.star;

%% Reconstruct template - needs sbgrid
% if pre-CTF corrected, add --ctf_multiplied true or --ctf_phase_flipped true 

unix(['relion_reconstruct --i ' jobID '_randomRot_template.star --o ' jobID '_randomRot_template.mrc --angpix ' num2str(angPix) ' --maxres 30 --ctf true --ctf_phase_flipped true --3d_rot true'])
   
