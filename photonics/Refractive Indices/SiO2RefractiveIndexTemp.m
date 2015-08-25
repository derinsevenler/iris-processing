function nSiO2 = SiO2RefractiveIndexTemp(lambda, temperature)
% nSiO2 = SiO2RefractiveIndexTemp(temperature, lambda)
% 
% lambda is in microns
% temperature is the temperature in C, between 20 and 100. Assumes pressure is sea level.
%
% Parameters and equation from Gosh et al. Temperature-Dependent Sellmeier Coefficients and Chromatic Dispersions for Some Optical Fiber Glasses (1994)


A = @(T)(1.31552+6.90754e-6*T);
B = @(T)(.788404+2.35835e-5*T);
C = @(T)(.011099+5.84758e-7*T);
D = @(T)(0.91316+5.48368e-7*T);
E = 100;

nSiO2 = sqrt(A(temperature)+ B(temperature)/(1-C(temperature)/lambda^2) + D(temperature)/(1-E/lambda^2));