# Kore Bot Plugin Example

A comprehensive example demonstrating the integration and usage of the Kore Bot Plugin for Flutter applications. This example showcases how to implement a chatbot interface with various features including message handling, search functionality, and custom data management.

## Features

- Bot connection management
- Real-time messaging
- Search functionality
- Chat history retrieval
- Custom data updates
- Socket connection status monitoring

## Getting Started

### Prerequisites

- Flutter SDK (latest version recommended)
- Android Studio or VS Code with Flutter extensions
- Basic knowledge of Flutter development

### Installation

1. Add the plugin to your `pubspec.yaml`:
   ```yaml
   dependencies:
     korebotplugin: ^latest_version
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Import the plugin in your Dart code:
   ```dart
   import 'package:korebotplugin/korebotplugin.dart';
   ```

## Configuration

The example demonstrates bot configuration with the following parameters:

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
    "custom_data": {"age": 39, "gender": "M"}
};
```

## Usage

### 1. Initialize the Bot
```dart
await botInitialize();
```

### 2. Connect to the Bot
```dart
await connectToBot();
```

### 3. Send Messages
```dart
await sendMessage("Your message here");
```

### 4. Perform Searches
```dart
await getSearchResults("Your search query");
```

### 5. Retrieve Chat History
```dart
await getHistoryResults(0, 10); // offset, limit
```

### 6. Update Custom Data
```dart
await updateCustomData({
    "size": 40,
    "gender": "F",
    "color": "blue",
    "age": 38,
    "outfit": "T-shirt"
});
```

## Error Handling

The example includes comprehensive error handling for:
- Platform exceptions
- Connection failures
- Message delivery failures
- Search errors

## UI Components

The example provides a complete UI implementation including:
- Message input field
- Send button
- Search interface
- Connection status indicators
- History retrieval
- Custom data management

## Support

For issues and feature requests, please file them on the [issue tracker](https://github.com/your-repo/issues).

## License

License Copyright © Kore.ai, Inc. MIT License; see LICENSE for further details.
