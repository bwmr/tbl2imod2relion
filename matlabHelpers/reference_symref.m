%%%%%%%%
% Takes unsymmetric input reference, List of desired axial symmetries. Outputs
% references with desired symmetries for Relion
%%%%%%%%

clc;
clearvars;

%% Define desired Symmetries

sym_list = [5];
input_mrc = tom_mrcread('template_centered_nosym.mrc');

%% Run 
for k=sym_list
    temp_name = ['reference_sym_' num2str(k)];
    temp_vol = tom_symref(input_mrc.Value, k);
    tom_mrcwrite(temp_vol,'name',[temp_name '.mrc']);
    clear temp_name temp_vol;
end
