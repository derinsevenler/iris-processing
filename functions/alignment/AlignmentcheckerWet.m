%%%%This function aligns the images and provides a quality of alignment
%%%%feedback.  The user can approve the automatic alignment or manually
%%%%align the images.



function [Ial] = AlignmentcheckerWet(im1, im)


z = 0;
Ial = im;

yZeroCoordinates = find(not(mean(im)));
xZeroCoordinates = find(not(im(:,1)));
if isempty(yZeroCoordinates) == 0 
    if yZeroCoordinates(1) <= 100
        ycoord = yZeroCoordinates(end);
        xy = 0;
    elseif yZeroCoordinates(1) >= 100
        ycoord = yZeroCoordinates(1);
        xy = 1;
    end
else
    ycoord = size(im,2);
    xy = 1;
end

if xy == 0
    error = (double(Ial(:,ycoord:end)-double(im1(:, ycoord:end)))).^2;
elseif xy == 1
    error = (double(Ial(:,1:ycoord)-double(im1(:, 1:ycoord)))).^2;
end

errorpPixel = sum(error(:))/numel(im1);

if errorpPixel >= 0.001
     h = warndlg('Alignment of images is poor. This image will be skipped');
    waitfor(h)
    Ial = NaN(size(Ial));

end
