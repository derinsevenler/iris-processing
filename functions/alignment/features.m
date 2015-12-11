function [Ir]=features(I1,I2)
%%% Find the corners.

   points1 = detectHarrisFeatures(I1);  %% reference image
   points2 = detectHarrisFeatures(I2);  %% distorted image 

%%%Extract the neighborhood features.

   [features1, valid_points1] = extractFeatures(I1, points1); 
   [features2, valid_points2] = extractFeatures(I2, points2);  

%%%Match the features.

   indexPairs = matchFeatures(features1, features2);

%%%Retrieve the locations of the corresponding points for each image.

   matchedPoints1 = valid_points1(indexPairs(:, 1), :); 
   matchedPoints2 = valid_points2(indexPairs(:, 2), :); 
   [tform,inlierPtsDistorted,inlierPtsOriginal] = estimateGeometricTransform(matchedPoints2,matchedPoints1,'affine');
   figure; showMatchedFeatures(I1,I2,inlierPtsOriginal,inlierPtsDistorted);
   title('Matched inlier points');


outputView = imref2d(size(I1));
Ir = imwarp(I2,tform,'OutputView',outputView);
% figure; imshow(Ir);
% title('Recovered image');

