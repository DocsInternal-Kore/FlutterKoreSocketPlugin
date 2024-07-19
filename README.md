# Flutter Plugin integration

Assuming flutter application is available

## Update pubspec file 

Add below snippet into flutter app pubspec.yaml “path” is where plugin is copied after that need to run “flutter pub get”
```
dependencies:
  flutter:
    sdk: flutter


  korebotplugin:
     # the parent directory to use the current plugin's version.
    path: ../ 
```

Steps for Integrating Flutter Socket Plugin into Flutter Application

1) Create a “Method channel” with channel name as below
```
static const platform = MethodChannel('kore.botsdk/chatbot');
```

2) Here is the sample varible format to pass bot configuration to the SDK's
```
var botConfig = {
    "clientId": "cs-47e5f4e6-0621-563d-a3fb-2d1f3ab94750",
    "clientSecret": "TvctzsjB/iewjdddKi2Ber4PPrYr0LoTi1WUasiMceM=",
    "botId": "st-953e931b-1fe5-5bcc-9bb7-1b9bd4226947",
    "chatBotName": "SDKBot",
    "identity": "example@kore.com",
    "jwt_server_url":
        "https://mk2r2rmj21.execute-api.us-east-1.amazonaws.com/dev/",
    "server_url": "https://platform.kore.ai",
    "isReconnect": false,
    "jwtToken": "",
    "custom_data": {"age": 34, "gender": "M"}
  };

var searchConfig = {
    "botId": "st-953e931b-1fe5-5bcc-9bb7-1b9bd4226947",
    "indexName": "tedbaker-test",
    "namespace": "tedbaker-gender-v1",
    "stage": "dev",
    "retail_server_url": "https://retailassist-poc.kore.ai/"
  };

```

3) Below is the method to be called from the parent application before connecting to the bot. Which intializes the SDK
```
Future<void> botInitialize() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String config =
          await platform.invokeMethod('initialize', searchConfig);
    } on PlatformException catch (e) {}
  }
```
4) Below is the method to be called to establish the bot connection
```
“connectToBot” can be changed as per requirement.
Future<void> connectToBot() async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String result =
          await platform.invokeMethod('getChatWindow', botConfig);
    } on PlatformException catch (e) {}
  }

```
5) On button press the above mentioned method can be called to initiate the chat socket as below
```
 children: [
          ElevatedButton(
            onPressed: connectToBot,
            child: const Text('Bot Connect'),
          ),
        ],
```

6) All the callbacks from native to the flutter application happens in the below snippet. Users can implement their own logics as per requirement.
```
platform.setMethodCallHandler((handler) async {
    if (handler.method == 'Callbacks') {
      // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

```

7) When user wants to send any message to bot below method can be used. We can add context data as well in this method as key, value pair
```
“_callSendmethod” can be changed as per requirement.
Future<void> _callSendmethod(msg) async {
    platform.setMethodCallHandler((handler) async {
      if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Event from native ${handler.arguments}");
      }
    });

    try {
      final String result = await platform.invokeMethod('sendMessage', {
        "message": msg,
        "msg_data": {"size": 40, "gender": "M"}
      });
    } on PlatformException catch (e) {}
  }

```
8) When message sent to bot, bot_reponse can be received through callback in the same method
```
if (handler.method == 'Callbacks') {
        // Do your logic here.
        debugPrint("Bot response from native ${handler.arguments}");
      }
```

10) Below method can be used for getting search results with context data(Optional)
```
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

By using the above method search results can be received in the "Callbacks" so that developer can implement their own logic

11) Below method can be used to get the history of the user chat by providing "offset"(Number of conversations currently in the chat window) and "limit" (Limit of history messages to be received)
```
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

12) Below is the method can be used to close the bot.
```
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


# For iOS:
Add below lines in AppDelegate.swift

<img width="597" alt="image" src="https://github.com/SudheerJa-Kore/KoreBotflutterplugin/assets/64408292/fb33b51c-1795-48af-933b-cae0bf0bbe69">

``` 
 //Callbacks from chatbotVC
  NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
  NotificationCenter.default.addObserver(self, selector: #selector(self.callbacksMethod), name: 
  NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
```
```
@objc func callbacksMethod(notification:Notification) {
        let dataString: String = notification.object as! String
                if let eventDic = convertStringToDictionary(text: dataString){
            if flutterMethodChannel != nil{
                flutterMethodChannel?.invokeMethod("Callbacks", arguments: eventDic)
            }
        }
    }
```
```
  func convertStringToDictionary(text: String) -> [String: Any]? {
      if let data = text.data(using: .utf8) {
          do {
              return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
          } catch {
              print(error.localizedDescription)
          }
      }
      return nil
  }
  ```
  <img width="607" alt="image" src="https://github.com/SudheerJa-Kore/KoreBotflutterplugin/assets/64408292/7a6b82c6-c0f3-4d1c-af1f-e7fbedbbb6d4">

  
