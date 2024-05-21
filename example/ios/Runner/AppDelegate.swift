import UIKit
import Flutter
import korebotplugin

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    let botClient: BotClient = BotClient()
    var flutterMethodChannel: FlutterMethodChannel? = nil
    
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
                //Set Korebot Config
               self.setBotConfig()
                
                // Callbacks from chatbotVC
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.callbacksMethod), name: NSNotification.Name(rawValue: "CallbacksNotification"), object: nil)
            }else if call.method == "sendMessage"{
                guard let result = call.arguments else {
                return
                }
                let myresult = result as? [String: Any]
                if let messageStr = myresult?["message"] as? String{
                    // send message to bot server
                    self.sendMessageToBot(message: messageStr)
                }
            }
            
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func setBotConfig(){
        
        let clientId = "cs-1e845b00-81ad-5757-a1e7-d0f6fea227e9" // Copy this value from Bot Builder SDK Settings ex. cs-5250bdc9-6bfe-5ece-92c9-ab54aa2d4285
        let clientSecret = "5OcBSQtH/k6Q/S6A3bseYfOee02YjjLLTNoT1qZDBso=" // Copy this value from Bot Builder SDK Settings ex. Wibn3ULagYyq0J10LCndswYycHGLuIWbwHvTRSfLwhs=
        let botId =  "st-b9889c46-218c-58f7-838f-73ae9203488c" // Copy this value from Bot Builder -> Channels -> Web/Mobile Client  ex. st-acecd91f-b009-5f3f-9c15-7249186d827d
        let chatBotName = "SDKBot" // Copy this value from Bot Builder -> Channels -> Web/Mobile Client  ex. "Demo Bot"
        let identityy = "rajasekhar.balla@kore.com"// This should represent the subject for JWT token. This can be an email or phone number, in case of known user, and in case of anonymous user, this can be a randomly generated unique id.
        let isAnonymous = true// This should be either true (in case of known-user) or false (in-case of anonymous user).
        let JWT_SERVER = String(format: "https://mk2r2rmj21.execute-api.us-east-1.amazonaws.com/dev/users/sts") // Replace it with the actual JWT server URL, if required. Refer to developer documentation for instructions on hosting JWT Server.
        //Setting the server Url
        let botServerUrl: String = "https://bots.kore.ai"
        
        var identity: String! = nil
        if (isAnonymous) {
            identity = self.getUUID()
        } else {
            identity = identityy
        }
        
        self.botClient.genarateJwTokenWithClientId(clientId, clientSecret: clientSecret, identity: identity, isAnonymous: isAnonymous, jwtURL: JWT_SERVER) { jwToken in
            let botInfo: [String: Any] = ["chatBot": chatBotName, "taskBotId": botId]
            
            self.botClient.initialize(botInfoParameters: botInfo, customData: [:])
           
            self.botClient.setKoreBotServerUrl(url: botServerUrl)
            
            let jwt_token = jwToken
            self.botClient.connectWithJwToken(jwt_token, intermediary: { [weak self] (client) in
                self?.botClient.connect(isReconnect: false)
            }, success: { (client) in
                print("\(String(describing: client))")
            }, failure: { (error) in
                print("\(String(describing: error))")
            })
            self.configureBotClient()
            
        } failure: { error in
            print(error)
        }
        
    }
    
    func sendMessageToBot(message:String){
        self.botClient.sendMessage(message, options: [:])
    }
    
    func configureBotClient() {
        
        botClient.onMessage = { (object) in
            //"object" type as "BotMessageModel"
            //print("Bot response: \(object ?? [:])")
            let jsonString = self.stringFromJSONObject(object: object ?? [:])
            NotificationCenter.default.post(name: Notification.Name("CallbacksNotification"), object: jsonString)
        }
        self.botClient.onMessageAck = { (ack) in
            //"ack" type as "Ack"
        }
        self.botClient.connectionDidClose = { (code, reason) in
            //"code" type as "Int", "reason" type as "String"
            print("Close \(String(describing: reason))")
        }
        self.botClient.connectionDidFailWithError = { (error) in
            //"error" type as "NSError"
            print("error \(String(describing: error))")
        }
    }
    
    @objc func callbacksMethod(notification:Notification) {
        let dataString: String = notification.object as! String
        //print("\(dataString)")
        if let eventDic = convertStringToDictionary(text: dataString){
            if flutterMethodChannel != nil{
                flutterMethodChannel?.invokeMethod("Callbacks", arguments: eventDic)
            }
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
    
    func getUUID() -> String {
        var id: String?
        let userDefaults = UserDefaults.standard
        if let UUID = userDefaults.string(forKey: "UUID") {
            id = UUID
        } else {
            let date: Date = Date()
            id = String(format: "email%ld%@", date.timeIntervalSince1970, "@domain.com")
            userDefaults.set(id, forKey: "UUID")
        }
        return id!
    }
}
