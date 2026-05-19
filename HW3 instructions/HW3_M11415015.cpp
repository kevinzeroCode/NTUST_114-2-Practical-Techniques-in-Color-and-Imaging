#include <opencv2/opencv.hpp>

#include <algorithm>
#include <array>
#include <iostream>
#include <string>
#include <vector>

using namespace cv;
using namespace std;

/*
    HW3 - OpenCV Interactive Image Processing Demo

    Features:
    1. Perspective transformation with draggable image corners
    2. Brightness and saturation adjustment using HSV color space
    3. Binary image display using Otsu thresholding
    4. Colored Canny edge display
    5. Save processed image
    6. Reset image settings
    7. Display student ID on the output image

    Keyboard Controls:
    - 1 : Binary mode
    - 2 : Canny color mode
    - 3 : Normal BGR mode
    - R : Reset all settings
    - S : Save current result as output.jpg
    - Q / ESC : Exit program
*/

namespace {

// Constant settings used throughout the program.
const string kWindowName = "HW3 demo";
const string kStudentId = "m11415015";
const string kBrightnessTrackbar = "Brightness";
const string kSaturationTrackbar = "Saturation";

const int kTrackbarMax = 200;
const int kDefaultTrackbarValue = 100;
const int kCornerHitRadius = 24;

// Different image display modes required by the homework.
enum class DisplayMode {
    Bgr,        // Original color image
    Binary,     // Binary image using Otsu thresholding
    CannyColor  // Colored Canny edge result
};

// Global variables are used because OpenCV GUI callbacks require
// C-style callback functions. The state is kept small and clear.
Mat originalImage;
array<Point2f, 4> sourceCorners;
array<Point2f, 4> targetCorners;

DisplayMode displayMode = DisplayMode::Bgr;

int brightnessValue = kDefaultTrackbarValue;
int saturationValue = kDefaultTrackbarValue;

int activeCorner = -1;
bool draggingCorner = false;
bool controlsReady = false;

// Limit a floating-point value between low and high.
float clampFloat(float value, float low, float high) {
    return max(low, min(value, high));
}

// Convert std::array<Point2f, 4> into vector<Point2f>
// because getPerspectiveTransform() expects vector-like input.
vector<Point2f> toVector(const array<Point2f, 4>& points) {
    return vector<Point2f>(points.begin(), points.end());
}

// Reset the four perspective control points to the original image corners.
void resetCorners() {
    const int lastCol = originalImage.cols - 1;
    const int lastRow = originalImage.rows - 1;

    sourceCorners = {
        Point2f(0.0f, 0.0f),
        Point2f(static_cast<float>(lastCol), 0.0f),
        Point2f(static_cast<float>(lastCol), static_cast<float>(lastRow)),
        Point2f(0.0f, static_cast<float>(lastRow))
    };

    // At the beginning, target corners are the same as source corners,
    // so the image is displayed without perspective distortion.
    targetCorners = sourceCorners;
}

// Apply perspective transformation based on user-controlled target corners.
Mat applyPerspectiveTransform() {
    // Compute the homography matrix from original corners to target corners.
    Mat transform = getPerspectiveTransform(
        toVector(sourceCorners),
        toVector(targetCorners)
    );

    Mat warped;

    // Warp the original image using the perspective transform matrix.
    // Areas outside the transformed quadrilateral are filled with black.
    warpPerspective(originalImage, warped, transform, originalImage.size());

    return warped;
}

// Adjust brightness and saturation in HSV color space.
Mat applyHsvControls(const Mat& image) {
    // Read current trackbar values.
    // If controls are not ready yet, use default values.
    const int currentBrightness = controlsReady
        ? getTrackbarPos(kBrightnessTrackbar, kWindowName)
        : brightnessValue;

    const int currentSaturation = controlsReady
        ? getTrackbarPos(kSaturationTrackbar, kWindowName)
        : saturationValue;

    Mat hsv;

    // Convert BGR image to HSV because brightness and saturation
    // can be adjusted more naturally in HSV color space.
    cvtColor(image, hsv, COLOR_BGR2HSV);

    vector<Mat> channels;
    split(hsv, channels);

    // HSV channels:
    // channels[0] = Hue
    // channels[1] = Saturation
    // channels[2] = Value / Brightness
    const double saturationScale = currentSaturation / 100.0;
    const double brightnessScale = currentBrightness / 100.0;

    // Adjust saturation and brightness by scaling S and V channels.
    channels[1].convertTo(channels[1], -1, saturationScale, 0.0);
    channels[2].convertTo(channels[2], -1, brightnessScale, 0.0);

    merge(channels, hsv);

    Mat adjusted;

    // Convert back to BGR so OpenCV can display the image normally.
    cvtColor(hsv, adjusted, COLOR_HSV2BGR);

    return adjusted;
}

// Apply the selected display mode to the image.
Mat applyDisplayMode(const Mat& image) {
    // Mode 3: display normal BGR image.
    if (displayMode == DisplayMode::Bgr) {
        return image.clone();
    }

    Mat gray;

    // Binary thresholding and Canny edge detection both require grayscale input.
    cvtColor(image, gray, COLOR_BGR2GRAY);

    // Mode 1: binary image using Otsu thresholding.
    if (displayMode == DisplayMode::Binary) {
        Mat binary;

        // Otsu automatically finds a suitable threshold value.
        threshold(gray, binary, 0, 255, THRESH_BINARY | THRESH_OTSU);

        Mat output;

        // Convert grayscale binary image back to BGR so text can be drawn in color.
        cvtColor(binary, output, COLOR_GRAY2BGR);

        return output;
    }

    // Mode 2: colored Canny edge result.
    Mat edges;

    // Detect edges using the Canny edge detector.
    Canny(gray, edges, 80, 160);

    Mat output = Mat::zeros(image.size(), image.type());

    // Copy original color pixels only where edges are detected.
    // This creates a colored edge visualization instead of plain white edges.
    image.copyTo(output, edges);

    return output;
}

// Draw student ID on the image.
void drawStudentId(Mat& image) {
    // Draw the ID after all processing so it remains visible
    // in BGR, binary, and Canny modes.
    putText(
        image,
        kStudentId,
        Point(12, 34),
        FONT_HERSHEY_SIMPLEX,
        0.9,
        Scalar(0, 255, 255),
        2,
        LINE_AA
    );
}

// Main rendering pipeline.
Mat renderCurrentImage() {
    // Processing order:
    // 1. Apply perspective transformation
    // 2. Apply HSV brightness/saturation controls
    // 3. Apply selected display mode
    // 4. Draw student ID
    Mat warped = applyPerspectiveTransform();
    Mat adjusted = applyHsvControls(warped);
    Mat output = applyDisplayMode(adjusted);

    drawStudentId(output);

    return output;
}

// Redraw the current image in the OpenCV window.
void showCurrentImage(int = 0, void* = nullptr) {
    if (originalImage.empty() || !controlsReady) {
        return;
    }

    imshow(kWindowName, renderCurrentImage());
}

// Find the nearest draggable corner to the mouse cursor.
int findNearestCorner(Point cursor) {
    int nearest = -1;
    double nearestDistance = kCornerHitRadius;

    for (int i = 0; i < static_cast<int>(targetCorners.size()); ++i) {
        const double distance = norm(
            Point2f(static_cast<float>(cursor.x), static_cast<float>(cursor.y))
            - targetCorners[i]
        );

        // Only select a corner if the cursor is close enough.
        if (distance <= nearestDistance) {
            nearestDistance = distance;
            nearest = i;
        }
    }

    return nearest;
}

// Mouse callback for dragging perspective corners.
void onMouse(int event, int x, int y, int, void*) {
    if (originalImage.empty()) {
        return;
    }

    if (event == EVENT_LBUTTONDOWN) {
        // Start dragging only when the user clicks near a corner.
        activeCorner = findNearestCorner(Point(x, y));
        draggingCorner = activeCorner >= 0;
        return;
    }

    if (event == EVENT_MOUSEMOVE && draggingCorner && activeCorner >= 0) {
        // Update only the selected corner.
        // The point is clamped inside the image boundary to avoid invalid positions.
        targetCorners[activeCorner] = Point2f(
            clampFloat(static_cast<float>(x), 0.0f, static_cast<float>(originalImage.cols - 1)),
            clampFloat(static_cast<float>(y), 0.0f, static_cast<float>(originalImage.rows - 1))
        );

        showCurrentImage();
        return;
    }

    if (event == EVENT_LBUTTONUP) {
        // Stop dragging when the mouse button is released.
        draggingCorner = false;
        activeCorner = -1;
    }
}

// Handle keyboard input.
void handleKey(int key) {
    switch (key) {
    case 'r':
    case 'R':
        // Reset perspective points, trackbars, and display mode.
        resetCorners();

        setTrackbarPos(kBrightnessTrackbar, kWindowName, kDefaultTrackbarValue);
        setTrackbarPos(kSaturationTrackbar, kWindowName, kDefaultTrackbarValue);

        displayMode = DisplayMode::Bgr;
        showCurrentImage();
        break;

    case 's':
    case 'S':
        // Save the current processed result.
        if (imwrite("output.jpg", renderCurrentImage())) {
            cout << "Saved output.jpg" << endl;
        } else {
            cerr << "Failed to save output.jpg" << endl;
        }
        break;

    case '1':
        // Switch to binary display mode.
        displayMode = DisplayMode::Binary;
        showCurrentImage();
        break;

    case '2':
        // Switch to colored Canny edge display mode.
        displayMode = DisplayMode::CannyColor;
        showCurrentImage();
        break;

    case '3':
        // Switch back to normal BGR display mode.
        displayMode = DisplayMode::Bgr;
        showCurrentImage();
        break;

    default:
        break;
    }
}

} // namespace

int main() {
    // Load the input image.
    originalImage = imread("ntust.jpg");

    if (originalImage.empty()) {
        cerr << "Failed to open ntust.jpg. Please run this program from the folder containing ntust.jpg." << endl;
        return 1;
    }

    // Initialize perspective corner positions.
    resetCorners();

    // Create the main display window.
    namedWindow(kWindowName, WINDOW_AUTOSIZE);

    // Create trackbars for brightness and saturation adjustment.
    // Brightness is created first so it appears above Saturation.
    createTrackbar(kBrightnessTrackbar, kWindowName, nullptr, kTrackbarMax, showCurrentImage);
    createTrackbar(kSaturationTrackbar, kWindowName, nullptr, kTrackbarMax, showCurrentImage);

    // Set initial trackbar values to 100%.
    setTrackbarPos(kBrightnessTrackbar, kWindowName, brightnessValue);
    setTrackbarPos(kSaturationTrackbar, kWindowName, saturationValue);

    // Mark GUI controls as ready after trackbars are initialized.
    controlsReady = true;

    // Register mouse callback for perspective corner dragging.
    setMouseCallback(kWindowName, onMouse);

    // Show the initial image.
    showCurrentImage();

    // Main event loop.
    while (true) {
        const int key = waitKey(30);

        // Press Q, q, or ESC to exit.
        if (key == 'q' || key == 'Q' || key == 27) {
            break;
        }

        // Handle other keyboard commands.
        if (key >= 0) {
            handleKey(key);
        }
    }

    // Close all OpenCV windows before program exits.
    destroyAllWindows();

    return 0;
}