% Cylindermask

clc;
clearvars;

vol_1 = tom_mrcread('job002_pore_centered_ref.mrc');
cyl = tom_cylindermask(ones(84,84,84),28);
tom_volxyz(vol_1.Value);
cyl(:,:,1:15) = 0;
cyl(:,:,57:84) = 0;
tom_volxyz(cyl);

mask = tom_norm(tom_filter(cyl,8),1);
tom_mrcwrite(mask,'name','mask_r15_stem.mrc');

stem_masked = mask.*vol_1.Value;
tom_mrcwrite(stem_masked,'name','_masked.mrc');

tom_volxyz(mask.*vol_1);
