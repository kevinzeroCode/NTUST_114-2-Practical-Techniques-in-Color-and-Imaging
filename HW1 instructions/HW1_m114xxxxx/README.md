# 作業一：以 MATLAB APP 呈現自動對焦與色彩校正效果

**課程**：114 台科大 色彩及影像實作技術
**學號**：M11415015
**繳交期限**：2026/04/14 (週二) 24:00

---

## 檔案說明

| 檔案 | 說明 |
|------|------|
| `HW1_m11415015.mlapp` | MATLAB App Designer 主程式（繳交檔案） |
| `HW1_complete.m` | 完整 classdef 參考碼（含 UI 建立與所有 callback） |
| `HW1_callbacks.m` | 各 callback 函式獨立參考碼（方便貼入 App Designer） |
| `UI_SETUP_GUIDE.md` | App Designer UI 元件建立步驟說明 |

> 影像檔（e1–e11.jpg、cc1.jpg、cc2.jpg）與 RGB_target.mat 不含在繳交壓縮檔中。

---

## 執行環境

- MATLAB（不需要 Image Processing Toolbox）
- 執行前請確認工作目錄（Current Folder）包含以下檔案：
  - `e1.jpg` ~ `e11.jpg`（11 張不同焦距影像）
  - `cc1.jpg` 或 `cc2.jpg`（ColorChecker 影像）
  - `RGB_target.mat`（24 色塊標準 RGB 值，範圍 [0, 1]）

---

## 功能說明

### Tab 1 — Focus（自動對焦）

**手動對焦模式**（預設）
- 拖動 `DepthSlider` 滑桿，Gauge 指針連動，UIAxes 顯示對應焦距影像（e1–e11）

**自動對焦模式**（勾選 Auto Focus）
1. 點擊 `Area Selection` 按鈕
2. 在彈出視窗中用滑鼠拖曳框選感興趣區域（ROI）
3. 程式自動計算 11 張影像在該 ROI 的 Sobel 邊緣清晰度
4. 最清晰影像顯示於 UIAxes，ROI 裁切圖顯示於 Image 圖框，Gauge 同步更新

### Tab 2 — Color（色彩校正）

1. 點擊 `Area Selection` 按鈕
2. 在彈出視窗中**依序**點選 ColorChecker 四個角落（左上 → 右上 → 右下 → 左下）
3. 程式進行透視校正，將 ColorChecker 拉正為 400×600 像素並顯示於 UIAxes2
4. 讀取 24 色塊 RGB 均值，與 `RGB_target.mat` 做最小平方法，計算 3×3 色彩校正矩陣 `ccMat`
5. 透過 `Option` 下拉選單切換三種顯示模式：

| 選項 | 矩陣 | Gamma |
|------|------|-------|
| RAW, G=1 | 單位矩陣 | 1 |
| Color Correction, G=1 | ccMat | 1 |
| Color Correction G=0.5 | ccMat | 0.5 |

---

## 主要技術實作（取代 Image Processing Toolbox）

| IPT 函式 | 替代方案 |
|----------|----------|
| `im2double` | `double(img) / 255` |
| `edge()` | Sobel 濾波器 + `conv2` |
| `fitgeotrans` | DLT（Direct Linear Transform）+ SVD |
| `imwarp` + `imref2d` | 反向映射 + `interp2` |
| `drawpolygon` | `ginput(1)` 逐點迴圈 + 即時 `plot` 標記 |
| `drawrectangle` | `waitforbuttonpress` + `rbbox` |
| `mean2` | `mean(x(:))` |

---

## 防呆設計

- ROI 座標自動 clip 至影像範圍，並確保寬高 > 0
- `rank(RGB_values) < 3` 檢查：避免色塊矩陣奇異導致 `\` 運算失敗
- `cond(H) > 1e8` 檢查：避免四角點共線或重合導致 Homography 矩陣奇異
- `ginput` / `rbbox` 視窗提前關閉：`try-catch` + `ishandle` 安全退出
- `isempty(px)` 檢查：`ginput` 回傳空值時安全中止
