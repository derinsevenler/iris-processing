function[aligned_im2]=points(image1,image2)

[im2pts, im1pts] = cpselect(image2, image1, 'wait', true);

trans2 = fitgeotrans(im2pts, im1pts, 'affine');

Rimage1 = imref2d(size(image1));

aligned_im2 = imwarp(image2, trans2, 'OutputView', Rimage1);


%average images

 

% sum_image = image1 + aligned_im2 + aligned_image3 + aligned_image4 + aligned_image5;
% 
% average_image = sum_image./5;
% 
% imshow(average_image, [90 130])
% 
% imshow(abs(image1-aligned_im2), [0 1])