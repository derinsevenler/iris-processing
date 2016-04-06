function [ centroid, cornerMed ] = CornerMaskMeasure( image, mask, gridx, gridy )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%   label the black and white masks
labeledMask = bwlabel(mask);

%measure data from spots
    stats = regionprops(labeledMask,image, 'PixelValues', 'Centroid');
    
    %extract centroid and pixelvalue data
    for i = 1:length(stats)
        centroid(i,:) = stats(i).Centroid;
        medPixVal(i,:) = median(stats(i).PixelValues);
    end
    





%% Sort spot values into its original array based on the xy position of the centroid

    
    for i = 1 : size(gridx,1)
        for j = 1:size(gridx,2)
            x=gridx(i,j);
            y=gridy(i,j);
            if ~isnan(x)||isnan(y);
                tempSpots = [x,y;centroid];
                D = pdist(tempSpots);
                D = D(1:size(centroid,1));
                [sortedCorners, sortedIndex] = sort(D);
                cornersIndex = sortedIndex(1:4);
                cornerMed(i,j) = median(medPixVal(cornersIndex));
                
                %Just as a check-up
                %figure;imshow(image,median(double(image(:)))*[0.8 1.2]);
                %h = viscircles(centroid(cornersIndex,:),10*ones(4,1));
            elseif isnan(x) || isnan(y)
                cornerMed(i,j) = NaN;
            end
            
        end
    end
    

end

