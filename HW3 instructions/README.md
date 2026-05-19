# Interactive Image Processing with C++ and OpenCV

This project is a C++ / OpenCV homework implementation for interactive image processing. It demonstrates practical experience with OpenCV image I/O, color space conversion, GUI controls, mouse events, perspective transformation, thresholding, edge detection, and CMake-based builds on Windows.

## Technical Highlights

- Built an interactive desktop image-processing tool in C++ using OpenCV HighGUI.
- Used `imread()` and `imwrite()` for image loading and JPEG export.
- Converted BGR images to HSV and adjusted brightness and saturation through OpenCV trackbars.
- Implemented mouse-driven four-corner perspective transformation with `getPerspectiveTransform()` and `warpPerspective()`.
- Implemented multiple processing modes:
  - BGR display mode
  - Otsu binary thresholding with `threshold()`
  - Colored Canny edge visualization using `Canny()` and mask-based `copyTo()`
- Managed keyboard shortcuts for reset, save, mode switching, and application exit.
- Configured a reproducible CMake build linked against OpenCV.

## Features

- Displays `ntust.jpg` in an OpenCV window.
- Shows the student ID watermark `m11415015` on the image.
- Provides two trackbars:
  - `Brightness`: adjusts HSV value channel.
  - `Saturation`: adjusts HSV saturation channel.
- Allows dragging image corners to create a perspective effect.
- Supports keyboard controls:
  - `r`: reset perspective, mode, brightness, and saturation.
  - `s`: save the current result as `output.jpg`.
  - `1`: show Otsu binary threshold result.
  - `2`: show colored Canny edge result.
  - `3`: return to BGR mode.
  - `q` or `Esc`: exit.

## Build and Run

This project was built on Windows with:

- C++17
- CMake
- Visual Studio 2022 Build Tools
- OpenCV 4 installed through vcpkg

Configure:

```cmd
"C:\Program Files\CMake\bin\cmake.exe" -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE=C:\vcpkg\scripts\buildsystems\vcpkg.cmake
```

Build:

```cmd
"C:\Program Files\CMake\bin\cmake.exe" --build build --config Release
```

Run from the project folder:

```cmd
build\Release\HW3_M11415015.exe
```

## Interview Talking Points

- I implemented an image-processing application in C++ using OpenCV instead of only using Python bindings.
- I worked with OpenCV GUI components such as windows, trackbars, keyboard input, and mouse callbacks.
- I applied common computer vision operations including HSV adjustment, perspective transform, Otsu thresholding, and Canny edge detection.
- I handled stateful interactive behavior, including reset logic, mode switching, and saving processed output.
- I used CMake to configure and build a native C++ project with external OpenCV dependencies on Windows.

## Main Files

- `HW3_M11415015.cpp`: main C++ OpenCV implementation.
- `CMakeLists.txt`: CMake build configuration.
- `ntust.jpg`: input image used by the program.
