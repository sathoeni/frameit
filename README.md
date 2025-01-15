# frameit

A Swift command-line tool for adding device bezels to screenshots and creating beautiful App Store screenshots with custom labels.

## Features

- Automatically detects device type based on screenshot resolution
- Supports multiple device types (iPhone, iPad)
- Customizable device bezels and colors
- Optional text labels for App Store screenshots
- Supports multiple languages
- Automatic device frame positioning and content scaling

## Installation

1. Clone the repository
2. Build the project using Swift Package Manager:
```bash
swift build -c release
```
3. The binary will be available in `.build/release/frameit`

## Basic Usage

To add device bezels to your screenshots:

```bash
frameit -i ~/screenshots-source/ -o ~/output/
```

To create App Store screenshots with labels:

```bash
frameit -i ~/screenshots-source/ -o ~/output/ -c config.json
```

### Parameters

- `-i, --screenshotsDirectory`: Directory containing the source screenshots
- `-o, --outputDirectory`: Directory where the processed images will be saved
- `-c, --configPath`: (Optional) Path to the configuration file for customizing bezels and adding labels

## Configuration

The configuration file (`config.json`) allows you to customize the appearance of your screenshots. Here are examples for both simple and advanced usage:

### Simple Configuration (Device Framing Only)
```json
{
  "devices": {
    "iPhone 16 Pro Max": {
      "width": 1320,
      "height": 2868,
      "bezelID": "iphone-16-pro-max",
      "bezelColor": "black"
    },
    "iPad Pro 13 - M4": {
      "width": 2064,
      "height": 2752,
      "bezelColor": "space-gray"
    }
  }
}
```

### Advanced Configuration (with Text Labels)
```json
{
  "devices": {
    "iPhone 16 Pro Max": {
      "width": 1320,
      "height": 2868,
      "bezelID": "iphone-16-pro-max",
      "bezelColor": "black",
      "layoutConfiguration": {
        "deviceFrameInsets": {
          "top": 340,
          "left": 20,
          "bottom": -144,
          "right": 20
        },
        "fontSize": 78
      }
    }
  },
  "titles": [
    {
      "localeCode": "en-US",
      "viewID": "dashboard",
      "text": "Smart Home Control at Your Fingertips"
    },
    {
      "localeCode": "en-US",
      "viewID": "remote",
      "text": "Control your home from anywhere"
    },
    {
      "localeCode": "de-DE",
      "viewID": "dashboard",
      "text": "Smart Home Steuerung mit einem Fingertipp"
    },
    {
      "localeCode": "de-DE",
      "viewID": "remote",
      "text": "Steuern Sie Ihr Zuhause von überall"
    }
  ]
}
```

### Device Configuration

Each device entry in the configuration requires:
- `width` and `height`: The resolution of the screenshot (in pixels)
- `bezelID`: (Optional) Specific device identifier for exact bezel matching. Only necessary when multiple devices share the same resolution and you need fine-grained control over which device bezel to use.
- `bezelColor`: (Optional) Color of the device bezel
- `layoutConfiguration`: (Optional) Settings for text placement and sizing
  - `deviceFrameInsets`: Margins around the device frame
  - `fontSize`: Size of the title text

By default, the tool automatically selects the appropriate device bezel based on the screenshot resolution. The `bezelID` is only needed when you want to override this automatic selection, typically when dealing with different devices that have identical screen resolutions.

### Title Configuration

The entire "titles" section is optional and only needed when you want to add text labels to your screenshots. When provided, each title entry requires:
- `localeCode`: Language code (e.g., "en-US", "de-DE")
- `viewID`: Identifier matching the screenshot (derived from filename)
- `text`: The text to display above the screenshot

For simple device framing without labels, you can omit the "titles" section entirely from your configuration.

## File Naming Convention

Screenshots should follow this naming pattern:
```
{locale_code}/{view_id}.png
```

Example:
```
en-US/home.png
de-DE/features.png
```

## How It Works

1. Without Configuration:
   - The tool analyzes the screenshot resolution
   - Automatically selects the appropriate device bezel
   - Positions the screenshot within the device frame

2. With Configuration:
   - Uses specified device bezels and colors
   - Adds custom text labels
   - Applies precise positioning and styling

## Requirements

- macOS 12.0 or later
- Swift 5.7 or later

## Device Bezels Repository

All device bezels used by this tool are hosted in the [frameit-bezels](https://github.com/sathoeni/frameit-bezels) repository. This repository contains the device frames and their corresponding metadata.

### Contributing Device Bezels

If you'd like to add support for a new device:

1. Fork the [frameit-bezels](https://github.com/sathoeni/frameit-bezels) repository
2. Add your device bezel images
3. Update the `device-bezels.json` with the new device specifications
4. Submit a pull request

For detailed contribution guidelines and bezel specifications, please refer to the documentation in the frameit-bezels repository.
