% Cylindermask

clc;
clearvars;

vol_1 = tom_mrcread('');
cyl = tom_cylindermask(ones(240,240,240),60);
tom_volxyz(vol_1.Value);
cyl(:,:,1:40) = 0;
cyl(:,:,175:240) = 0;
tom_volxyz(cyl);

mask = tom_norm(tom_filter(cyl,12),1);
tom_mrcwrite(mask,'name','mask_whole.mrc');

stem_masked = mask.*vol_1.Value;
tom_mrcwrite(stem_masked,'name','_masked.mrc');

tom_volxyz(mask.*vol_1.Value);
