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

### 5) On button press the above mentioned method can be called to initiate the chat socket as below
```dart
 children: [
          ElevatedButton(
            onPressed: connectToBot,
            child: const Text('Bot Connect'),
          ),
        ],
```

### 6) All the callbacks from native to the flutter application happens in the below snippet. Users can implement their own logics as per requirement.
```dart
platform.setMethodCallHandler((handler) async {
    if (handler.method == 'Callbacks') {
      // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

```

### 7) Send message to Bot.
   This method verifies the bot connection is active or not, If active sends the message if not sends a call back to prarent app and tries to reconnect the bot connection
   and sends the message to bot.
```dart
“_callSendmethod” can be changed as per requirement.
Future<void> _callSendmethod(msg) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String result = await platform.invokeMethod('sendMessage', {"message": msg});
    } on PlatformException catch (e) {}
  }

```
### 8) When message sent to bot, bot_reponse can be received through callback in the same method
```dart
if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Bot response from native ${handler.arguments}");
      }
```

### 9) Search results with context data(Optional)
```dart
Future<void> getSearchResults(searchQuery) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config = await platform.invokeMethod('getSearchResults', {
        "searchQuery": searchQuery,
        "context_data": {"color": "Black", "gender": "M"}
      });
    } on PlatformException catch (e) {}
  }

```

By using the above method search results can be received in the "Callbacks" so that developer can implement your own logic

### 10) Below method can be used to get the history of the user chat by providing "offset"(Number of conversations currently in the chat window) and "limit" (Limit of history messages to be received)
```dart
Future<void> getHistoryResults(offset, limit) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Response will be received here. Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config = await platform.invokeMethod(
          'getHistoryResults', {"offset": offset, "limit": limit});
    } on PlatformException catch (e) {}
  }
```

### 11) Below is the method can be used to close the bot.
```dart
Future<void> closeBot() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'CloseBot') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config = await platform.invokeMethod('closeBot');
    } on PlatformException catch (e) {}
  }
```

### 12) Below is the method can be used to verify the bot connection active or inactive.
```dart
Future<void> isSocketConnected() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String socketConnection =
          await platform.invokeMethod('isSocketConnected');
    } on PlatformException catch (e) {}
  }

CallBack Event : {"eventCode":"BotConnectStatus","eventMessage":"true/false"}
```

### 13) Below is the method can be used to update the custom data during the session.
```dart
Future<void> updateCustomData(customData) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String custom = await platform
          .invokeMethod('updateCustomData', {"custom_data": customData});
    } on PlatformException catch (e) {}
  }

CallBack Event : {"eventCode":"UpdateCustomData","eventMessage":"true/false"}
```

# For iOS:


### 1) Add below lines in AppDelegate.swift
```dart
import korebotplugin
let searchConnect = SearchConnect()

```
### 2) Add below lines in didFinishLaunchingWithOptions method in AppDelegate.swift
```dart
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        flutterMethodChannel = FlutterMethodChannel(name: "kore.botsdk/chatbot",
                                                    binaryMessenger: controller.binaryMessenger)
        flutterMethodChannel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            // This method is invoked on the UI thread.
            let methodName = call.method
            switch (methodName) {
            case "getChatWindow":
                guard let botConfig = call.arguments else {
                    return
                }
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.callbacksMethod), name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.tokenExpiry), name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
                
                //Set Korebot Config
                self.searchConnect.botConnect(botConfig: botConfig as? [String : Any])
                
            case "sendMessage":
                guard let result = call.arguments else {
                    return
                }
                let myresult = result as? [String: Any]
                if let message = myresult?["message"] as? String{
                // MARK: Send message to bot
                    if let msg_data = myresult?["msg_data"] as? [String:Any]{
                        self.searchConnect.sendMessage(message, options: [:], messageData: msg_data)
                    }else{
                        self.searchConnect.sendMessage(message, options: [:], messageData: [:])
                    }
                   
                }
                
            case "initialize":
                // Callbacks from chatbotVC
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.callbacksMethod), name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                guard let botConfig = call.arguments else {
                    return
                }
                //Set Search Config
                self.searchConnect.getJwTokenWithClientId(botConfig: botConfig as? [String : Any], success: {  (jwToken) in
                    print(jwToken ?? "")
                }, failure: { (error) in
                    print(error)
                })
                
            case "getSearchResults":
                guard let message = call.arguments else {
                    return
                }
                let messageDetails = message as? [String: Any]
                guard let serachTxt = messageDetails?["searchQuery"] as? String else{
                    return
                }
                let context_data = messageDetails?["context_data"] as? [String:Any]
                var context_data_String = ""
                for (key, value) in context_data ?? [:] {
                    //print("\(key) -> \(value)")
                    context_data_String.append(" \(key):\(value)")
                }
                //print(context_data_String)
                self.searchConnect.classifyQueryApi(serachTxt,context_data_String) { resultDic in
                    if self.flutterMethodChannel != nil{
                        //let jsonStr = self.convertJsonObjectFromString(object: resultDic)
                        self.flutterMethodChannel?.invokeMethod("Callbacks", arguments: resultDic)
                    }
                } failure: { error in
                    print(error)
                    self.flutterMethodChannel?.invokeMethod("Callbacks", arguments: "No Search can be performed on the query provided")
                    
                }

            case "getHistoryResults":
                guard let history = call.arguments else {
                    return
                }
                let historyDetails = history as? [String: Any]
                guard let offset = historyDetails?["offset"] as? Int else{
                    return
                }
                guard let limit = historyDetails?["limit"] as? Int else{
                    return
                }
                // MARK: chat history
                self.searchConnect.getChatHistory(offset: offset, limit: limit)
                
            case "closeBot":
                // MARK: Close the bot
                self.searchConnect.closeBot()
                
            case "isSocketConnected":
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.callbacksMethod), name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                self.searchConnect.connectBotConnectStatus()
                
            case "updateCustomData":
                guard let result = call.arguments else {
                    return
                }
                let myresult = result as? [String: Any]
                // MARK: Update CustomData
                if let custom_data = myresult?["custom_data"] as? [String:Any]{
                    self.searchConnect.updateCustomData(customData: custom_data)
                }
            default:
                break
            }
        })

```

### 3) Add below methods in AppDelegate.swift
```dart
    // MARK: Callbacks From Native to flutter
    @objc func callbacksMethod(notification:Notification) {
        let dataString: String = notification.object as! String
        //print("\(dataString)")
        if let eventDic = Utilities.jsonObjectFromString(jsonString: dataString){
            if flutterMethodChannel != nil{
                flutterMethodChannel?.invokeMethod("Callbacks", arguments: eventDic)
            }
        }
    }
    
    @objc func tokenExpiry(notification:Notification){
        let jsonString: String = notification.object as! String
        NotificationCenter.default.post(name: Notification.Name("CallbacksNotification"), object: jsonString)
    }
```

### Error CallBacks

1) When fails in fetching jwt token
```dart
{ "eventCode" : "Error_STS", "eventMessage" : "STS call failed" }
```

2) When fails in jwt grant call
```dart
{ "eventCode" : "Error_JwtGrant", "eventMessage" : "JwtGrant call failed" }
```

3) When fails in RTM start call
```dart
{ "eventCode" : "Error_RTMStart", "eventMessage" : "RTM start call failed" }
```

4) When Socket connection to Bot failed
```dart
{ "eventCode" : "Error_Socket", "eventMessage" : "Unable to connect. Please try again later" }
```

5) When Socket connected successfully
```dart
{ "eventCode " : "BotConnected" , "eventMessage" : "Bot connected successfully" }
```

6) When Socket disconnected by user or network disconnection
```dart
{ "eventCode" : "BotDisconnected", "eventMessage" : "Bot disconnected" }
```

7) When message send to bot and when socket is not connected sending this callback
```dart
{ "eventCode" : "Send_Failed", "eventMessage" : "Socket disconnected, Trying to reconnect" }
```

8) When isSocketConnected method called sending this callback
```dart
{ "eventCode" : "BotConnectStatus", "eventMessage" : "true/false" }
```

9) When custom data method called and based on the update in the sdk sending this callback
```dart
{ "eventCode" : "UpdateCustomData", "eventMessage" : "true/false" }
```
  
