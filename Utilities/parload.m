function multispectralImage = parload(fname)
% loads the data in the .mat file fname
radiance = load(fname);
multispectralImage = radiance.multispectralImage;
end
