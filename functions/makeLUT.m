function [bestColor, LUT] = makeLUT(X, medium, film, temperature, minus, plus, dt)
	% generate a LUT with the parameters X from X(1) -minus to +plus, with a step size dt, in microns.
	% Typical values 
	% bestColor is 1 for blue, 2 for green, etc
	t_base = X(1)*1000; % i.e., the background SiO2 film thickness in nm

	d = ((t_base-minus):dt:(t_base+plus))/1000; % range of thicknesses of interest, in microns.

	Ic = zeros(length(d), 4);
    progressbar();
	for n = 1:length(d)
		Ic(n,:) = irisFun([d(n), X(2), X(3)], {medium, film, temperature});
		progressbar(n/length(d));
    end
    
	% Select the most sensitive color. We don't want a local min or max, so a simple sum of diffs is sufficient.
	derivs = sum(diff(Ic)); % super easy
	[~, bestColor] = max(abs(derivs));

	LUT = [d', Ic(:, bestColor)];

	% TODO - maybe setup some limits (i.e., LUT must be monotonic etc)
end
