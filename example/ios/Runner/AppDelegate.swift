import UIKit
import Flutter
import korebotplugin

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var flutterMethodChannel: FlutterMethodChannel? = nil
    let searchConnect = SearchConnect()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.tokenExpiry), name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
                
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

                self.searchConnect.classifyQueryApi(serachTxt) { resultDic in
                    if self.flutterMethodChannel != nil{
                        //let jsonStr = self.convertJsonObjectFromString(object: resultDic)
                        self.flutterMethodChannel?.invokeMethod("Callbacks", arguments: resultDic)
                    }
                } failure: { error in
                    print(error)
                    let errorDic = ["error": "No Search can be performed on the query provided"]
                    self.flutterMethodChannel?.invokeMethod("Callbacks", arguments: errorDic)
                    
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
            default:
                break
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
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
        let dic = ["event_code": "SESSION_EXPIRED", "event_message": "Your session has been expired. Please re-login."]
        let jsonString = Utilities.stringFromJSONObject(object: dic)
        NotificationCenter.default.post(name: Notification.Name("CallbacksNotification"), object: jsonString)
    }

}
