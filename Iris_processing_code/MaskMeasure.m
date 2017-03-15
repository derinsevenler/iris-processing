function [  centroid, varargout ] = MaskMeasure( varargin)
%MaskMeasure measures the median intensity of regions of image defined by
%mask.
%   If there is no mask element near gridx or gridy, NaN is returned.
switch nargin
    case 4
        image = varargin{1};
        mask = varargin{2};
        gridx = varargin{3};
        gridy = varargin{4};
    case 1
        mask = varargin{1};
end
%   label the black and white masks
labeledMask = bwlabel(mask);

%measure data from spots
if nargin == 4
    stats = regionprops(labeledMask,image, 'PixelValues', 'Centroid');
    
    %Preallocate for speed
    centroid = zeros(length(stats),2);
    medPixVal = zeros(length(stats),1);
    meanPixVal = zeros(length(stats),1);
    
    %extract centroid and pixelvalue data
    for i = 1:length(stats)
        centroid(i,:) = stats(i).Centroid;
        PixVal = stats(i).PixelValues;
        
        medPixVal(i,:) = median(PixVal);
        modePixVal = mode(PixVal);
        stdPixVal = std(PixVal);
        meanPixVal(i,:) = mean(PixVal(PixVal >= modePixVal - stdPixVal & PixVal <= modePixVal + stdPixVal));
    end
    
elseif nargin == 1
    stats = regionprops(labeledMask, 'Centroid');
    %extract centroid 
    for i = 1:length(stats)
        centroid(i,:) = stats(i).Centroid;
    end
end





%% Sort spot values into its original array based on the xy position of the centroid
if nargin == 4
    spotData = [centroid medPixVal meanPixVal];
    
    tol = 20;
    
    %Preallocate for speed
    spotMed = zeros(size(gridx,1), size(gridx,2));
    spotMean = zeros(size(gridx,1), size(gridx,2));
    
    for i = 1 : size(gridx,1)
        for j = 1:size(gridx,2)
            idxx = find(spotData(:,1)<(gridx(i,j)+tol) & spotData(:,1)>(gridx(i,j)-tol)) ;
            idxy = find(spotData(:,2)<(gridy(i,j)+tol) & spotData(:,2)>(gridy(i,j)-tol)) ;
            match = intersect(idxx, idxy);
            
            if isempty(match)
                spotMed(i,j) = NaN;
                spotMean(i,j) = NaN;
            else
                spotMed(i,j) = spotData(match, 3);
                spotMean(i,j) =spotData(match,4);
            end
            
            
        end
    end
    
    varargout{1} = spotMed;
    varargout{2} = spotMean;
    
end

