function [annBlueVal,spotblueval,Vs,Van]= spotDet(filt,cent,ra,spotRt,n,rows)
c = spotRt(1);
r = spotRt(2);
[rr,cc]= meshgrid(1:size(filt,1), 1:size(filt,2));


for k=1:rows
     rak=ra(k);
     roOuter=rak*1.5;  
     Rs = (rr - cent(k,2)).^2 + (cc - cent(k,1)).^2 < (rak).^2;
     Ran = ( (rr - cent(k,2)).^2 + (cc - cent(k,1)).^2 > (rak).^2 ) &...
            ( (rr - cent(k,2)).^2 + (cc - cent(k,1)).^2 < (roOuter).^2 );
     Rs=Rs';
     Ran=Ran';
   	 temp= filt.*Rs;
  	 Vs = temp( temp ~= 0);
     spotblueval(k) = median(Vs);
     %figure(n);
     %imshow(temp);
     temp2 = filt.*Ran;
     Van = temp2( temp2~= 0);
   	 annBlueVal(k)= median(Van);
     %figure(n+1);
     %imshow(temp2);
     
     
end
