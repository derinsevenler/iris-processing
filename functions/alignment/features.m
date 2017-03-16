function [Ir,tformTotal]=features(I1,I2)
%%% Find the corners.

%   points1 = detectHarrisFeatures(I1);  %% reference image
%   points2 = detectHarrisFeatures(I2);  %% distorted image 
   
   ptsOriginalBRISK  = detectBRISKFeatures(I1,'MinContrast',0.01);
ptsDistortedBRISK = detectBRISKFeatures(I2,'MinContrast',0.01);

ptsOriginalSURF  = detectSURFFeatures(I1);
ptsDistortedSURF = detectSURFFeatures(I2);

%%%Extract the neighborhood features.

%   [features1, valid_points1] = extractFeatures(I1, points1); 
%   [features2, valid_points2] = extractFeatures(I2, points2);  

   
   [featuresOriginalFREAK,validPtsOriginalBRISK]  = extractFeatures(I1,ptsOriginalBRISK);
[featuresDistortedFREAK,validPtsDistortedBRISK] = extractFeatures(I2,ptsDistortedBRISK);

[featuresOriginalSURF,validPtsOriginalSURF]  = extractFeatures(I1,ptsOriginalSURF);
[featuresDistortedSURF,validPtsDistortedSURF] = extractFeatures(I2,ptsDistortedSURF);
%%%Match the features.

 %  indexPairs = matchFeatures(features1, features2);
   
   
   
   indexPairsBRISK = matchFeatures(featuresOriginalFREAK, featuresDistortedFREAK,'MatchThreshold',40,'MaxRatio',0.8);

   indexPairsSURF = matchFeatures(featuresOriginalSURF,featuresDistortedSURF);

%%%Retrieve the locations of the corresponding points for each image.

%   matchedPoints1 = valid_points1(indexPairs(:, 1), :); 
%   matchedPoints2 = valid_points2(indexPairs(:, 2), :); 
  % [tform,inlierPtsDistorted,inlierPtsOriginal] = estimateGeometricTransform(matchedPoints2,matchedPoints1,'affine');
%    figure; showMatchedFeatures(I1,I2,inlierPtsOriginal,inlierPtsDistorted);
%    title('Matched inlier points');


matchedOriginalBRISK  = validPtsOriginalBRISK(indexPairsBRISK(:,1));
matchedDistortedBRISK = validPtsDistortedBRISK(indexPairsBRISK(:,2));

matchedOriginalSURF  = validPtsOriginalSURF(indexPairsSURF(:,1));
matchedDistortedSURF = validPtsDistortedSURF(indexPairsSURF(:,2));

% figure(1)
% showMatchedFeatures(I1,I2,matchedOriginalBRISK,...
%             matchedDistortedBRISK)
% title('Putative matches using BRISK & FREAK')
% legend('ptsOriginalBRISK','ptsDistortedBRISK')

%combine
matchedOriginalXY  = ...
    [matchedOriginalSURF.Location; matchedOriginalBRISK.Location];
matchedDistortedXY = ...
    [matchedDistortedSURF.Location; matchedDistortedBRISK.Location];


[tformTotal,inlierDistortedXY,inlierOriginalXY] = estimateGeometricTransform(matchedDistortedXY,matchedOriginalXY,'affine');

figure(2)
showMatchedFeatures(I1,I2,inlierOriginalXY,inlierDistortedXY)
title('Matching points using SURF and BRISK (inliers only)')
legend('ptsOriginal','ptsDistorted')

outputView = imref2d(size(I1));
Ir = imwarp(I2,tformTotal,'OutputView',outputView);
% figure; imshow(Ir);
% title('Recovered image');

