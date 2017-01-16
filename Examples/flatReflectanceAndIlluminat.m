folderToStore = pwd;

S = [400 5 61];
theWavelengths = SToWls(S);

theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931(2,:),theWavelengths);

flatIlluminant = ones(61,1);

fid = fopen(fullfile(folderToStore,'illuminance_10000.spd'),'w');
fprintf(fid,'%3d %3.6f\n',[theWavelengths,flatIlluminant]');
fclose(fid);

theLuminanceTarget=reshape(repmat([0.2:0.4/9:0.6],10,1),100,1)';

flatScaledReflectances = ones(61,1)*theLuminanceTarget/sum(theLuminanceSensitivity);


for i=1:10
    for j = 1:10
        reflectanceName = sprintf('luminance-%.4f-reflectance-%03d.spd', theLuminanceTarget(1,i*10), 600+j);
        fid = fopen(fullfile(folderToStore,reflectanceName),'w');
        fprintf(fid,'%3d %3.6f\n',[theWavelengths,flatScaledReflectances(:,(i-1)*10+j)]');
        fclose(fid);
    end
end    