%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Takes a list of extracted particles from Dynamo. Outputs list for
% subtomogram reconstruction in imod. This creates symlinks to work with the new file endings adapted for imod > 4.10.51,
% but will work for others. 
% Box size must be even!
% Based on a script by Matthias Wojtynek.
% (c) Benedikt Wimmer, Medalia Lab, UZH, April 2021
%
% Version 2 Features:
% - no symlinks are created anymore for legacy imod file endings (imod >
% 4.11.2)
% - center coordinates of particles are more faithfully calculated
% according to https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Volume_center#While_particle_cropping
% - allows entering a scaling factor to transfer (binned) Dynamo
% coordinates to unbinned data.
% - use processchunks for parallel processing
% - use 3D CTF correction. Provide aligned, filtered stack, ctf correction
% .com file, defocus .com file must be in imod folder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

%% Input Here
inputModel = '';
experimentPath ='';

boxSizeXYZ = '';
scalingFactor = ;
CTFstepnm = ''; 

parallelProcesses = '16';

%% Load & Clean Data
cropList = strcat(inputModel, '/crop.tbl');
fileList = strcat(inputModel, '/indices_column20.doc');

origT = readtable(cropList,'FileType','text','Delimiter','space');
origF = readtable(fileList,'FileType','text','Delimiter','space','MultipleDelimsAsOne',true);

origF.Var2 = char(origF.Var2);

cleanT(:,1) = table2array(origT(:,20));

% Calculate true center and scale by scaling Factor

cleanT(:,2) = table2array(origT(:,24)) -0.5;
cleanT(:,3) = table2array(origT(:,25)) -0.5;
cleanT(:,4) = table2array(origT(:,26)) -0.5;

scaledT(:,1) = table2array(origT(:,20));
scaledT(:,2) = scalingFactor * cleanT(:,2);
scaledT(:,3) = scalingFactor * cleanT(:,3);
scaledT(:,4) = scalingFactor * cleanT(:,4);

clear origT;

% Create one subtable with per TS
listTS = unique(cleanT(:,1));

for k = listTS'
    splitID = cleanT(:,1)==k;
    splitT{k} = cleanT(splitID,2:4);
    coordsT{k} = scaledT(splitID,2:4);
    clear splitID;
    splitID = origF.Var1==k;
    splitF{k} = origF(splitID,2);
end

clear k splitID cleanT scaledT origF;

%% Run subtomosetup

% Define particle path
inputSplit = strsplit(inputModel,'/');
inputName = inputSplit{8};
clear inputSplit;
particlePath = strcat(experimentPath,'/particles_',inputName);
mkdir(particlePath);

% Set dirlist memory
dirlist = dir(particlePath);
dirlist(1:2) = [];
dirlist_memory = size(dirlist,1);

% Create IMOD reconstruction commands
for k=listTS'
    
    % Initialize basepath
    path = strsplit(splitF{k}.Var2,'/');
    basePath = strcat(experimentPath,'/',path{9});
    
    % Perform reconstruction
    disp(['Starting reconstruction ' path{9}]);
        
    % Change to IMOD directory
    cd([basePath '/imod']);
    
    % Export model file (with coordinates on Dynamo input = unscaled)
    imodName = strcat(path{9},'_',inputName);
    fileID = fopen(imodName,'w');
    fprintf(fileID,'%.2f %.2f %.2f\n', splitT{k}');
    fclose(fileID);

     % Export .coords file (with coordinates on unbinned reconstruction = upscaled)
    rlnName = strcat(path{9},'.coords');
    fileID = fopen(rlnName,'w');
    fprintf(fileID,'%.2f %.2f %.2f\n', coordsT{k}');
    fclose(fileID);    
    
    % Create subtomogram reconstruction commands. In newer versions,
    % symlinks are not required anymore (imod > 4.11.2)
    unix(['subtomosetup -root ' path{9} '-ali' ' -volume ' splitF{k}.Var2 ' -center ' imodName ' -size ' boxSizeXYZ ' -dir ' particlePath ' -extent ' CTFstepnm]);
    disp(['IMOD subtomogram-setup done, starting reconstruction, ' num2str(size(splitT{k},1)) ' particles']);

    % Perform particle reconstruction
    unix(['processchunks ' parallelProcesses ' tilt-sub']);

    % Waiting-loop until current tomogram is done
    continue_flag = 0;
    while continue_flag == 0
        dirlist = dir(particlePath);
        dirlist(1:2) = [];
        % Break loop
        if size(dirlist,1) - dirlist_memory == size(splitT{k},1)
            continue_flag =1;
        end
    end
    pause(10);
    clear tempName
    dirlist_memory = size(dirlist,1);
    disp([path{9} ' done']);

    % Delete subtomogram reconstruction commands
    delete tilt-sub*.com;
end
clear
clc
