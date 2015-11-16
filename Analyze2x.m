% % % % %%%%%%%%%% 
% clear all
% close all
% 
% %% choose the kind of analysis you want to run
% flag=menu('Which kind of analisy do you wish to run?','Temperature variations(or etching)','Spots variations');
% if flag==2
%     flag=0;
% end
% 
% %% Get the dried chip image
%  if flag==0
%  [file, folder] = uigetfile('*.*', 'Select the dry chip file (TIFF image stack also)');
%  dryFile= [folder filesep file]; 
%  dry= imread(dryFile,1);
%  end
%  
% %% Get the mirror image file info
% 
% [file, folder] = uigetfile('*.*', 'Select the mirror file (TIFF image stack also)');
% mirFile= [folder filesep file];
% 
% %% Get the tiff Image
% [file, folder] = uigetfile('*.*', 'Select the data file (TIFF image stack also)');
% tifFile= [folder filesep file];
% 
% nColor=inputdlg('How many colors have you used to acquire the images?');
% nColor=str2num(nColor{1});
% info=imfinfo(tifFile);
% numIm=numel(info)/nColor;
% numIm=100;
% % ===================================================================================================================
% % read temperature file
% [Tempfile, Tempfolder] = uigetfile('*.*', 'Select the Temperature file');
% Tfile= [Tempfolder filesep Tempfile]; 
% Temp=importdata(Tfile);
% TempIm=Temp_assignment(Temp,numIm);
% 
% % Align the blue images 
% 
% color=1; %(blue)
% f = figure('Name', 'Please select a region of bare Si');
% im = imread(tifFile, color);
% [~, selfRefRegion] = imcrop(im, median(double(im(:)))*[.8 1.2]);
% pause(0.01); % so the window can close
% close(f);
% mir=imread(mirFile,1);
% In = double(im)./double(mir);
% sRef = imcrop(In, selfRefRegion);
% data1 = In./median(sRef(:));
% 
% %% Align the first image of the stack to the dry image
% 
% if flag==0 %%if you are analyzing the spots you need to align to the dry image, otherwise no.
% contMain=1;
% repeat=0;
% count=0;
% channel=0;
% [Ial1,theta,tx,ty,thetaDry]=regWetDry(contMain,repeat,dry,In,data1)
%    align(:,:,1,1)=Ial1;
% else
%    align(:,:,1,1)=data1;
% end
% 
% %%% Align all the blue wet images in the stack to the first one
% 
% if nColor>1
%  progressbar('Align Blue Im','Align other colors Im');
% else 
%  progressbar('Align Blue Im')
% end
% % figure(2)
% % [dd,rect]=imcrop(Ial1);
% 
% 
% for channel = (color+nColor):nColor:numIm*nColor   
%     
%     I = imread(tifFile,channel);
%     In = double(I)./double(mir);
%     sRef = imcrop(In, selfRefRegion);
%     data = In./median(sRef(:));  
%     dataOr(:,:,1,1)=data1;  %to be adapt for 4 colors
%     dataOr(:,:,((channel-color)/nColor)+1,color)=data;
% 
%      if flag==0 
% %         ww=imcrop(data,rect);
%         count=1;
%         [Ial,delta(((channel-color)/nColor),:),angle(((channel-color)/nColor),:)]=regWet(Ial1,data,data,count);
%      else
%         [Ial]=regWet(dry,data,data,count),delta(((channel-color)/nColor),:),angle(((channel-color)/nColor),:)=regWet(data1,data,count);
%      end
% 
%     align(:,:,((channel-color)/nColor)+1,color)=Ial;
%     progressbar(channel/numIm)
% 
%  end
% 
% %%%%=================================================================================================================
% 
% %%Align all the images (other colors) using the values found for the blue one
% 
%  if nColor >1
%  
%     for color= 2:nColor
%       I  = imread(tifFile, color);
%       mir=imread(mirFile,color);
%       In = double(I)./double(mir);
%       sRef = imcrop(In, selfRefRegion);
%       data = In./median(sRef(:));
%         if flag==0
%            temp=imrotate(data,theta,'crop');
%            align(:,:,1,color)=imtranslate(temp,[ty tx]); 
%         else
%            align(:,:,1,color)=data;
%         end
%            for channel = (color+nColor):nColor:(numIm*nColor)
%                I = imread(tifFile, channel);
%                In = double(I)./double(mir);
%                sRef = imcrop(In, selfRefRegion);
%                data = In./median(sRef(:));
%                temp2=imrotate(data,angle(((channel-color)/nColor),:),'crop');
%                align(:,:,((channel-color)/nColor)+1,color)=imtranslate(temp2,-delta(((channel-color)/nColor),:));  
%                progressbar([],channel/numIm);
%            end
%     end
%  end

% =========================================================================================================================
% Detect spots 

%  for color=1:nColor
%     filt=boxcarAv(align(:,:,:,color));
%      if color==1
%          numSpots=1;
%          if flag==1
%              out = inputdlg('How many region of the background do you want to analyze?');
%              numSpots=str2num(out{1});
%              numSpots=numSpots+1; %%regions of the background plus one region of oxide
%          end   
%          
%          minimum=10;
%          maximum=20;
%          
%          for n = 1:numSpots
%              g = figure; 
%              
%              if flag==1
%                 if n==1
%                    g=figure('Name','select first a region of the oxide');
%                 else      
%                    g=figure('Name','Select a region of the background');
%                 end
%               Icrop=align(:,:,1,1);
%               [spotR, spotRect(n,:)] = imcrop(Icrop,median(double(Icrop(:)))*[.8, 1.2]); 
% 	          pause(0.05);
%  	          close(g);
%              end 
%              
%             if flag==0
%                g=figure('Name','crop one region containing all the spots you wish to analyze');
%                [spotR, spotRect(n,:)] = imcrop(dry, median(double(dry(:)))*[.8, 1.2]); 
%                pause(0.05);
%                close(g);
%                
% %%%%%%%%%%%%%%choose one method%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%              
% %             [Gmag, Gdir] = imgradient(spotR,'sobel');
% %             BW= edge(Gmag,'canny');
% %             binary=BW;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%              spotad=imadjust(spotR);
%              level=graythresh(spotad);
%              binary=im2bw(spotad,level);
%              f=0;
%              [center,rad,minimum,maximum]= CircleDet(binary,minimum,maximum,f);
%             end  
%          end
%       end
%   
% %%%% Calculate spots and annulus values
%       if flag==0
%       for channel=1:numIm      
%         if color==1
%             if channel==1
%              [center,rad,centerOld,radOld,row,col,gridx,gridy]=GridSpot(center,rad,spotR,spotRect);
%           %% sorting detect spots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           matxy=sorting(center,rad,gridx,gridy,row,col);
%        
%           %%%%%% ricrop if not all the spots have been detected. 
%           nd=find(matxy==0);
%           if(isempty(nd))
%               nd=1;
%           end
%           if nd~=1
%               f=1;  
%                g=figure('Name','crop a region containing the undetected spots');
%                [spotRadd, spotRectadd(n,:)] = imcrop(spotR, median(double(spotR(:)))*[.8, 1.2]); 
%                pause(0.05);
%                close(g);
%                spotad=imadjust(spotRadd);
%                level=graythresh(spotad);
%                binaryAdd=im2bw(spotad,level);
%                [centerAdd,radAdd,minimum,maximum]= CircleDet(binaryAdd,minimum,maximum,f);  
%                %% find the correct coordinates and add the new detected spots
%                if length(centerAdd>0)  %if nothing more has been detected just keep going0
%                centAdd= spotRect(1:2)+spotRectadd(1:2)+centerAdd;
%                center=vertcat(center,centAdd);
%                rad=vertcat(rad,radAdd);
%                end
%           
%           matxy=sorting(center,rad,gridx,gridy,row,col);
%           end
%          end
%          end
%           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%     
%       
%      for g=1:col
%               centCol=matxy(1:row,1:2,g);
%               radCol=matxy(1:row,3,g);
%               [annulus.heights(1:row,channel,g,color),results.heights(1:row,channel,g,color)]= spotDet(dry,filt(:,:,channel),centCol,radCol,spotRect,spotR,channel,row);
%      end
%  end
%  end
%  end
%       
% if flag==1 
%     for color=1:nColor
%        for channel=1:numIm
%            col=align(:,:,channel,color);
%            spotO=imcrop(col,spotRect(1,:));
%            for n=1:numSpots
%                spotB=imcrop(col,spotRect(n,:));
%                figure; imshow(spotB);
%                oxideVal(n,channel,color)=median(spotO(:));
%                backVal(n,channel,color)=median(spotB(:));
%            end
%        end 
%     end
% end 

%% ======================================================================================
%%Apply lookup table
%%======================================================================================
%Display and save the results.

  if flag==0
% 
% %%save results in an excel file
Diff=(annulus.heights-results.heights)*-1;

for color=1:nColor
    switch color
      case 1 
        c='Blue';
      case 2 
        c='Green';
      case 3
        c='Orange';
      case 4
        c='Red';
    end
    
    name1=strcat(c,'Diff.xlsx');
    name2=strcat(c,'Annulus.xlsx');
    name3=strcat(c,'Spots.xlsx');
    
    for g=1:col
    numSheet=strcat('column',num2str(g));    
    S=Diff(:,:,g,color);
    xlswrite(name1,S,numSheet);
    R=results.heights(:,:,g,color);  
    xlswrite(name3,R,numSheet);
    A=annulus.heights(:,:,g,color);
    xlswrite(name2,A,numSheet);
    end 
end

%%graph results
for color=1:nColor
    for g=1:col
        for channel=1:numIm
         res=results.heights(:,channel,g,color);  
         res(isnan(res))=[];
         ann=annulus.heights(:,channel,g,color);
         ann(isnan(ann))=[];
         resultAv(:,channel,g,color)=mean(res);
         annAv(:,channel,g,color)=mean(ann);
         DiffAv=resultAv-annAv;
        end 
    end
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%delete outliers
diffNoutOld=DiffAv;
[diffNout]= outliers(DiffAv,row,col,color,numIm);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for color=1:nColor
     for g=1:col 
          figure(g);
         h=subplot(4,1,1);
         plot(TempIm(:,2),resultAv(1,:,g,color),'o');ylabel('Spot');
         subplot(4,1,2);
         plot(TempIm(:,2),annAv(1,:,g,color),'o');ylabel('Background');
         subplot(4,1,3);
         plot(TempIm(:,2),DiffAv(1,:,g,color),'o');ylabel('Diff');xlabel('Temperature');
         subplot(4,1,4);
         plot(TempIm(:,2),diffNout(1,:,g,color),'o');ylabel('DiffnoOut');xlabel('Temperature');
         name=strcat(c,'-','col',num2str(g));
         saveas(h,name,'fig');
         saveas(h,name,'tiff');
         
         
     end
    end

%%save alignment graph


 figure(n+1)
 g=subplot(3,1,1); 
 plot(tx,'o'); ylabel('tx');
 subplot(3,1,2);
 plot(ty,'o');ylabel('ty');
 subplot(3,1,3)
 plot(ang);ylabel('angle');xlabel('Images');
 name=strcat('alignment');
 saveas(g,name,'tiff');
 saveas(g,name,'fig');
end
% 
% 
