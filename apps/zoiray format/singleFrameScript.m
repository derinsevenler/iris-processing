% This script is for working with Zoiray-formatted (.mat) image files.


%% Load image
[filename, pathname] = uigetfile('*.mat', 'Select a Zoiray Dataset .mat file');
dataset = load([pathname filesep filename]);
data = dataset.data;

% Fit Parameters
media = 'air';
dApprox = 30; % nm
% LUT Parameters
minus = 5;
plus = 5;
dt = .1;

[d, bestColor, LUT, X] = singleFrameLUT(data, media, dApprox, minus, plus, dt);

figure; imshow(d, dApprox*[.8, 1.2]); % for fun
% save to a subdirectory 'results'
save([pathname filesep filename 'fastfit' datestr(now) '.mat'], 'd', 'bestColor', 'LUT', 'X');
