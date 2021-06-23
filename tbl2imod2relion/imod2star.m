%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Takes a list of extracted particles from Dynamo and folder with
% reconstructed subtomograms from imod. Outputs wedge volume for masking and .star file for Relion.
%
% Requires:
% - dynamo2warp
% - Relion 1.4 (set in .sbgrid.conf).
% - Python 3 (set in .sbgrid.conf).
% - Python 2 (accessed as python2).
% - adapted version of relion_prepare_subtomograms.py file (hardcode magnification, defocus, tomogram size, box size) placed in the
% Relion project folder
%
% (c) Benedikt Wimmer, Medalia Lab, UZH, April 2021
%
% Version 2 Features:
% - allow creation of a real dose file for the 3D CTF model (based on
% Matthias Wojtynek's dose filtration script)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

%% Input Here

inputModel = '';
dataPath ='';
outputProject = '';
scriptName = '';

boxSize = '';
trueDose = 0;

%% Import TS list

fileList = strcat(inputModel, '/indices_column20.doc');
origF = readtable(fileList,'FileType','text','Delimiter','space');

cleanF(:,1) = table2array(origF(:,4));
clear origF;

inputSplit = strsplit(inputModel,'/');
inputName = inputSplit{8};
clear inputSplit;

%% Organize Relion folders, generate all_micrographs.star

for k=1:size(cleanF,1)
    
    % Get info on imod directory
    path = strsplit(cleanF{k},'/');
    tsID = strcat(path{9});
    imodDir = fileparts(cleanF{k});
    
    disp(['Creating Relion input folder for ' tsID]);
    
    % Make corresponding output directory for Relion
    outDir = strcat(outputProject, '/Tomograms/', tsID);
    mkdir(outDir);
    
    % Make symlinks for tomogram, aligned stack, coordinates, tomo.tlt
    unix(['ln -s ' cleanF{k} ' ' outDir '/' tsID '.mrc']);
    unix(['ln -s ' imodDir '/' tsID '-ali_ali.mrc ' outDir '/' tsID '.mrcs']);
    unix(['ln -s ' imodDir '/' tsID '-ali.tlt ' outDir '/' tsID '.tlt']);
    unix(['cp ' imodDir '/' tsID '.coords ' outDir '/' tsID '.coords']);
    
    % To create .order file, first read tilt angles.
    
    tltfile = fopen([imodDir '/' tsID '-ali.tlt']);
    tlt = textscan(tltfile,'%s');
    orderFile = str2double(tlt{1});
    fclose(tltfile);
    clear fileID;
    
    if trueDose == 1
        % Read .mdoc file, write out true prior Dose.delete star_export.star;

        mdoc_dir = dir('*.mdoc');
        fileID = fopen(mdoc_dir.name,'r');
        j = 1;
        tline = fgetl(fileID);
        i = 1;

        while ischar(tline)
            tline = fgetl(fileID);
            
            if tline == -1
                break
            end

            if contains(tline,'[ZValue')
                i = i+1;
                j=1;
            end
            
            mdocFile{j,i} = tline;
            j = j+1;
        end
        
        fclose(fileID);
        clear i j tline;
    
        % Sort frames based on date, so it is known which frames where acquired
        % first&last. Check which field contains DateTime, PriorRecordDose.
        DT = 28;
        PD = 24;

        for i=2:size(mdocFile,2)
            time(i-1,1) = datetime(mdocFile{DT,i}(12:end),'InputFormat','dd-MM-yy HH:mm:ss');
        end

        [~,sidx] = sort(time);
        mdocSorted = mdocFile(:,1);
        mdocSorted = [mdocSorted mdocFile(:,sidx+1)];

        for i=2:(size(mdocSorted,2))
            orderFile(sidx(i-1),2) = str2double(regexp(string(mdocSorted{PD,i}),'(\d+,)*\d+(\.\d*)?', 'match'));
        end
        
    else
        % Write all zero prior Dose in .order file.
        orderFile(:,2) = zeros([size(orderFile,1),1]);
    end
    
    % Write out .order file
    fileID = fopen([outDir '/' tsID '.order'],'w');
    fprintf(fileID,'%.2f %.2f\n', orderFile');
    fclose(fileID);
    
end

clear k fileID rawtlt tlt mdoc_dir orderFile outDir path tsID cleanF DT PD mdocFile mdocSorted i j tltfile time sidx;

cd(outputProject);
unix('relion_star_loopheader rlnMicrographName > all_tomograms.star');
unix('ls Tomograms/TS_??/*.mrc >>  all_tomograms.star');

%% Extract prior angles from Dynamo, write to .star file

unix(['dynamo2warp -i ' inputModel '/crop.tbl' ' -tm ' fileList ' -o ' outputProject '/prior_angles.star']);
clear fileList;

%% Run relion_prepare_subtomograms.py & fake CTF correction to generate Wedge Volume

unix(['python2 ' scriptName '.py']);
unix(['sh ./do_all_reconstruct_ctfs.sh ' boxSize]);

%% Read prior angles and Wedge Volume and write out a .star file with Particle Paths and all info.

% Read particles_subtomo.star and prior_angles.star
particlesSubtomo = readtable([outputProject '/particles_subtomo.star'], 'FileType','text','Delimiter', 'tab');
priorAngles = readtable([outputProject '/prior_angles.star'], 'FileType','text','Delimiter', 'tab');

% Read in files dirlist memory and add to star file
dirlist = dir([dataPath '/particles_' inputName]);
dirlist(1:2) = [];

for k = 1:size(dirlist,1)
    cleanDir{k} = strcat(dirlist(k).folder, '/', dirlist(k).name);
end

clear dirlist k;

% Create combined star. Columns: 1 filename, 2 - 4 XYZ, 5 -7 Euler angles as Prior information,
% 8 particle path, 9 CTF volume

starExport(:,1:4) = particlesSubtomo(:,1:4);
starExport(:,5:7) = priorAngles(:,4:6);
starExport(:,8) = cleanDir';
starExport(:,9) = particlesSubtomo(:,6);

clear cleanDir particlesSubtomo priorAngles;
delete prior_angles.star particles_subtomo.star;

% Export .star file with particles paths, correct header.

fileID = fopen('imod2star.star','w');
fprintf(fileID,'%s\n','data_','','loop_','_rlnMicrographName #1','_rlnCoordinateX #2','_rlnCoordinateY #3','_rlnCoordinateZ #4','_rlnAngleRotPrior #5','_rlnAngleTiltPrior #6','_rlnAnglePsiPrior #7','_rlnImageName #8','_rlnCtfImage #9');
fclose(fileID);

writetable(starExport,'star_export.star','FileType','text','Delimiter','tab','WriteVariableNames',false);
unix('cat star_export.star >> imod2star.star');

delete star_export.star;

clearvars;
clc;
