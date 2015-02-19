classdef ImageBuffer  < handle
    properties
        counter
        data
        width
        height
        size
        dtype
    end
    
    methods
        function obj = ImageBuffer(imageHeight, imageWidth, bufferSize, dataType)
            if nargin < 4
                obj.dtype = 'uint8';
            else
                obj.dtype = dataType;
            end
            obj.counter = 1;
            obj.data = zeros([imageHeight, imageWidth, bufferSize], obj.dtype);
            obj.width = imageWidth;
            obj.height = imageHeight;
            obj.size = bufferSize;
        end
        
        function obj = add(obj, newImage)
            obj.data(:,:, obj.counter) = newImage;
            obj.counter = obj.counter + 1;
            if obj.counter > obj.size
                obj.counter = 1;
            end
        end
    end
end