function spotHeight = diffToHeight(diffReflectance, temperature, backgroundH, lut)
% function spotHeight = diffToHeight(temperature, backgroundH, diffReflectance, lut)
% 
% Convert 'difference between reflectance of spot and background' to 'spot height in nanometers'.
% 
% diffReflectance - [(spot reflectance) - (background reflectance)]. This measurement should already 
% 		have been mirror-normalized and self-reference (bare Si region) normalized.
% temperature - temperature of the substrate at that particular time, in celsius.
% background H - the thickness of the background oxide, in nanometers.
% lut - the temperature-dependent look up table, made using GenerateLUT. It must have 'temperature'
% 		within it's range, of course.

% get the lut heights at this temperature, corresponding wtih lut.R
H = interp2(lut.T, lut.R, lut.H, temperature, lut.R);

% Derivative dH/dR
dHdR = gradient(H)./gradient(lut.R); %diff(lut.R) is probably constant, which is fine

% evaluate at this particular background thickness
d = interp1(H, dHdR, backgroundH)

spotHeight = diffReflectance*d;