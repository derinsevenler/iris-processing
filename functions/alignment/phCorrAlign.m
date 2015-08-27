function [delta,q] = phCorrAlign(I1, I2)
	% Simple image alignment using phase correlation
% Translation only, does not account for rotation.
% Source: http://www.mathworks.com/matlabcentral/newsreader/view_thread/22794
% delta is the [row, column] displacement of I2 relative to I1.

% block_outer = 150;

% Take FFT of each image
F1 = fft2(I1);
F2 = fft2(I2);

% Create phase difference matrix
pdm = exp(1i*(angle(F1)-angle(F2)));
% Solve for phase correlation function
pcf = real(ifft2(pdm));
pcf = fftshift(pcf);

% Set the bright center pixel to be the average of its neighbors
center = size(pcf)/2 + 1/2; % Image centroid is here
% cPix = ceil(center); % Center pixel is here
% pcf(cPix(1), cPix(2)) = 0;
% reg = pcf((cPix(1)-1):(cPix(1)+1), (cPix(2)-1):(cPix(2)+1));
% pcf(cPix(1), cPix(2)) = sum(reg(:))./8;

% [r,c] = meshgrid(1:size(pcf,1), 1:size(pcf,2));
% mask = sqrt((r-size(pcf,1)/2).^2 + (c-size(pcf,2)/2).^2) > block_outer;
% pcf(mask) = 0;

% figure; imagesc(pcf); colorbar;

[q, idx] = max(pcf(:));
[r, c] = ind2sub(size(pcf),idx);
roi = pcf(r-5:r+5, c-5:c+5);
P = peakfit2d(roi);

v = P - ((size(roi)/2) + 1/2) + [r c];
delta = v - center;