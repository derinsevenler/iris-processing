% useLUTmulti

% Use a lookup table that you've generated with 'generateAccurateLUT.m' to fit another image. If you haven't generated a lookup table yet, this function isn't for you.


% load the lookup table
[lutFile, lutFolder] = uigetfile('*.mat', 'Select the results file with the lookup table you wish to use');

lutF = load([lutFolder filesep lutFile]);

LUT = lutF.results.LUT;
results.bestColor = lutF.results.bestColor;

% Get the mirror image file info
[file, folder] = uigetfile('*.*', 'Select the mirror file (TIFF image stack also)');
mirFile= [folder filesep file];




% Get the measurement image file info
dir_name = uigetdir;                                
subfolder_path = genpath(dir_name);
subfolder_path_array = strsplit (subfolder_path, ';');
num_folders = length(subfolder_path_array);
subfolder_path_array = subfolder_path_array(1:num_folders - 1);

k = 0;

%go through each folder in the path to check for tiffs
for foldernumber = 1:num_folders - 1
    cd(subfolder_path_array{foldernumber})
    tifFiles = dir('*.tif');
    num_datafiles = length(tifFiles);
    
    %perform fit for each tif and save results
    for m = 1:num_datafiles
        k = k+1;
        
        % load the first image to get the self-reference region
        f = figure('Name', 'Please select a region of bare Si');
        tifdata = imread(tifFiles(m).name, 1);  % load tif file
        [~, selfRefRegion] = imcrop(tifdata, median(double(tifdata(:)))*[.8 1.2]);
        pause(0.01); % so the window can close
        close(f);
        
        % Load the images. Normalize by the mirrors and self-reference regions
        data = zeros(size(tifdata,1), size(tifdata,2), 4);
        for channel = 1:4
            I = imread(tifFiles(m).name, channel);
            mir = imread(mirFile, channel);
            In = double(I)./double(mir);
            sRef = imcrop(In, selfRefRegion);
            data(:,:,channel) = In./median(sRef(:));
        end
        
        %Fit data
        results.heights = interp1(LUT(:,2), LUT(:,1), squeeze(data(:,:,bestColor)), 'nearest', 0);
            
            
        % Save the LUT with the Parameters
        params = lutF.params;
        
        %Export a Tiff file for arraypro analysis
        tiffSaveName = [datestr(now, 'HHMMSS') 'thickness_100x.tif'];
        height_scaled = results.heights.*100;
        height_scaled_int = uint16(height_scaled);
        imwrite(height_scaled_int, tiffSaveName)
        
        %save .mat file
        saveName = [datestr(now, 'HHMMSS') 'results.mat'];
        save([subfolder_path_array{foldernumber} filesep saveName], 'results', 'params');
        
        
    end
end

disp(['Analysis of ' num2str(k) ' images complete!!'])

