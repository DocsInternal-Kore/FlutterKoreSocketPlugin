import UIKit
import Flutter
import korebotplugin

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    let botClient: BotClient = BotClient()
    let kaBotClient: KABotClient = KABotClient()
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
            
            if call.method == "getChatWindow"{
                guard let botConfig = call.arguments else {
                return
                }
                let configDetails = botConfig as? [String: Any]
                guard let clientId = configDetails?["clientId"] as? String else{
                   return
                }
                guard let clientSecret = configDetails?["clientSecret"] as? String else{
                   return
                }
                guard let botId = configDetails?["botId"] as? String else{
                   return
                }
                guard let chatBotName = configDetails?["chatBotName"] as? String else{
                   return
                }
                guard let identity = configDetails?["identity"] as? String else{
                   return
                }
                guard let jwtToken = configDetails?["jwtToken"] as? String else{
                    return
                }
                guard let jwtServerUrl = configDetails?["jwt_server_url"] as? String else{
                    return
                 }
                guard let botServerUrl = configDetails?["server_url"] as? String else{
                    return
                 }
                guard let isReconnect = configDetails?["isReconnect"] as? Bool else{
                    return
                 }
                //Set Korebot Config
                self.setBotConfig(clientId: clientId, clientSecret: clientSecret, botId: botId, chatBotName: chatBotName, identity: identity, JWT_SERVER: jwtServerUrl, BOT_SERVER: botServerUrl,customJWToken : jwtToken, isReconnect: isReconnect)
               
                
                // Callbacks from chatbotVC
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.callbacksMethod), name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.tokenExpiry), name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
                
            }else if call.method == "sendMessage"{
                guard let result = call.arguments else {
                return
                }
                let myresult = result as? [String: Any]
                if let messageStr = myresult?["message"] as? String{
                    // send message to bot server
                    self.sendMessageToBot(message: messageStr)
                }
            }else if call.method == "initialize"{
                guard let botConfig = call.arguments else {
                  return
                }
                let configDetails = botConfig as? [String: Any]
                guard let clientId = configDetails?["clientId"] as? String else{
                   return
                }
                guard let clientSecret = configDetails?["clientSecret"] as? String else{
                   return
                }
                guard let botId = configDetails?["botId"] as? String else{
                   return
                }
                guard let chatBotName = configDetails?["chatBotName"] as? String else{
                   return
                }
                guard let identity = configDetails?["identity"] as? String else{
                   return
                }
                guard let jwtToken = configDetails?["jwtToken"] as? String else{
                    return
                 }
                guard let jwtServerUrl = configDetails?["jwt_server_url"] as? String else{
                    return
                 }
                guard let botServerUrl = configDetails?["server_url"] as? String else{
                    return
                 }
                guard let isReconnect = configDetails?["isReconnect"] as? Bool else{
                    return
                 }

                //Set Search connect Config
                self.searchConnectConfig(clientId: clientId, clientSecret: clientSecret, botId: botId, chatBotName: chatBotName, identity: identity,JWT_SERVER: jwtServerUrl, bot_SERVER_Url: botServerUrl, customJWToken:jwtToken, isReconnect: isReconnect)
                
            }else if call.method == "getSearchResults"{
                guard let message = call.arguments else {
                return
                }
                let messageDetails = message as? [String: Any]
                guard let serachTxt = messageDetails?["searchQuery"] as? String else{
                   return
                }
                self.sendQuery(text: serachTxt)
            }else if call.method == "getHistoryResults"{
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
                self.getChatHistory(offset: offset, limit: limit)
            }else if call.method == "closeBot"{
                self.closeBot()
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: Bot Connection
    func setBotConfig(clientId:String, clientSecret:String, botId:String, chatBotName:String, identity:String, JWT_SERVER:String, BOT_SERVER:String,customJWToken:String, isReconnect: Bool){
        
        let clientId = clientId // Copy this value from Bot Builder SDK Settings ex. cs-5250bdc9-6bfe-5ece-92c9-ab54aa2d4285
        let clientSecret = clientSecret // Copy this value from Bot Builder SDK Settings ex. Wibn3ULagYyq0J10LCndswYycHGLuIWbwHvTRSfLwhs=
        let botId =  botId // Copy this value from Bot Builder -> Channels -> Web/Mobile Client  ex. st-acecd91f-b009-5f3f-9c15-7249186d827d
        let chatBotName = chatBotName // Copy this value from Bot Builder -> Channels -> Web/Mobile Client  ex. "Demo Bot"
        let identityy = identity// This should represent the subject for JWT token. This can be an email or phone number, in case of known user, and in case of anonymous user, this can be a randomly generated unique id.
        let isAnonymous = false// This should be either true (in case of known-user) or false (in-case of anonymous user).
        let JWT_SERVER = "\(JWT_SERVER)"  //users/sts// Replace it with the actual JWT server URL, if required. Refer to developer documentation for instructions on hosting JWT Server.
        
        //Setting the server Url
        let botServerUrl: String = BOT_SERVER
        
        searchConnect.botConnect(clientId, koreClientSecret: clientSecret, koreBotID: botId, KoreBotName: chatBotName, Koreidentity: identityy, KoreisAnonymous: isAnonymous, jwt_Server_Url: JWT_SERVER, botServerUrl: botServerUrl,customJWToken: customJWToken, isReconnect: isReconnect)
    }
    
    // MARK: Send message to bot
    func sendMessageToBot(message:String){
        searchConnect.sendMessage(message, options: [:])
    }
    
    // MARK: chat history
    func getChatHistory(offset:Int, limit:Int){
        searchConnect.getChatHistory(offset: offset, limit: limit)
    }
    
    // MARK: Close the bot
    func closeBot(){
        searchConnect.closeBot()
    }
    
    // MARK: Callbacks From Native to flutter
    @objc func callbacksMethod(notification:Notification) {
        let dataString: String = notification.object as! String
        //print("\(dataString)")
        if let eventDic = convertStringToDictionary(text: dataString){
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

    // MARK: Search assist
    func searchConnectConfig(clientId:String, clientSecret:String, botId:String, chatBotName:String, identity:String,JWT_SERVER:String,bot_SERVER_Url:String,customJWToken:String,isReconnect: Bool){
        let clientId: String = clientId
        let clientSecret: String = clientSecret
        let isAnonymous: Bool = false
        let identity =  identity
        let jwtServerUrl: String = "\(JWT_SERVER)" //users/sts
        let botServerUrl: String = bot_SERVER_Url
        let custom_JWToken: String = customJWToken
        self.searchConnect.getJwTokenWithClientId(clientId, clientSecret: clientSecret, botID: botId, identity: identity, isAnonymous: isAnonymous,jwtServerUrl:jwtServerUrl,botServerUrl:botServerUrl,customJWToken: custom_JWToken,isReconnect: isReconnect, success: {  (jwToken) in
            print(jwToken)
        }, failure: { (error) in
            print(error)
        })
    }
    
    func sendQuery(text:String){
        self.searchConnect.getSearchResults(text) { resultDic in
           // print(resultDic)
            if self.flutterMethodChannel != nil{
                //let jsonStr = self.convertJsonObjectFromString(object: resultDic)
                self.flutterMethodChannel?.invokeMethod("Callbacks", arguments: resultDic)
            }
        } failure: { (error) in
            print(error)
        }
    }

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
    
    func stringFromJSONObject(object: Any) -> String? {
        var jsonString: String? = nil
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            jsonString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        } catch {
            print(error.localizedDescription)
        }
        return jsonString
    }
}
