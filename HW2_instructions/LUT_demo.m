%% 讀取 *.cube 格式的 3D-LUT, 改變影像色調
clc, clear, close all
imageFile='s.jpg';
cubeFile='LUTs/Paladin 1875.CUBE';

% 讀取影像
img = im2double(imread(imageFile));

% 讀取 .cube LUT
[lut, lutSize] = readCubeFile(cubeFile);

% 將影像套用 LUT
imgLUT = applyLUT(img, lut, lutSize);

% 顯示結果
figure;
subplot(1,2,1); imshow(img); title('原始影像');
subplot(1,2,2); imshow(imgLUT); title('套用 LUT 後影像');


%% 讀取 3D-LUT
function [lut, lutSize] = readCubeFile(cubeFile)
fid = fopen(cubeFile, 'r'); % 以唯讀模式開檔
lut = [];
lutSize = 0;
while ~feof(fid)
    line = strtrim(fgetl(fid));
    if startsWith(line, 'LUT_3D_SIZE') % 偵測3D-LUT的尺寸
        lutSize = sscanf(line, 'LUT_3D_SIZE %d');
    elseif isempty(line) || startsWith(line, '#')
        continue;
    else
        values = sscanf(line, '%f %f %f'); %讀取對照表資料
        if numel(values) == 3
            lut = [lut; values'];
        end
    end
end
fclose(fid);
lut = reshape(lut, [lutSize, lutSize, lutSize, 3]);
end

%% 使用 3D-LUT 對輸入影像調色
function imgOut = applyLUT(img, lut, lutSize)
% 將影像 RGB 值映射到 LUT 索引範圍
imgScaled = img * (lutSize - 1) + 1;

% 三線性插值
imgOut = zeros(size(img));
for c = 1:3
    imgOut(:,:,c) = interp3( ...
        1:lutSize, 1:lutSize, 1:lutSize, ...
        lut(:,:,:,c), ...
        imgScaled(:,:,2), imgScaled(:,:,1), imgScaled(:,:,3), ...
        'linear', 0);
end
end
