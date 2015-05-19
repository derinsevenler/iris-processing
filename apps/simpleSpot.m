% simpleSpot is a basic utility for measuring spot heights. Spots should not be within 1 radius from  any edge.

% get the image
f = uigetfile('*.*', 'Select the results mat file:');
data = load(f);
im = data.results.data_fitted;

out = inputdlg('How many spots do you wish to analyze?', 'Number of spots', 1,{'1'});
numSpots = str2num(out{1});

for n = 1:numSpots
	g = figure;
	[spotR, spotRect] = imcrop(im, median(im(:))*[.8, 1.2]);
	pause(0.05);
	close(g);

	c = spotRect(1);
	r = spotRect(2);
	centroid = [r+spotRect(3)/2, c+spotRect(4)/2];
	rs = min(spotRect(3:4)/2);
	roInner = max(spotRect(3:4)/2);
	roOuter = roInner+rs; % thinner for more oblong spots, thicker for more spherical spots. I have a hunch this will tend to improve the adaptability of ratio of their areas.


	% crop the circle and an annulus
	[rr, cc] = meshgrid(1:size(im,1), 1:size(im,2));

	Rs = (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < rs^2;

	Ran = ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 > roInner^2 ) & ...
		  ( (rr - centroid(1)).^2 + (cc - centroid(2)).^2 < roOuter^2 );

	Rs = Rs';
	Ran = Ran';
	% get the average value for each region
	temp = im.*Ran;
	Van = temp( temp ~= 0);
	Dan = median(Van);

	temp = im.*Rs;
	Vs = temp( temp ~= 0);
	Ds = median(Vs);

	h = Ds-Dan;
	disp([ 'Spot height is ' num2str(round(h*100)/100) ' nm.']);

	% Show the regions

	r1 = centroid(1) - (roOuter +5); % fudge factor
	r2 = centroid(1) + (roOuter +5);
	c1 = centroid(2) - (roOuter +5); % fudge factor
	c2 = centroid(2) + (roOuter +5);

	imReg = im(r1:r2,c1:c2);
	h = figure;
	imshow(imReg, median(imReg(:))*[.8, 1.2], 'InitialMagnification',500);

	% draw a circle for the spot, and two for the annulus
	th = 0:pi/50:2*pi;
	% spot
	xunit = rs * cos(th) + centroid(2)- c1;
	yunit = rs * sin(th) + centroid(1)- r1;
	hold on; plot(xunit, yunit, '-b');

	%annulus
	xunit = roInner * cos(th) + centroid(2)- c1;
	yunit = roInner * sin(th) + centroid(1)- r1;
	hold on; plot(xunit, yunit, '-r');
	xunit = roOuter * cos(th) + centroid(2)- c1;
	yunit = roOuter * sin(th) + centroid(1)- r1;
	hold on; plot(xunit, yunit, '-r');

	pause(3);
	close(h);
end
