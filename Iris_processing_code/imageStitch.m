function [ slide ] = imageStitch( alignedBlocks)
%imageStitch concatenates slide images into one slide



slide = alignedBlocks{1}(:,:,:);

for i = 2:numel(alignedBlocks)
    %pad arrays in order to obtain the same number of rows.
    if size(slide,1) > size(alignedBlocks{i}, 1)
        alignedBlocks{i} = padarray(alignedBlocks{i},[size(slide,1)-size(alignedBlocks{i}, 1), 0], median(alignedBlocks{i}(:)), 'pre');
    elseif size(alignedBlocks{i}, 1) > size(slide,1)
        slide = padarray(slide,[size(alignedBlocks{i}, 1)-size(slide,1), 0], median(slide(:)), 'pre');  
    end
    %concatenate arrays
    slide = cat(2, slide, alignedBlocks{i});
end
    


end

