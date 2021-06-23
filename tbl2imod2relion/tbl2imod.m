%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Takes a list of extracted particles from Dynamo. Outputs list for
% subtomogram reconstruction in imod. This creates symlinks to work with the new file endings adapted for imod > 4.10.51,
% but will work for others. 
% Box size must be even!
% (c) Benedikt Wimmer, Medalia Lab, UZH, February 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

%% Input Here
inputModel = '';
experimentPath ='';
boxSizeXYZ = '';

%% Load & Clean Data
cropList = strcat(inputModel, '/crop.tbl');
fileList = strcat(inputModel, '/indices_column20.doc');

origT = readtable(cropList,'FileType','text','Delimiter','space');
origF = readtable(fileList,'FileType','text','Delimiter','space','MultipleDelimsAsOne',true);

origF.Var2 = char(origF.Var2);

cleanT(:,1) = table2array(origT(:,20));
cleanT(:,2:4) = table2array(origT(:,24:26));

clear origT;

% Create one subtable with per TS
listTS = unique(cleanT(:,1));

for k = listTS'
    splitID = cleanT(:,1)==k;
    splitT{k} = cleanT(splitID,2:4);
    clear splitID;
    splitID = origF.Var1==k;
    splitF{k} = origF(splitID,2);
end

clear k splitID cleanT origF;

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
    
    % Export model file
    tempName = strcat(path{9},'_',inputName);
    fileID = fopen(tempName,'w');
    fprintf(fileID,'%.2f %.2f %.2f\n', splitT{k}');
    fclose(fileID);

    % Create subtomogram reconstruction commands.
    unix(['ln -s ' path{9} '-ali.mrc' ' ' path{9} '-ali.st']);
    unix(['ln -s ' path{9} '-ali_ali.mrc' ' ' path{9} '-ali.ali']);
    unix(['subtomosetup -root ' path{9} '-ali' ' -volume ' splitF{k}.Var2 ' -center ' tempName ' -size ' boxSizeXYZ ' -dir ' particlePath]);
    disp(['IMOD subtomogram-setup done, starting reconstruction, ' num2str(size(splitT{k},1)) ' particles']);

    % Perform particle reconstruction
    unix('subm tilt-sub*.com');
    disp('reconstructing ...');        

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
