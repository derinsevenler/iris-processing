function nWater = WaterRefractiveIndexTemp(lambda, temperature)
% nWater = WaterRefractiveIndexTemp(temperature, lambda)
% 
% lambda is in microns
% temperature is the temperature in C, between 20 and 100. Assumes pressure is sea level.



% Parameters and equation from http://www.iapws.org/relguide/rindex.pdf

% Contants
a0 = .2442577733;
a1 = 9.74634476e-3;
a2 = -3.73234996e-3;
a3=2.68678472e-4;
a4=1.58920570e-3;
a5 = 2.45934259e-3;
a6 = .900704920;
a7 = -1.66626219e-2;
lambda_uv=.2292020;
lambda_ir=5.432937;

% Water density vs temperature (kg/m^3)
% Copied from http://www.engineeringtoolbox.com/water-density-specific-weight-d_595.html
water_p_temps=[0 4 10 20 30 40 50 60 70 80 90 100];
p_lookup = [999.8, 1000, 999.7, 998.2, 995.7, 992.2, 988.1, 983.2, 977.8, 971.8, 965.3, 958.4];

% Reference Parameters
T_ref = 273.15; % Kelvin
p_ref = 1000; % kg/m^3
lambda_ref = .589; % microns

% ========================
% Your parameters
% ========================
lambda_range = .4:.01:.7; % microns

% Normalization
T_bar = (temperature+T_ref)/T_ref;
p = interp1(water_p_temps,p_lookup, temperature);
p_bar = p/p_ref;
lambda_bar = lambda/lambda_ref;

% perform calculation

lhs = @(n) ( (n^2-1)/(n^2+2)/p_bar ...
		-	( a0 + a1*p_bar + a2*T_bar + a3*(lambda_bar^2)*T_bar + ...
		 	  a4/lambda_bar^2 + a5/(lambda_bar^2 - lambda_uv^2) + ...
		 	  a6/(lambda_bar^2 - lambda_ir^2) + a7*p_bar^2 ) ...
	 );

nWater = fzero(lhs, 1.33);