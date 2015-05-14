function [bestColor, LUT] = generateSimpleLUT(X, media, minus, plus, dt)
	% generate a LUT with the parameters X from X(1) nm -minus to +plus, with a step size dt. All in nanometers. 
	% Typical values may be X, -10nm, +20nm, 0.1nm.
	% bestColor is 1 for blue, 2 for 
	t_base = X(1)*1000; % i.e., the background SiO2 film thickness in nm

	d = ((t_base-minus):dt:(t_base+plus))/1000; % range of thicknesses of interest, in microns.

	Ic = zeros(length(d), 4);
    progressbar();
	for n = 1:length(d)
		Ic(n,:) = irisFun([d(n), X(2), X(3)], media);
		progressbar(n/length(d));
    end
	% figure; hold on;
 %    xlabel('Film thickness (\mum)', 'FontSize',16);
 %    ylabel('Normalized Reflected Intensity', 'FontSize',16);
 %    set(gca, 'FontSize', 16);
 %    plot(d, Ic(:,1), 'b');
 %    plot(d, Ic(:,2), 'g');
 %    plot(d, Ic(:,3), 'color', [.5 .5 0]);
 %    plot(d, Ic(:,4), 'r');
 %    axis([.095, .110, 0.3 .5]);
    
	% Select the most sensitive color. We don't want a local min or max, so a simple sum of diffs is sufficient.
	derivs = sum(diff(Ic)); % super easy
	[~, bestColor] = max(abs(derivs));

	LUT = [d', Ic(:, bestColor)];

	% TODO - maybe setup some limits (i.e., LUT must be monotonic etc)
end

% Notes:
% Spot height is about 2nm
% 2nm = 164 - 64 = 100 bits. So, 1nm = 50 bits, in these images