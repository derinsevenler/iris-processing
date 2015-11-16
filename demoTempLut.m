function demoTempLut()

temps = 25:5:70;
h = .090:.003:.110;

for n = 1:length(temps)
	for m = 1:length(h)
		x = [h(m) 1 0];
		xdata = {'air', 'SiO2',temps(n)};
		reflectances(n,m,:) = irisFun(x, xdata);
		progressbar([], m/length(h))
	end
	progressbar(n/length(temps),[])
end
progressbar(1);
surf(h, temps, reflectances(:,:,1));
end