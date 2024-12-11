# Kore Bot SDK Flutter Plugin

<div align="center">

![Kore.ai Logo](https://www.kore.ai/wp-content/themes/kore/images/kore-ai-logo.png)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Pub Version](https://img.shields.io/pub/v/korebotplugin?style=for-the-badge)](https://pub.dev/packages/korebotplugin)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

## 📝 Description

A Flutter plugin for integrating Kore.ai's powerful chatbot SDK into your Flutter applications. This plugin provides seamless communication between your Flutter app and Kore.ai's bot platform, enabling rich conversational experiences.

## ✨ Features

- 🤖 Real-time bot communication
- 🔍 Advanced search capabilities
- 📱 Native UI integration
- 🔄 Automatic reconnection handling
- 📊 Custom data management
- 📜 Chat history retrieval
- 🔐 Secure JWT authentication

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest version recommended)
- iOS 11.0 or higher
- Android API level 21 or higher
- Kore.ai bot credentials

### Installation

1. Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  korebotplugin:
    path: ../  # Use path for local development
    # OR
    # version: ^latest_version  # From pub.dev
```

2. Run flutter pub get:
```bash
flutter pub get
```

## 💻 Implementation Guide

### 1. Initialize Method Channel

Create a method channel for communication:

```dart
static const platform = MethodChannel('kore.botsdk/chatbot');
```

### 2. Configure Bot Settings

Set up your bot configuration:

```dart
var botConfig = {
    "clientId": "YOUR_CLIENT_ID",
    "clientSecret": "YOUR_CLIENT_SECRET",
    "botId": "YOUR_BOT_ID",
    "chatBotName": "YOUR_BOT_NAME",
    "identity": "user@example.com",
    "jwt_server_url": "YOUR_JWT_SERVER_URL",
    "server_url": "YOUR_SERVER_URL",
    "isReconnect": false,
    "jwtToken": "",
    "custom_data": {
        "age": 34,
        "gender": "M"
    }
};

var searchConfig = {
    "botId": "YOUR_SEARCH_BOT_ID",
    "indexName": "YOUR_INDEX",
    "namespace": "YOUR_NAMESPACE",
    "stage": "dev",
    "retail_server_url": "YOUR_RETAIL_SERVER_URL"
};
```

### 3. Initialize the Bot

```dart
Future<void> botInitialize() async {
    platform.setMethodCallHandler((handler) async {
        if (handler.method == 'Callbacks') {
            // Handle callbacks here
            debugPrint("Event from native ${handler.arguments}");
        }
    });

    try {
        await platform.invokeMethod('initialize', searchConfig);
    } on PlatformException catch (e) {
        // Handle initialization errors
    }
}
```

### 4. Connect to Bot

```dart
Future<void> connectToBot() async {
    platform.setMethodCallHandler((handler) async {
        if (handler.method == 'Callbacks') {
            // Handle connection callbacks
            debugPrint("Event from native ${handler.arguments}");
        }
    });

    try {
        await platform.invokeMethod('getChatWindow', botConfig);
    } on PlatformException catch (e) {
        // Handle connection errors
    }
}
```

### 5. UI Integration

```dart
ElevatedButton(
    onPressed: connectToBot,
    child: const Text('Connect to Bot'),
    style: ElevatedButton.styleFrom(
        primary: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
)
```

## 🔄 Available Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `initialize` | Initialize the bot SDK | `searchConfig` |
| `getChatWindow` | Connect to the bot | `botConfig` |
| `sendMessage` | Send a message | `message` |
| `getSearchResults` | Perform search | `query`, `context` |
| `getHistoryResults` | Get chat history | `offset`, `limit` |
| `closeBot` | Close bot connection | - |
| `isSocketConnected` | Check connection status | - |
| `updateCustomData` | Update custom data | `customData` |

## 🛠 iOS-Specific Setup

Add the following to your `AppDelegate.swift`:

```swift
let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
flutterMethodChannel = FlutterMethodChannel(
    name: "kore.botsdk/chatbot",
    binaryMessenger: controller.binaryMessenger
)
```

## 📱 Example Implementation

Check out our [example app](./example) for a complete implementation showcase.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, please:
1. Check our [documentation](https://developer.kore.ai/docs/bots/sdks/flutter-sdk/)
2. Raise an issue in our [GitHub repository](https://github.com/Koredotcom/flutter-plugin/issues)
3. Contact [Kore.ai Support](https://www.kore.ai/contact-us/)
