%%%This function detect the spots over a cropped region of the dry chip
%%%image, containing all the spots . The user helped by the imdistline tool
%%%calculate the radius of the spot and give to the program a range for the
%%spots radius. The circle detection is
%%provided by the function imfindcircles, based on hough transform.
%%The function returns the radius and the center of each spot.

function [centers,radii,minn,maxx,row,col]= CircleDet(data,minn,maxx,f)

g=figure;
imshow(data,median(double(data(:)))*[.8 1.2]);
%%%detect the radius of one spot with imdistline
h=imdistline(gca);
position = wait(h);
defaultans = {'15','20'};
asw = inputdlg({'Minimum radius', 'Maximum radius'},'Spot radius', 1, defaultans);
minn=str2num(asw{1});
maxx=str2num(asw{2});

delete(h);
close(gcf);

[centers, radii] = imfindcircles(data,[minn maxx],'ObjectPolarity','bright','Sensitivity',0.93);

%%%draw circles
figure;imshow(data,median(double(data(:)))*[0.8 1.2]);
h = viscircles(centers,radii);
centers=centers;
radii=radii;
minn=minn;
maxx=maxx;