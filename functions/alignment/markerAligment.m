function [Ial] = markerAligment(im1, im)

z = 0;
n = 0;
Ial = im;
while z == 0
    n = n+1;
    g=figure('Name','Please select an alignment marker');
    [alignmentmark1,alignCord]=imcrop(im1,median(double(im1(:)))*[.8 1.2]);
    close(g);
    %alignmentmark1 = im1;
    
    alignmentmark=imcrop(Ial,alignCord);
    %alignmentmark = Ial;
    
    [~,delta(n,:),angle(n,:)]=regWet(alignmentmark1,alignmentmark,alignmentmark);
    deltaMean = mean(delta,1);
    angleMean = mean(angle,1);
    Ial=imrotate(Ial,angleMean,'crop');
    Ial=imtranslate(Ial,-deltaMean);
    
    error = (double(Ial)-double(im1)).^2;
    errorsum = sum(error(:));
      
    i = figure('Position', [500 500 700 500], 'Name', ['Histogram of the difference squared with sum = ' num2str(errorsum)]);
    histogram(error);
    
    h = figure('Position', [100 100 1200 900], 'Name', 'Are the images aligned?');
        
       

        % Create ok push button
        okbtn = uicontrol('Style', 'pushbutton', 'String', 'ok',...
            'Position', [20 20 50 20],...
            'Callback', @continueCB);
        % Create ok push button
        nobtn = uicontrol('Style', 'pushbutton', 'String', 'no',...
            'Position', [920 20 50 20],...
            'Callback', @startOver);
        
        hold on
        imshow((double(im1)+double(Ial))/2);
        hold off
        
        
        waitfor(h)
        
end

        function continueCB(hObject, callbackdata)
        z=1;
        close(h)
        end
    function startOver(hObject, callbackdata)
        z=0;
        close(h)
    end
end
