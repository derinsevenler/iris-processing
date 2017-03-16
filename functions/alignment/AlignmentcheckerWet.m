%%%%This function aligns the images and provides a quality of alignment
%%%%feedback.  The user can approve the automatic alignment or manually
%%%%align the images.



function [Ial] = AlignmentcheckerWet(im1, im)


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

if errorpPixel >= 0.1
    h = figure('Position', [50 50 700 900], 'Name', ['Are the images aligned well enough? Error Per pixel is ' num2str(errorpPixel)]);

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
    
end

%Button call backs
    function continueCB(~, ~)
        Ial = Ial;
        close(h)
    end
    function startOver(~, ~)
        Ial = NaN(size(Ial));
        close(h)
    end

end
