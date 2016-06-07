function kernel2D = generateLowPassFilter(stride, filterWidth)
 
    if (stride == 1)
        kernel2D = ones(1,1);
        return;
    end
    sigma = sqrt((filterWidth^2-1)/12);
    spaceAxis   = -round(4*sigma):1:round(4*sigma);
    kernel      = exp(-0.5*(spaceAxis/sigma).^2);
    kernel2D    = kernel' * kernel;
    kernel2D    = kernel2D / sum(kernel2D(:));
end