%% this script is to express variability between spots as a function of expected shot noise variation

% takes data in the form of data(rows,columns,timestep)
% make sure to update the following constants to match your
% signal_intensity, spot_size, number_of_frames, number_of_spots,
% slope_LUT, and mirror_intensity.

%% Define expected shot noise
% this will depend on approximate spot intensity, spot size, number of frames, and number
% of spots measured


signal_intensity = 5000;
spot_size = 860;
number_of_frames = 50;
number_of_spots = 1;


shot_noise = sqrt(signal_intensity/(spot_size * number_of_frames * number_of_spots));

%% Express shot noise in nm
% first normalize by the mirror intensity and then mutiply by the slope of
% the LUT to obtain nm from the normalized shot noise.


slope_LUT = 102.1103; %nm/normalized reflectivity
mirror_intensity = 10300;

norm_shot_noise = shot_noise/mirror_intensity;
shot_noise_nm = norm_shot_noise * slope_LUT;

%% Calculate the standard deviation between the images of each spot
%for a data in a 3D array rowxcolumnximage

data_size = size(data);

for i = 1 : data_size(1)
    for j = 1: data_size(2)
        temp = [];
        for k = 1: data_size(3)
            temp(k) = data(i,j,k);
                       
        end
        variability.measured(i,j) = std(temp);
    end
end

%% express the variability as a function of shot noise variability

 variability.aafo_shot_noise = variability.measured/shot_noise_nm;
 
 
 %% Plot the variability
 
 figure(1)
 histogram(variability.aafo_shot_noise)
 xlabel(['noise as a function of shot noise (' num2str(round(shot_noise_nm,4)) 'nm)']);
 ylabel('number of spots')
    ax = gca;
    ax.LineWidth = 2;
    ax.FontSize = 16;
    ax.FontWeight = 'bold';
    ax.Box = 'off';

