function [ spotMed ] = MaskMeasure( image, mask, gridx, gridy)
%MaskMeasure measures the median intensity of regions of image defined by
%mask.  
%   If there is no mask element near gridx or gridy, NaN is returned.

%measure data from spots
stats = regionprops(mask,image, 'PixelValues', 'Centroid');

%extract centroid and pixelvalue data
for i = 1:length(stats)
centroid(i,:) = stats(i).Centroid;
medPixVal(i,:) = median(stats(i).PixelValues);
end



%% Sort spot values into its original array based on the xy position of the centroid
spotData = [centroid medPixVal];

tol = 40;

for i = 1 : size(gridx,1)
    for j = 1:size(gridx,2)
      idxx = find(spotData(:,1)<(gridx(i,j)+tol) & spotData(:,1)>(gridx(i,j)-tol)) ;
      idxy = find(spotData(:,2)<(gridy(i,j)+tol) & spotData(:,2)>(gridy(i,j)-tol)) ;
      match = intersect(idxx, idxy);
      
      if isempty(match)
          spotMed(i,j) = NaN;
      else
      spotMed(i,j) = spotData(match, 3);
      end
     
      
end
    


end

