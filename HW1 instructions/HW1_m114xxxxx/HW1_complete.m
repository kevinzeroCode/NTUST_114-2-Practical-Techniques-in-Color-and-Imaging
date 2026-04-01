classdef HW1_m11415015 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TabGroup               matlab.ui.container.TabGroup
        FocusTab               matlab.ui.container.Tab
        AreaSelectionButton    matlab.ui.control.Button
        DepthSlider            matlab.ui.control.Slider
        SliderLabel            matlab.ui.control.Label
        Gauge                  matlab.ui.control.LinearGauge
        GaugeLabel             matlab.ui.control.Label
        AutoFocusCheckBox      matlab.ui.control.CheckBox
        M11415015Label         matlab.ui.control.Label
        Image                  matlab.ui.control.Image
        UIAxes                 matlab.ui.control.UIAxes
        ColorTab               matlab.ui.container.Tab
        OptionDropDown         matlab.ui.control.DropDown
        DropDownLabel          matlab.ui.control.Label
        AreaSelectionButton_2  matlab.ui.control.Button
        Image2                 matlab.ui.control.Image
        UIAxes2                matlab.ui.control.UIAxes
    end

    properties (Access = private)
        ccimg    % ColorChecker 影像（double 格式）
        ccMat    % 3×3 色彩校正矩陣
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % --- 隱藏初始不需要的元件 ---
            app.AreaSelectionButton.Visible  = 'off';  % 自動對焦按鈕（勾選才顯示）
            app.Image.Visible                = 'off';  % ROI 預覽（選區後才顯示）
            app.OptionDropDown.Visible       = 'off';  % 色彩選單（色彩校正後才顯示）
            app.Image2.Visible               = 'off';  % 色彩校正結果圖框

            % --- 設定 OptionDropDown 選項 ---
            app.OptionDropDown.ItemsData = num2cell(1:3);
            app.OptionDropDown.Items     = {'RAW, G=1', 'Color Correction, G=1', 'Color Correction G=0.5'};
            app.OptionDropDown.Value     = 3;

            % --- 關閉 UIAxes 工具列，清除軸標籤 ---
            app.UIAxes.Toolbar.Visible  = 'off';
            app.UIAxes2.Toolbar.Visible = 'off';
            app.UIAxes.XLabel.String    = ' ';
            app.UIAxes.YLabel.String    = ' ';
            app.UIAxes2.XLabel.String   = ' ';
            app.UIAxes2.YLabel.String   = ' ';

            % --- 設定 Gauge 與 Slider 的數值範圍 ---
            app.Gauge.Limits       = [1 11];
            app.DepthSlider.Limits = [1 11];
            app.DepthSlider.Value  = 1;

            % --- 讀取 ColorChecker 影像並轉浮點 ---
            rawImg = imread('cc1.jpg');
            app.ccimg = double(rawImg) / 255;  % 手動轉浮點，取代 im2double

            % --- 初始化 ccMat 為單位矩陣 ---
            app.ccMat = eye(3);

            % --- 呼叫 Slider 回呼，顯示初始影像 ---
            DepthSliderValueChanged(app, struct());
        end

        % Value changed function: DepthSlider
        function DepthSliderValueChanged(app, event)
            % 四捨五入取得整數影像編號 (1~11)
            idx = round(app.DepthSlider.Value);
            idx = max(1, min(11, idx));  % 防呆：確保在 [1,11] 範圍

            % 讀取並顯示對應影像
            img = imread(sprintf('e%d.jpg', idx));
            imshow(img, 'Parent', app.UIAxes);

            % 更新 Gauge 指針
            app.Gauge.Value = idx;
        end

        % Value changed function: AutoFocusCheckBox
        function AutoFocusCheckBoxValueChanged(app, event)
            if app.AutoFocusCheckBox.Value
                % 勾選 → 自動對焦模式
                app.AreaSelectionButton.Visible = 'on';
                app.DepthSlider.Visible         = 'off';
            else
                % 取消勾選 → 手動對焦模式
                app.AreaSelectionButton.Visible = 'off';
                app.Image.Visible               = 'off';
                app.DepthSlider.Visible         = 'on';
            end
        end

        % Button pushed function: AreaSelectionButton
        function AreaSelectionButtonPushed(app, event)
            % --- 讀取 11 張影像（cell 格式）---
            imgs = cell(1, 11);
            for i = 1:11
                rawImg = imread(sprintf('e%d.jpg', i));
                imgs{i} = double(rawImg) / 255;
            end

            % --- 開暫時視窗，顯示第 1 張影像 ---
            fig_temp = figure('Name', '自動對焦 - 選取區域', 'NumberTitle', 'off');
            ax_temp  = axes(fig_temp);
            [imgH, imgW, ~] = size(imgs{1});
            image(ax_temp, uint8(imgs{1} * 255));  % 用 image() 顯示（base MATLAB）
            axis(ax_temp, 'image');                 % 等比例
            set(ax_temp, 'XTick', [], 'YTick', []);
            title(ax_temp, '請用滑鼠拖曳框選對焦區域');

            % --- 用 rbbox 實現拖曳框選（base MATLAB 橡皮筋矩形）---
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

            % --- 計算 ROI 範圍 [y1:y2, x1:x2] ---
            x1 = round(min(point1(1,1), point2(1,1)));
            y1 = round(min(point1(1,2), point2(1,2)));
            x2 = round(max(point1(1,1), point2(1,1)));
            y2 = round(max(point1(1,2), point2(1,2)));

            % --- 防呆：clip 到影像範圍內 ---
            x1 = max(1, min(imgW, x1));
            y1 = max(1, min(imgH, y1));
            x2 = max(1, min(imgW, x2));
            y2 = max(1, min(imgH, y2));

            % --- 防呆：確保選取區域有效（寬高 > 0）---
            if x2 <= x1 || y2 <= y1
                return;
            end

            % --- 計算每張影像 ROI 的邊緣清晰度（Sobel 濾波器）---
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

            % --- 找最清晰影像 ---
            [~, bestIdx] = max(edgeRatios);

            % --- 顯示最佳對焦全幅影像於 UIAxes ---
            imshow(imgs{bestIdx}, 'Parent', app.UIAxes);
            title(app.UIAxes, sprintf('最佳對焦：e%d.jpg', bestIdx));

            % --- 顯示 ROI 區域於 Image 圖框 ---
            roiImg = imgs{bestIdx}(y1:y2, x1:x2, :);
            app.Image.ImageSource = roiImg;
            app.Image.Visible     = 'on';

            % --- 更新 Gauge 連動 ---
            app.Gauge.Value = bestIdx;
        end

        % Button pushed function: AreaSelectionButton_2
        function AreaSelectionButton_2Pushed(app, event)
            % --- 開暫時視窗，顯示 RAW 影像 ---
            fig_temp = figure('Name', '色彩校正 - 選取 ColorChecker', 'NumberTitle', 'off');
            ax_temp  = axes(fig_temp);
            image(ax_temp, uint8(app.ccimg * 255));
            axis(ax_temp, 'image');
            set(ax_temp, 'XTick', [], 'YTick', []);
            title(ax_temp, '請依序點選 ColorChecker 四角（左上→右上→右下→左下）');

            % --- 逐點點擊 + 即時標記（顯示涵蓋範圍）---
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

            % --- 透視校正（輸出 400×600）---
            % 使用手動 DLT 演算法 + interp2，取代 fitgeotrans/imwarp/imref2d
            targetW  = 600;
            targetH  = 400;
            dstPoints = [1 1; targetW 1; targetW targetH; 1 targetH];

            % --- DLT (Direct Linear Transform) 計算 Homography 矩陣 ---
            nPts = size(srcPoints, 1);
            A = zeros(2*nPts, 9);
            for k = 1:nPts
                xs = srcPoints(k,1); ys = srcPoints(k,2);
                xd = dstPoints(k,1); yd = dstPoints(k,2);
                A(2*k-1,:) = [xs ys 1  0  0  0  -xd*xs -xd*ys -xd];
                A(2*k,  :) = [ 0  0 0  xs ys 1  -yd*xs -yd*ys -yd];
            end
            [~, ~, V] = svd(A);
            H = reshape(V(:,end), 3, 3)';  % 3×3 Homography: dst = H * src

            % --- 防呆：確保 Homography 矩陣條件數合理（四點不共線）---
            if cond(H) > 1e8
                title(app.UIAxes2, '⚠ 四角點接近共線或重合，請重新選取');
                return;
            end

            % --- 反向映射 (inverse warp)：對每個目標像素找來源座標 ---
            Hinv = H \ eye(3);  % inv(H)
            [dxGrid, dyGrid] = meshgrid(1:targetW, 1:targetH);
            dstCoords = [dxGrid(:)'; dyGrid(:)'; ones(1, targetW*targetH)];
            srcCoords = Hinv * dstCoords;
            sx = reshape(srcCoords(1,:) ./ srcCoords(3,:), targetH, targetW);
            sy = reshape(srcCoords(2,:) ./ srcCoords(3,:), targetH, targetW);

            % --- 用 interp2 做雙線性內插 ---
            ccRect = zeros(targetH, targetW, 3);
            for ch = 1:3
                ccRect(:,:,ch) = interp2(app.ccimg(:,:,ch), sx, sy, 'linear', 0);
            end

            % --- 顯示透視校正後的 ColorChecker ---
            imshow(ccRect, 'Parent', app.UIAxes2);
            title(app.UIAxes2, '透視校正後的 ColorChecker');

            % --- 讀取 24 色塊 RGB 值（4 行 × 6 列）---
            rows = 4; cols = 6;
            blockH = floor(targetH / rows);
            blockW = floor(targetW / cols);
            RGB_values = zeros(rows * cols, 3);
            pIdx = 1;
            for r = 1:rows
                for c = 1:cols
                    xS = (c-1) * blockW + 1;
                    yS = (r-1) * blockH + 1;
                    block = ccRect(yS:yS+blockH-1, xS:xS+blockW-1, :);
                    RGB_values(pIdx, :) = squeeze(mean(mean(block, 1), 2));
                    pIdx = pIdx + 1;
                end
            end

            % --- 載入目標 RGB 值 ---
            data       = load('RGB_target.mat');
            fn         = fieldnames(data);
            RGB_target = data.(fn{1});  % 24×3 浮點格式

            % --- 防呆：確保矩陣不奇異 ---
            if rank(RGB_values) < 3
                title(app.UIAxes2, 'RGB_values 奇異，無法計算 ccMat');
                return;
            end

            % --- 最小平方法計算 3×3 色彩校正矩陣 ---
            % RGB_values * ccMat ≈ RGB_target
            app.ccMat = RGB_values \ RGB_target;

            % --- 顯示選單與結果圖框 ---
            app.OptionDropDown.Visible = 'on';
            app.Image2.Visible         = 'on';

            % --- 執行 OptionDropDown 回呼（不傳 event）---
            OptionDropDownValueChanged(app, []);
        end

        % Value changed function: OptionDropDown
        function OptionDropDownValueChanged(app, event)
            val = app.OptionDropDown.Value;

            % --- 根據選單決定矩陣與 Gamma ---
            switch val
                case 1  % RAW, G=1
                    M           = eye(3);
                    gamma_value = 1;
                case 2  % Color Correction, G=1
                    M           = app.ccMat;
                    gamma_value = 1;
                case 3  % Color Correction, G=0.5
                    M           = app.ccMat;
                    gamma_value = 0.5;
                otherwise
                    return;
            end

            % --- 將 RGB 影像降至 2 維（H×W×3 → (H*W)×3）---
            [imgH, imgW, ~] = size(app.ccimg);
            ccimg2d = reshape(app.ccimg, [], 3);

            % --- 套用色彩校正矩陣 ---
            out2d = ccimg2d * M;

            % --- 升維回 3 維 ---
            out = reshape(out2d, imgH, imgW, 3);

            % --- Clip 到 [0,1] ---
            out = max(0, min(1, out));

            % --- Gamma 校正 ---
            out = out .^ gamma_value;

            % --- 顯示結果 ---
            app.Image2.ImageSource = out;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 640 480];

            % Create FocusTab
            app.FocusTab = uitab(app.TabGroup);
            app.FocusTab.Title = 'Focus';

            % Create UIAxes
            app.UIAxes = uiaxes(app.FocusTab);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [0 1 300 428];

            % Create Image
            app.Image = uiimage(app.FocusTab);
            app.Image.Position = [386 79 254 236];

            % Create M11415015Label
            app.M11415015Label = uilabel(app.FocusTab);
            app.M11415015Label.Position = [536 374 68 22];
            app.M11415015Label.Text = 'M11415015';

            % Create AutoFocusCheckBox
            app.AutoFocusCheckBox = uicheckbox(app.FocusTab);
            app.AutoFocusCheckBox.ValueChangedFcn = createCallbackFcn(app, @AutoFocusCheckBoxValueChanged, true);
            app.AutoFocusCheckBox.Text = 'Auto Focus';
            app.AutoFocusCheckBox.Position = [334 407 80 22];

            % Create GaugeLabel
            app.GaugeLabel = uilabel(app.FocusTab);
            app.GaugeLabel.HorizontalAlignment = 'center';
            app.GaugeLabel.Position = [354 47 41 22];
            app.GaugeLabel.Text = 'Gauge';

            % Create Gauge
            app.Gauge = uigauge(app.FocusTab, 'linear');
            app.Gauge.Orientation = 'vertical';
            app.Gauge.Position = [314 84 39 120];

            % Create SliderLabel
            app.SliderLabel = uilabel(app.FocusTab);
            app.SliderLabel.HorizontalAlignment = 'right';
            app.SliderLabel.Position = [308 47 36 22];
            app.SliderLabel.Text = 'Depth';

            % Create DepthSlider
            app.DepthSlider = uislider(app.FocusTab);
            app.DepthSlider.Orientation = 'vertical';
            app.DepthSlider.ValueChangedFcn = createCallbackFcn(app, @DepthSliderValueChanged, true);
            app.DepthSlider.Position = [366 56 3 150];

            % Create AreaSelectionButton
            app.AreaSelectionButton = uibutton(app.FocusTab, 'push');
            app.AreaSelectionButton.ButtonPushedFcn = createCallbackFcn(app, @AreaSelectionButtonPushed, true);
            app.AreaSelectionButton.Position = [334 373 100 23];
            app.AreaSelectionButton.Text = 'Area Selection';

            % Create ColorTab
            app.ColorTab = uitab(app.TabGroup);
            app.ColorTab.Title = 'Color';

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.ColorTab);
            title(app.UIAxes2, 'Title')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [9 166 300 185];

            % Create Image2
            app.Image2 = uiimage(app.ColorTab);
            app.Image2.Position = [413 152 176 199];

            % Create AreaSelectionButton_2
            app.AreaSelectionButton_2 = uibutton(app.ColorTab, 'push');
            app.AreaSelectionButton_2.ButtonPushedFcn = createCallbackFcn(app, @AreaSelectionButton_2Pushed, true);
            app.AreaSelectionButton_2.Position = [244 420 100 23];
            app.AreaSelectionButton_2.Text = 'Area Selection';

            % Create DropDownLabel（放在 Image2 上方）
            app.DropDownLabel = uilabel(app.ColorTab);
            app.DropDownLabel.HorizontalAlignment = 'right';
            app.DropDownLabel.Position = [383 358 50 22];
            app.DropDownLabel.Text = 'Option';

            % Create OptionDropDown（加寬到 200px 讓文字完整顯示）
            app.OptionDropDown = uidropdown(app.ColorTab);
            app.OptionDropDown.ValueChangedFcn = createCallbackFcn(app, @OptionDropDownValueChanged, true);
            app.OptionDropDown.Position = [438 358 200 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = HW1_m11415015

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
