%%%%%%%%
% Input unmasked half-maps from Relion Refine3D job type. Calculate and
% plot FSCs.
% Based on a script by Matthias Wojtynek.
% (c) Benedikt Wimmer, UZH, 04/2021
%%%%%%%%

clc;
clearvars;


%% Input
% General Parameters
boxSize = 240;
pixelSize = 1.755;
plotNumber = 3;

odd = cell(1,plotNumber);
even = cell(1,plotNumber);
name = cell(1,plotNumber);

% Dataset 1:
name{1} = 'smallset';

oddTemp = tom_mrcread('Refine3D/job002/run_half1_class001_unfil.mrc');
odd{1} = oddTemp.Value;

evenTemp = tom_mrcread('Refine3D/job002/run_half2_class001_unfil.mrc');
even{1} = evenTemp.Value;

% Dataset 2:
name{2} = '';

oddTemp = tom_mrcread('');
odd{2} = oddTemp.Value;

evenTemp = tom_mrcread('');
even{2} = evenTemp.Value;

% Dataset 3:    
name{3} = '';

oddTemp = tom_mrcread('');
odd{3} = oddTemp.Value;

evenTemp = tom_mrcread('');
even{3} = evenTemp.Value;

% Dataset 4:   
name{4} = '';

oddTemp = tom_mrcread('');
odd{4} = oddTemp.Value;

evenTemp = tom_mrcread('');
even{4} = evenTemp.Value;

clear oddTemp evenTemp;

%% Calculate FSCs

fsc = cell(1,plotNumber);

for k = 1:plotNumber
    fsc{k} = tom_compare(odd{k},even{k},boxSize/2);
end

%% Plot

figure(1); hold on

% Axis limits
axis([0 50 -0.05 1.01]);

% 0.5 FSC, 0.143 FSC
y1 = yline(0.5,'--','DisplayName','FSC = 0.5');
y2 = yline(0.143,'--','DisplayName','FSC = 0.143');
y3 = yline(0,'DisplayName','');

% Axis labels
ylabel('Correlation coefficient','FontSize',12,'FontWeight','bold');
xlabel('Spatial frequency [1/A]','FontSize',12,'FontWeight','bold');

% Convert frequencies in 1/px to 1/A / Calculate resolution (0.143
% criterion)
f = (1:(boxSize/2))./(2*pixelSize.*boxSize/2);
x = round((1./f).*10)./10;

resolution = cell(1,plotNumber);

for k = 1:plotNumber
    fscTemp = fsc{k};
    intersect = interp1(fscTemp(2:boxSize/2,9),fscTemp(2:boxSize/2,1),0.143,'makima'); 
    resolution{k} = interp1(1:boxSize/2,x,intersect);
    disp(['The estimated resolution for ' name{k} ' is ' num2str(resolution{k}) ' A'])
end

xticks([10 20 30 40 50]);
xticklabels({ x(10) x(20) x(30) x(40) x(50)});

clear fscTemp f x intersect;

% Plot all FSCs
colors = ['m' 'c' 'g' 'k'];

for k = 1:plotNumber
    plotTemp = fsc{k};
    k = plot(plotTemp(:,1),plotTemp(:,9),colors(k),'LineWidth',3,'DisplayName',name{k});
end

legend;

clear plotTemp;

