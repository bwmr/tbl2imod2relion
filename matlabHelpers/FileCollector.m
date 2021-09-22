%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copy all MMMs to the folder of interest
% Create binned version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

%% Input

RootDir = '/mnt/ome/Projects7/Benedikt/01_100_Bacteria/01_Krios-data';
TargetDir = '/mnt/ome/scratchX03/4Nadav';

%% Copy Files to bin0 and rename

% Create target folder

mkdir([TargetDir '/bin0'])

% Grab all MMM files in all subdirectories, remove all stitched / blended /
% whatever

cd(RootDir);

fileList = dir('**/MMM*.mrc');
fileList = fileList(~contains({fileList(:).name},{'sti','blended'}));

% Copy and rename files

for k = 1:size(fileList,1)
    
    % Extract experiment ID from path
    path = strsplit(fileList(k).folder,'/');
    ID = strsplit(path{9},'-');
    experiment = [ID{2} '-' ID{3}];
    
    % Copy file to target folder
    unix(['cp ' fileList(k).folder '/' fileList(k).name ' ' TargetDir '/bin0/' experiment '-' fileList(k).name]);
    
end


%% Create Binned versions (in imod convention)

cd(TargetDir);

mkdir('bin4');

cd bin0;

unix('for FILE in *.mrc; do newstack -in $FILE -bin 4 -out ../bin4/$FILE; done');

%% Compress folder containing binned files

