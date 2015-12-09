%%%%This function aligns the images and provides a quality of alignment
%%%%feedback.  The user can approve the automatic alignment or manually
%%%%align the images.



function [Ial] = Alignmentchecker(im1, im)


z = 0;
[Ial,delta,angle]=regWet(im1,im,im);


error = (double(Ial)-double(im1)).^2;
errorppixel = sum(error(:))/numel(im1);

i = figure('Position', [800 10 700 500], 'Name', ['Histogram of the difference squared with error per pixel = ' num2str(errorppixel)]);
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
imshow((double(im1)+double(Ial))/2);
hold off


waitfor(h)
close(i)

while z == 1
    Ial=points(im1,im);
    error = (double(Ial)-double(im1)).^2;
    errorppixel = sum(error(:))/numel(im1);
    
    i = figure('Position', [800 10 700 500], 'Name', ['Histogram of the difference squared with error per pixel = ' num2str(errorppixel)]);
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
