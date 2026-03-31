%% 讀取 ColorChecker 中的RGB數值

%% (1)框選影像中 ColorChecker 的四角點:
% 讀取影像
img = im2double(imread('cc1.jpg'));

imshow(img);
title('請用滑鼠框選 ColorChecker 四個角點 (依序點選左上、右上、右下、左下)');

% 使用 drawpolygon 取得四邊形
h = drawpolygon('LineWidth',2,'Color','r');

% 取得頂點座標
srcPoints = h.Position;   % Nx2 matrix, 每列為 [x, y]

%% (2)顯示透視校正 ColorChecker 影像:
% 定義目標矩形大小 (例如 600x400 像素)
targetW = 600;
targetH = 400;
dstPoints = [0 0; targetW 0; targetW targetH; 0 targetH];

% 計算透視變換矩陣
tform = fitgeotrans(srcPoints, dstPoints, 'projective');

% 透視校正
colorcheckerRectified = imwarp(img, tform, 'OutputView', imref2d([targetH targetW]));

imshow(colorcheckerRectified);
title('透視校正後的 ColorChecker');


%% (3)讀取24色塊之RGB值([0 1]浮點數格式):
% 分割成 6x4 色塊
rows = 4;
cols = 6;
blockH = floor(targetH / rows);
blockW = floor(targetW / cols);

RGB_values = zeros(rows*cols, 3);
index = 1;

for r = 1:rows
    for c = 1:cols
        xStart = (c-1)*blockW + 1;
        yStart = (r-1)*blockH + 1;
        block = colorcheckerRectified(yStart:yStart+blockH-1, xStart:xStart+blockW-1, :);
        
        meanRGB = squeeze(mean(mean(block,1),2));
        RGB_values(index,:) = meanRGB;
        
        fprintf('Patch %2d: R=%.2f, G=%.2f, B=%.2f\n', index, meanRGB(1), meanRGB(2), meanRGB(3));
        index = index + 1;
    end
end