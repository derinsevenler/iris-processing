function [center,rad,centerOld,radOld,row,col,totx,toty]= GridSpot2(cent,ra,spotRe,spotRt)

%%  detect "false positive" spots and construct the grid used for spots sorting 

numS=inputdlg('How many rows and columns of spots do you wish to analyze [nrow ncol]?');
numS=str2num(numS{1});
row=(numS(1));
col=(numS(2));

%% save in posDry the coordinates of the first row of spots
 

for z=1:(col+1) 
     if z==col+1
      p=figure('Name','Select the center of the first spot of the second row you want to analyze');
     else
      p=figure('Name', 'Select the center of each spot of the first row you want to analyze'); 
     end 
    imshow(spotRe,median(double(spotRe(:)))*[0.8 1.2]);
    g=impoint(gca);
    pause(0.5);
    posDry(z,:)=getPosition(g);
    delete(p);
    close(gcf);
end
% 
%% distance between spots 
p1=posDry(1,:);
p2=posDry(col+1,:);
distx=p2(1)-p1(1);
disty=p2(2)-p1(2);
% 
% %% create the grid

if distx==0
   addx=zeros(1,row);
else 
    if row>1 
   addx=[0:distx:distx*(row-1)];
    else 
    addx=0;
    end
end

if disty==0
    addy=zeros(1,row);
else
    if row>1
    addy=[0:disty:disty*(row-1)];
    else 
    addy=0;    
    end
end
        
for j=1:col
    %% coordinates of the spots on the other rows
    totx(j,1:length(addx))=posDry(j,1)+addx; 
    toty(j,1:length(addy))=posDry(j,2)+addy;
end

totx=totx';
toty=toty';

%%%===========================================================================
ind.x=zeros(row,col);
ind.y=zeros(row,col);

tol=2; %%tol give the radius starting from the center of the spot within the detected spots is not discarded
range=round(mean(ra)*tol);

for z=1:length(cent(:,1));  
     xC=cent(z,1);
     yC=cent(z,2);
         for r=1:row
            for c=1:col
                x=totx(r,c);
                y=toty(r,c);
                if (xC<x+range&&xC>x-range&&yC<y+range&&yC>y-range)==1
                   fl(r,c,z)=1;
                else
                   fl(r,c,z)=0;
                end
           end
         end 
       if (find(fl(:,:,z)==1))~=0
           log(z)=1;
       else
           log(z)=0;
       end
end

idxF=find(log==0);
centerOld=cent;
cent(idxF,:)=[];
radOld=ra;
ra(idxF,:)=[];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% show the grid and the detected spots
figure(3);imshow(spotRe,median(double(spotRe(:)))*[0.8 1.2]);
hold on
plot(totx,toty,'bo');  %% totx toty are the coordinates of the points of the calculated grid
hold on
plot(centerOld(:,1),centerOld(:,2),'mo'); %%centerOld contains all the detected circles
hold on
plot(cent(:,1),cent(:,2),'go'); %%cent contains just the dectected circles that have a correspondance in the  grid
%legend('Grid','Detected','True'); 
cent(:,1)=cent(:,1)+spotRt(1);
cent(:,2)=cent(:,2)+spotRt(2);
center=cent;
rad=ra;
totx=totx+spotRt(1);
toty=toty+spotRt(2);

end


