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

7) When user wants to send any message to bot below method can be used. We can add context data as well in this method as key, value pair.
   This method verifies the bot connection is active or not, If active sends the message if not sends a call back to prarent app and tries to reconnect the bot connection
   and sends the message to bot.
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

13) Below is the method can be used to verify the bot connection active or inactive.
```
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





# For iOS:


1) Add below lines in AppDelegate.swift
```
import korebotplugin
let searchConnect = SearchConnect()

```
2) Add below lines in didFinishLaunchingWithOptions method in AppDelegate.swift
```
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
                self.searchConnect.connectBotConnectStatus()
            default:
                break
            }
        })

```

3) Add below methods in AppDelegate.swift

```
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

# Error CallBacks

1) When fails in fetching jwt token
```
{ "eventCode" : "Error_STS", "eventMessage" : "STS call failed" }
```

2) When fails in jwt grant call
```
{ "eventCode" : "Error_JwtGrant", "eventMessage" : "JwtGrant call failed" }
```

3) When fails in RTM start call
```
{ "eventCode" : "Error_RTMStart", "eventMessage" : "RTM start call failed" }
```

4) When Socket connection to Bot failed
```
{ "eventCode" : "Error_Socket", "eventMessage" : "Unable to connect. Please try again later" }
```

5) When Socket connected successfully
```
{ "eventCode " : "BotConnected" , "eventMessage" : "Bot connected successfully" }
```

6) When Socket disconnected by user or network disconnection
```
{ "eventCode" : "BotDisconnected", "eventMessage" : "Bot disconnected" }
```

7) When message send to bot and when socket is not connected sending this callback
```
{ "eventCode" : "Send_Failed", "eventMessage" : "Socket disconnected, Trying to reconnect" }
```
  
