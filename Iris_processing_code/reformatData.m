function [ outputData ] = reformatData( inputData, numberOfBlocks, rows, columns)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

n = 1;
%split the columns
for i = 1: size(inputData,1)/rows
    dataSingleRow = inputData((1+rows*(i-1)):rows*i,:,:);
    for j = 1 : size(dataSingleRow,2)/columns
    outputData{n} = dataSingleRow(:,(1+columns*(j-1)):columns*j,:);
    n = n+1;
    end   
end
    
if numberOfBlocks == numel(outputData)
    display('Data reorganization successful')
else
    h = warndlg('There were problems in the reorganization of the data');
end


end

