function nWater = WaterRefractiveIndexTemp(temp, lambda)
% nWater = WaterRefractiveIndexTemp(temp, lambda)
% 
% temp is the temperature in C, between 20 and 100. Assumes pressure is sea level.
% lambda is in nanometers



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
T_range = 30:2:80; % in C
lambda_range = .4:.01:.7; % microns

% Normalization
T_bar = (T_range+T_ref)/T_ref;
p_range = interp1(water_p_temps,p_lookup, T_range);
p_bar = p_range/p_ref;
lambda_bar = lambda_range/lambda_ref;

% perform calculation

n = zeros(length(T_bar),length(lambda_bar));
for x = 1:length(T_bar)
	for y = 1:length(lambda_bar)

		lhs = @(n) ( (n^2-1)/(n^2+2)/p_bar(x) ...
			-	( a0 + a1*p_bar(x) + a2*T_bar(x) + a3*(lambda_bar(y)^2)*T_bar(x) + ...
			 	  a4/lambda_bar(y)^2 + a5/(lambda_bar(y)^2 - lambda_uv^2) + ...
			 	  a6/(lambda_bar(y)^2 - lambda_ir^2) + a7*p_bar(x)^2 ) ...
		 );

		n(x,y) = fzero(lhs, 1.33);
	end
end
figure; plot(lambda_range, n');
figure;plot(T_range, n);