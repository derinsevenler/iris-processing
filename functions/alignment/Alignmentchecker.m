%%%%This function aligns the images and provides a quality of alignment
%%%%feedback.  The user can approve the automatic alignment or manually
%%%%align the images.



function [Ial] = Alignmentchecker(im1, im)


z = 0;
Ial = im;

yZeroCoordinates = find(not(mean(im)));
xZeroCoordinates = find(not(im(:,1)));
if isempty(yZeroCoordinates) == 0 
    if yZeroCoordinates(1) <= 100
        ycoord = yZeroCoordinates(end);
        xy = 0;
    elseif yZeroCoordinates(1) >= 100
        ycoord = yZeroCoordinates(1);
        xy = 1;
    end
else
    ycoord = size(im,2);
    xy = 1;
end

if xy == 0
    error = (double(Ial(:,ycoord:end)-double(im1(:, ycoord:end)))).^2;
elseif xy == 1
    error = (double(Ial(:,1:ycoord)-double(im1(:, 1:ycoord)))).^2;
end

errorpPixel = sum(error(:))/numel(im1);

i = figure('Position', [800 10 700 500], 'Name', ['Histogram of the difference squared with error per pixel = ' num2str(errorpPixel)]);
histogram(error);


h = figure('Position', [10 10 700 900], 'Name', 'Are the images aligned well enough?');



% Create ok push button
okbtn = uicontrol('Style', 'pushbutton', 'String', 'ok',...
    'Position', [20 20 50 20],...
    'Callback', @continueCB);
% Create ok push button
nobtn = uicontrol('Style', 'pushbutton', 'String', 'no',...
    'Position', [620 20 50 20],...
    'Callback', @startOver);

hold on
if xy == 0
    imshow((double(im1(:, ycoord:end))+double(Ial(:, ycoord:end)))/2);
elseif xy == 1
    imshow((double(im1(:, 1:ycoord))+double(Ial(:, 1:ycoord)))/2);
end
hold off


waitfor(h)
close(i)

while z == 1
    [Ial,delta,angle]=regWet(im1,im,im);
    %Ial=points(im1,im);
    error = (double(Ial)-double(im1)).^2;
    errorpPixel = sum(error(:))/numel(im1);
    
    i = figure('Position', [800 10 700 500], 'Name', ['Histogram of the difference squared with error per pixel = ' num2str(errorpPixel)]);
    histogram(error);
    
    h = figure('Position', [30 30 700 900], 'Name', 'Are the images aligned well enough?');
    
    
    
    % Create ok push button
    okbtn = uicontrol('Style', 'pushbutton', 'String', 'ok',...
        'Position', [20 20 50 20],...
        'Callback', @continueCB);
    % Create ok push button
    nobtn = uicontrol('Style', 'pushbutton', 'String', 'no',...
        'Position', [620 20 50 20],...
        'Callback', @startOver);
    
    hold on
    imshow((double(im1)+double(Ial))/2);
    hold off
    
    
    waitfor(h)
    close(i)
end




    function continueCB(hObject, callbackdata)
        z=0;
        close(h)
    end
    function startOver(hObject, callbackdata)
        z=1;
        close(h)
    end
end
