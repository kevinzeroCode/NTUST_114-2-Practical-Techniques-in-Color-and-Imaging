% =========================================================================
% 114 色彩及影像實作技術 - 作業一
% App Designer 完整 Callback 程式碼
%
% 使用方式：
%   1. 開啟 MATLAB App Designer，依照 UI_SETUP_GUIDE.md 建立所有元件
%   2. 在 Code View > Properties 區塊加入 Properties 程式碼
%   3. 將各 callback 函式的「內容」貼入 App Designer 對應 callback 中
%
% 注意：以下函式寫法是「可直接複製貼入 App Designer Code View」的格式
% =========================================================================


%% ========================================================================
%  【STEP A】Properties 宣告
%  位置：Code View > Properties (Access = private) 區塊
% =========================================================================
%{
properties (Access = private)
    ccimg    % ColorChecker 影像（im2double 後的 double 格式）
    ccMat    % 3×3 色彩校正矩陣
end
%}


%% ========================================================================
%  【STEP B】startupFcn 初始化
%  位置：Component Browser 頂層右鍵 > Add > startupFcn
% =========================================================================
function startupFcn(app)
    % ------ 隱藏初始不需要的元件 ------
    app.AreaSelectionButton.Visible  = 'off';  % 自動對焦按鈕（勾選 CheckBox 才顯示）
    app.Image.Visible                = 'off';  % ROI 預覽圖框（選區後才顯示）
    app.OptionDropDown.Visible       = 'off';  % 色彩選單（完成色彩校正後才顯示）
    app.Image2.Visible               = 'off';  % 色彩校正結果圖框

    % ------ 設定 OptionDropDown 選項 ------
    app.OptionDropDown.ItemsData = num2cell(1:3);  % ItemsData = {1, 2, 3}
    app.OptionDropDown.Items     = {'RAW, G=1', 'Color Correction, G=1', 'Color Correction G=0.5'};
    app.OptionDropDown.Value     = 3;              % 預設選第 3 項

    % ------ 關閉 UIAxes 工具列，清除軸標籤 ------
    app.UIAxes.Toolbar.Visible  = 'off';
    app.UIAxes2.Toolbar.Visible = 'off';
    app.UIAxes.XLabel.String    = ' ';
    app.UIAxes.YLabel.String    = ' ';
    app.UIAxes2.XLabel.String   = ' ';
    app.UIAxes2.YLabel.String   = ' ';

    % ------ 設定 Gauge 與 Slider 的數值範圍 ------
    app.Gauge.Limits       = [1 11];  % e1~e11 共 11 張
    app.DepthSlider.Limits = [1 11];
    app.DepthSlider.Value  = 1;       % 從最近焦距開始

    % ------ 讀取 ColorChecker 影像並轉浮點 ------
    rawImg = imread('cc1.jpg');
    app.ccimg = double(rawImg) / 255;  % 手動轉浮點，取代 im2double

    % ------ 初始化 ccMat 為單位矩陣（色彩未校正時用 eye(3)）------
    app.ccMat = eye(3);

    % ------ 呼叫 Slider 回呼，顯示初始影像 ------
    % 注意：呼叫時傳入空 struct 作為 event 替代
    DepthSliderValueChanged(app, struct());
end


%% ========================================================================
%  【STEP C】DepthSliderValueChanged：手動對焦滑桿
%  位置：app.DepthSlider > 右鍵 > Callbacks > ValueChangedFcn
% =========================================================================
function DepthSliderValueChanged(app, event)
    % 將滑桿浮點值四捨五入，取得整數影像編號 (1~11)
    idx = round(app.DepthSlider.Value);
    idx = max(1, min(11, idx));  % 防呆：確保在 [1, 11] 範圍內

    % 讀取對應影像並顯示於 UIAxes
    img = imread(sprintf('e%d.jpg', idx));
    imshow(img, 'Parent', app.UIAxes);

    % 更新 Gauge 指針
    app.Gauge.Value = idx;
end


%% ========================================================================
%  【STEP D】AutoFocusCheckBoxValueChanged：切換對焦模式
%  位置：app.AutoFocusCheckBox > 右鍵 > Callbacks > ValueChangedFcn
% =========================================================================
function AutoFocusCheckBoxValueChanged(app, event)
    if app.AutoFocusCheckBox.Value
        % === 勾選 → 自動對焦模式 ===
        app.AreaSelectionButton.Visible = 'on';   % 顯示選區按鈕
        app.DepthSlider.Visible         = 'off';  % 隱藏手動滑桿
    else
        % === 取消勾選 → 手動對焦模式 ===
        app.AreaSelectionButton.Visible = 'off';  % 隱藏選區按鈕
        app.Image.Visible               = 'off';  % 隱藏 ROI 圖框
        app.DepthSlider.Visible         = 'on';   % 顯示手動滑桿
    end
end


%% ========================================================================
%  【STEP E】AreaSelectionButtonPushed：自動對焦（找最清晰影像）
%  位置：app.AreaSelectionButton > 右鍵 > Callbacks > ButtonPushedFcn
% =========================================================================
function AreaSelectionButtonPushed(app, event)
    % ------ 讀取全部 11 張對焦影像（cell 格式儲存）------
    imgs = cell(1, 11);
    for i = 1:11
        rawImg = imread(sprintf('e%d.jpg', i));
        imgs{i} = double(rawImg) / 255;
    end

    % ------ 開暫時視窗，顯示第 1 張影像 ------
    fig_temp = figure('Name', '自動對焦 - 選取區域', 'NumberTitle', 'off');
    ax_temp  = axes(fig_temp);
    [imgH, imgW, ~] = size(imgs{1});
    image(ax_temp, uint8(imgs{1} * 255));  % 用 image() 顯示
    axis(ax_temp, 'image');
    set(ax_temp, 'XTick', [], 'YTick', []);
    title(ax_temp, '請用滑鼠拖曳框選對焦區域');

    % ------ 用 rbbox 實現拖曳框選（base MATLAB 橡皮筋矩形）------
    % 防呆：若使用者中途關閉視窗，try-catch 避免程式崩潰
    try
        waitforbuttonpress;                     % 等待滑鼠按下
        point1 = get(ax_temp, 'CurrentPoint');  % 按下時的座標
        rbbox;                                  % 橡皮筋拖曳，放開時返回
        point2 = get(ax_temp, 'CurrentPoint');  % 放開時的座標
    catch
        if ishandle(fig_temp), close(fig_temp); end
        return;
    end
    close(fig_temp);

    % ------ 計算 ROI 範圍 ------
    x1 = round(min(point1(1,1), point2(1,1)));
    y1 = round(min(point1(1,2), point2(1,2)));
    x2 = round(max(point1(1,1), point2(1,1)));
    y2 = round(max(point1(1,2), point2(1,2)));

    % ------ 防呆：clip 到影像範圍內 ------
    x1 = max(1, min(imgW, x1));
    y1 = max(1, min(imgH, y1));
    x2 = max(1, min(imgW, x2));
    y2 = max(1, min(imgH, y2));

    % ------ 防呆：確保選取區域有效（寬高 > 0）------
    if x2 <= x1 || y2 <= y1
        return;
    end

    % ------ 計算每張影像 ROI 的邊緣清晰度（Sobel 濾波器）------
    sobelX = [-1 0 1; -2 0 2; -1 0 1] / 8;
    sobelY = sobelX';
    edgeRatios = zeros(1, 11);
    for i = 1:11
        crop    = imgs{i}(y1:y2, x1:x2, :);
        grayROI = rgb2gray(crop);
        gx      = conv2(grayROI, sobelX, 'same');
        gy      = conv2(grayROI, sobelY, 'same');
        edgeMag = sqrt(gx.^2 + gy.^2);
        edgeRatios(i) = mean(edgeMag(:));
    end

    % ------ 選出清晰度最高的影像編號 ------
    [~, bestIdx] = max(edgeRatios);

    % ------ 顯示最佳對焦影像（全幅）於 UIAxes ------
    imshow(imgs{bestIdx}, 'Parent', app.UIAxes);
    title(app.UIAxes, sprintf('最佳對焦：e%d.jpg', bestIdx));

    % ------ 顯示最佳影像的 ROI 區域於 Image 圖框 ------
    roiImg = imgs{bestIdx}(y1:y2, x1:x2, :);
    app.Image.ImageSource = roiImg;
    app.Image.Visible     = 'on';

    % ------ 更新 Gauge 指針連動 ------
    app.Gauge.Value = bestIdx;
end


%% ========================================================================
%  【STEP F】AreaSelectionButton_2Pushed：色彩校正（透視校正＋計算 ccMat）
%  位置：app.AreaSelectionButton_2 > 右鍵 > Callbacks > ButtonPushedFcn
% =========================================================================
function AreaSelectionButton_2Pushed(app, event)
    % ------ 開暫時視窗，顯示 RAW 影像 ------
    fig_temp = figure('Name', '色彩校正 - 選取 ColorChecker', 'NumberTitle', 'off');
    ax_temp  = axes(fig_temp);
    image(ax_temp, uint8(app.ccimg * 255));
    axis(ax_temp, 'image');
    set(ax_temp, 'XTick', [], 'YTick', []);
    title(ax_temp, '請依序點選 ColorChecker 四角（左上→右上→右下→左下）');

    % ------ 逐點點擊 + 即時標記（顯示涵蓋範圍）------
    % 防呆：若使用者中途關閉視窗，try-catch 避免程式崩潰
    srcPoints = zeros(4, 2);
    cornerNames = {'左上', '右上', '右下', '左下'};
    hold(ax_temp, 'on');
    try
        for k = 1:4
            title(ax_temp, sprintf('請點選第 %d 點（%s）', k, cornerNames{k}));
            [px, py] = ginput(1);
            % 防呆：ginput 回傳空值（視窗被關閉）則中止
            if isempty(px) || isempty(py)
                if ishandle(fig_temp), close(fig_temp); end
                return;
            end
            srcPoints(k, :) = [px, py];
            plot(ax_temp, px, py, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
            text(ax_temp, px+5, py-5, num2str(k), 'Color', 'r', 'FontSize', 14, 'FontWeight', 'bold');
            if k > 1
                plot(ax_temp, srcPoints(k-1:k, 1), srcPoints(k-1:k, 2), 'r-', 'LineWidth', 2);
            end
            if k == 4
                plot(ax_temp, srcPoints([4 1], 1), srcPoints([4 1], 2), 'r-', 'LineWidth', 2);
            end
        end
    catch
        if ishandle(fig_temp), close(fig_temp); end
        return;
    end
    hold(ax_temp, 'off');
    pause(0.5);
    close(fig_temp);

    % ------ 定義目標矩形大小 400×600 像素 ------
    targetW = 600;
    targetH = 400;
    dstPoints = [1 1; targetW 1; targetW targetH; 1 targetH];

    % ------ DLT 計算 Homography 矩陣（取代 fitgeotrans）------
    nPts = size(srcPoints, 1);
    A = zeros(2*nPts, 9);
    for k = 1:nPts
        xs = srcPoints(k,1); ys = srcPoints(k,2);
        xd = dstPoints(k,1); yd = dstPoints(k,2);
        A(2*k-1,:) = [xs ys 1  0  0  0  -xd*xs -xd*ys -xd];
        A(2*k,  :) = [ 0  0 0  xs ys 1  -yd*xs -yd*ys -yd];
    end
    [~, ~, V] = svd(A);
    H = reshape(V(:,end), 3, 3)';

    % ------ 防呆：確保 Homography 矩陣條件數合理（四點不共線）------
    if cond(H) > 1e8
        title(app.UIAxes2, '⚠ 四角點接近共線或重合，請重新選取');
        return;
    end

    % ------ 反向映射 + interp2（取代 imwarp + imref2d）------
    Hinv = H \ eye(3);
    [dxGrid, dyGrid] = meshgrid(1:targetW, 1:targetH);
    dstCoords = [dxGrid(:)'; dyGrid(:)'; ones(1, targetW*targetH)];
    srcCoords = Hinv * dstCoords;
    sx = reshape(srcCoords(1,:) ./ srcCoords(3,:), targetH, targetW);
    sy = reshape(srcCoords(2,:) ./ srcCoords(3,:), targetH, targetW);
    ccRectified = zeros(targetH, targetW, 3);
    for ch = 1:3
        ccRectified(:,:,ch) = interp2(app.ccimg(:,:,ch), sx, sy, 'linear', 0);
    end

    % ------ 在同一圖框顯示透視校正後的 ColorChecker ------
    imshow(ccRectified, 'Parent', app.UIAxes2);
    title(app.UIAxes2, '透視校正後的 ColorChecker');

    % ------ 讀取 24 色塊 RGB 值（4 行 × 6 列）------
    rows = 4; cols = 6;
    blockH = floor(targetH / rows);   % 每色塊高
    blockW = floor(targetW / cols);   % 每色塊寬
    RGB_values = zeros(rows * cols, 3);
    pIdx = 1;

    for r = 1:rows
        for c = 1:cols
            xS = (c-1) * blockW + 1;
            yS = (r-1) * blockH + 1;
            block = ccRectified(yS:yS+blockH-1, xS:xS+blockW-1, :);
            RGB_values(pIdx, :) = squeeze(mean(mean(block, 1), 2));  % 取色塊平均
            pIdx = pIdx + 1;
        end
    end

    % ------ 載入目標 RGB 值（RGB_target.mat）------
    data       = load('RGB_target.mat');
    fn         = fieldnames(data);
    RGB_target = data.(fn{1});   % 自動取第一個變數（24×3，浮點格式，範圍 [0,1]）

    % ------ 防呆：確保分母矩陣不奇異 ------
    if rank(RGB_values) < 3
        title(app.UIAxes2, '⚠ RGB_values 奇異，無法計算 ccMat');
        return;
    end

    % ------ 以最小平方法解 ccMat（3×3）------
    % 公式：RGB_values * ccMat ≈ RGB_target
    % 左除解法：ccMat = RGB_values \ RGB_target
    % 意義：套用時 out2d = ccimg2d * ccMat，將 measured 色彩校正至 target
    app.ccMat = RGB_values \ RGB_target;

    % ------ 顯示 OptionDropDown 與 Image2 ------
    app.OptionDropDown.Visible = 'on';
    app.Image2.Visible         = 'on';

    % ------ 執行 OptionDropDown 回呼（注意：拿掉 event）------
    OptionDropDownValueChanged(app);
end


%% ========================================================================
%  【STEP G】OptionDropDownValueChanged：顯示三種色彩處理結果
%  位置：app.OptionDropDown > 右鍵 > Callbacks > ValueChangedFcn
%  注意：此函式「不加 event 參數」，以便從 Step F 直接呼叫
% =========================================================================
function OptionDropDownValueChanged(app)
    val = app.OptionDropDown.Value;  % 取得目前選項值（1, 2, 或 3）

    % ------ 根據選單值，決定矩陣與 Gamma 值 ------
    switch val
        case 1  % RAW, G=1：不校正，直接顯示原始影像
            M           = eye(3);
            gamma_value = 1;
        case 2  % Color Correction, G=1：套用 ccMat，gamma=1
            M           = app.ccMat;
            gamma_value = 1;
        case 3  % Color Correction, G=0.5：套用 ccMat，gamma=0.5
            M           = app.ccMat;
            gamma_value = 0.5;
        otherwise
            return;
    end

    % ------ 將 RGB 影像降至 2 維（H×W×3 → (H*W)×3）------
    [imgH, imgW, ~] = size(app.ccimg);
    ccimg2d = reshape(app.ccimg, [], 3);   % (H*W) × 3

    % ------ 套用 3×3 色彩校正矩陣 ------
    out2d = ccimg2d * M;                   % (H*W) × 3

    % ------ 升維回 3 維 RGB 影像 ------
    out = reshape(out2d, imgH, imgW, 3);

    % ------ clip：將數值限制在 [0, 1] 範圍 ------
    out = max(0, min(1, out));

    % ------ 套用 Gamma 校正（out = out .^ gamma_value）------
    out = out .^ gamma_value;

    % ------ 在 Image2 圖框中顯示浮點格式影像 ------
    app.Image2.ImageSource = out;
end
