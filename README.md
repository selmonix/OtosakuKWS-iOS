# OtosakuKWS-iOS 🎤

![OtosakuKWS-iOS](https://img.shields.io/badge/OtosakuKWS-iOS-blue.svg)  
[![Releases](https://img.shields.io/badge/Releases-latest-orange.svg)](https://github.com/selmonix/OtosakuKWS-iOS/releases)

Welcome to the **OtosakuKWS-iOS** repository! This project provides a lightweight, on-device keyword spotting engine for iOS. It leverages CoreML and supports real-time audio streaming. With this tool, you can implement efficient speech recognition and wake word detection in your iOS applications.

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Features

- **On-Device Processing**: No need for an internet connection. All processing happens on the device.
- **Real-Time Audio Streaming**: Capture and analyze audio input in real-time.
- **CoreML Integration**: Utilize Apple's powerful machine learning framework for efficient processing.
- **Lightweight**: Designed to run smoothly on iOS devices without draining resources.
- **Keyword Spotting**: Detect specific keywords or phrases with high accuracy.
- **Customizable**: Easily modify the model to suit your specific needs.

## Getting Started

To get started with **OtosakuKWS-iOS**, follow the instructions below.

### Prerequisites

Before you begin, ensure you have the following:

- An iOS device or simulator running iOS 12.0 or later.
- Xcode 12 or later installed on your machine.
- Basic knowledge of Swift and iOS development.

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/selmonix/OtosakuKWS-iOS.git
   cd OtosakuKWS-iOS
   ```

2. Open the project in Xcode:

   ```bash
   open OtosakuKWS-iOS.xcodeproj
   ```

3. Build and run the project on your device or simulator.

4. For pre-built binaries, visit the [Releases](https://github.com/selmonix/OtosakuKWS-iOS/releases) section to download the latest version.

## Usage

After installation, you can start using the OtosakuKWS-iOS engine in your application.

### Basic Setup

1. Import the framework in your Swift files:

   ```swift
   import OtosakuKWS
   ```

2. Initialize the keyword spotting engine:

   ```swift
   let kwsEngine = KeywordSpottingEngine()
   ```

3. Start the audio stream:

   ```swift
   kwsEngine.startAudioStream()
   ```

4. Set up your keyword:

   ```swift
   kwsEngine.setKeyword("Hello")
   ```

5. Handle the detected keywords:

   ```swift
   kwsEngine.onKeywordDetected = { keyword in
       print("Detected keyword: \(keyword)")
   }
   ```

### Example

Here is a simple example of how to use the engine:

```swift
import UIKit
import OtosakuKWS

class ViewController: UIViewController {
    let kwsEngine = KeywordSpottingEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        kwsEngine.onKeywordDetected = { keyword in
            print("Detected keyword: \(keyword)")
        }
        
        kwsEngine.setKeyword("Hello")
        kwsEngine.startAudioStream()
    }
}
```

## Contributing

We welcome contributions! If you have suggestions for improvements or want to add features, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes.
4. Submit a pull request with a description of your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the CoreML team for providing a robust framework for machine learning on iOS.
- Special thanks to the open-source community for their contributions and support.

For more details, check the [Releases](https://github.com/selmonix/OtosakuKWS-iOS/releases) section to download the latest version and get started with your implementation!