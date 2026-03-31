# App Designer UI 元件設定指引

## 開始前
1. 開啟 MATLAB
2. 確認工作目錄設為 `HW1 instructions` 資料夾（含 e1.jpg ~ e11.jpg, cc1.jpg 等）
3. Home > New > App（開啟 App Designer）

---

## 一、建立 TabGroup 與兩個 Tab

1. 從 Component Library 拖入 **Tab Group** 到 canvas
2. 預設有兩個 Tab，雙擊改名：
   - Tab 1 → `Focus`
   - Tab 2 → `Color`

---

## 二、Focus Tab 元件清單

點選 **Focus** tab，加入以下元件：

| 元件類型 | 元件名稱（Name） | 重要屬性設定 |
|---------|---------------|-------------|
| UIAxes | `UIAxes` | 左邊大圖軸，顯示全幅影像 |
| Image | `Image` | 右邊小圖框，顯示 ROI 預覽 |
| Label | `M11412345Label` | 文字改成你的學號，例如 `M11412345` |
| CheckBox | `AutoFocusCheckBox` | Text = `Auto Focus` |
| Gauge | `Gauge` | 垂直 Gauge，Limits 先不用設（程式設定）|
| Slider | `DepthSlider` | 垂直 Slider，Label 改 `Depth` |
| Button | `AreaSelectionButton` | Text = `Area Selection` |

**階層注意事項（Component Browser）：**
- 所有上述元件都必須在 `app.FocusTab` 下（不能放在外面）
- 若拖放錯位置，在 Component Browser 中拖到正確父層

---

## 三、Color Tab 元件清單

點選 **Color** tab，加入以下元件：

| 元件類型 | 元件名稱（Name） | 重要屬性設定 |
|---------|---------------|-------------|
| UIAxes | `UIAxes2` | 左邊大圖軸，顯示 ColorChecker |
| Image | `Image2` | 右邊圖框，顯示色彩校正結果 |
| Button | `AreaSelectionButton_2` | Text = `Area Selection` |
| DropDown | `OptionDropDown` | Label = `Option`，Items 稍後程式設定 |

---

## 四、新增 startupFcn

1. 在 Component Browser 最頂層（`app.UIFigure`）右鍵
2. 選 **Callbacks > Add StartupFcn**
3. App Designer 會自動跳到 Code View 並建立 `startupFcn`

---

## 五、新增各元件的 Callback

每個元件右鍵 > Callbacks > Add ... Fcn：

| 元件 | Callback 名稱 |
|------|--------------|
| `DepthSlider` | `DepthSliderValueChanged` |
| `AutoFocusCheckBox` | `AutoFocusCheckBoxValueChanged` |
| `AreaSelectionButton` | `AreaSelectionButtonPushed` |
| `AreaSelectionButton_2` | `AreaSelectionButton_2Pushed` |
| `OptionDropDown` | `OptionDropDownValueChanged` |

---

## 六、貼入程式碼

1. 打開 `HW1_callbacks.m`（本資料夾內）
2. 依照 STEP A ~ G 的標記，複製對應內容貼入 App Designer Code View
3. **STEP A**：貼入 `properties (Access = private)` 區塊（先找到 properties 那一行）
4. **STEP B ~ G**：貼入各 callback 函式的「函式本體」（不含 function 宣告行本身）

---

## 七、OptionDropDownValueChanged 特別說明

此函式要「拿掉 event」：

App Designer 預設生成：
```matlab
function OptionDropDownValueChanged(app, event)
```

請改成：
```matlab
function OptionDropDownValueChanged(app)
```

---

## 八、繳交

1. 確認資料夾名稱為 `HW1_m114xxxxx`（改成你的學號）
2. 將 `.mlapp` 檔案放入該資料夾
3. **不用附影像檔**（e1.jpg 等不需打包）
4. 以 zip 壓縮整個資料夾上傳 Moodle
