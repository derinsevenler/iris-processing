%%%Given a binary input, finds circles of specified radius and returns
%%%center coordinates and radii.
%%%This function detects the spots over a cropped region of the dry chip
%%%image, containing all the spots . The user helped by the imdistline tool
%%%calculates the radius of the spot and gives the program a range for the
%%spots radius. The circle detection is
%%provided by the function imfindcircles, based on hough transform.
%%The function returns the radius and the center of each spot.

function [centers,radii,minn,maxx,row,col]= CircleDet(data)

g=figure;
imshow(data,median(double(data(:)))*[.8 1.2]);
%%%detect the radius of one spot with imdistline
h=imdistline(gca);
position = wait(h);
defaultans = {'10','35'};
asw = inputdlg({'Minimum radius', 'Maximum radius'},'Spot radius', 1, defaultans);
minn=str2num(asw{1});
maxx=str2num(asw{2});

delete(h);
close(gcf);

[centers, radii] = imfindcircles(data,[minn maxx],'ObjectPolarity','bright','Sensitivity',0.93);

%Determine if there are any circles overlapping
D = pdist(centers);
squareD = squareform(D);
triangleD = triu(squareD)+tril(ones(size(squareD))*1000);
indices = find(triangleD<=maxx);
%If they are overlapping, remove the worst one as rated by
%imfindcircles(the last one)
if ~isempty(indices) 
    [~,j] = ind2sub(size(squareD),indices);
    j = unique(j);
    for i = length(j):-1:1
        centers(j(i),:) = [];
        radii(j(i),:) = [];
    end
end



%%%draw circles
figure;imshow(data,median(double(data(:)))*[0.8 1.2]);
h = viscircles(centers,radii);
centers=centers;
radii=radii;
minn=minn;
maxx=maxx;