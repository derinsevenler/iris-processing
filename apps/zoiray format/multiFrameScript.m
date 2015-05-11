% This script is for working with Zoiray-formatted (.mat) image files.


% Fit Parameters
media = 'air';
dApprox = 100; % nm

% LUT Parameters, in nm
minus = 2;
plus = 15;
dt = .1;

% Get image file names
% This means "Grab any file that contains the phrase 'DataSet' and ends with '.mat'"
imageDir = uigetdir;
nameRegEx = '^.*DataSet.*\.mat$'; 
fList = regexpdir(imageDir, nameRegEx);

%% fit the first image to get the parameters
ds = load(fList{1});
[d, bestColor, LUT, X] = singleFrameLUT(ds.data, media, dApprox, minus, plus, dt);

%% fit the whole stack with those parameters
multiFrameLUT(fList{2:end}, bestColor, LUT);