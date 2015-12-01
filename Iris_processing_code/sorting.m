 function matxy=sorting(center,rad,gridx,gridy,row,col)
 centrad=vertcat(center',rad');
 centrad=centrad'; %% contains cooordinates of the centers and radius of the respective circles.
 sortx=sortrows(centrad,1);   %% sort centrad with respect to the first dimension of the matrix (rows)
 
 matxy=zeros(row,3,col);  
 tol=40;
 for z=1:length(centrad(:,1))  %% find index of row and column of each center using the grid as reference. The tol value could need to be changed.
      idxCol(z,1)=find(centrad(z,1)<(gridx(1,:)+tol) & centrad(z,1)>(gridx(1,:)-tol)) 
      idxRow(z,1)=find(centrad(z,2)<(gridy(:,1)+tol) & centrad(z,2)>(gridy(:,1)-tol))
 end 

 centrad=vertcat(centrad',idxCol',idxRow');
 centrad=centrad';
 
 for k=1:length(centrad(:,1))
     icol=centrad(k,4);
     irow=centrad(k,5);
     matxy(irow,1:3,icol)=centrad(k,1:3);  %% center coord and radius sorted by rows and col
 end

             
             
           