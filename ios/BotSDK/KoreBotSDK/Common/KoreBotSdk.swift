//
//  KoreBotSdk.swift
//  korebotplugin
//
//  Created by Pagidimarri Kartheek on 23/07/24.
//

import UIKit
public class KoreBotSdk: NSObject {
    
    let searchConnect = SearchConnect()
    
    public override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func connect(methodName:String, callArguments:[String:Any]){
        switch (methodName) {
        case "getChatWindow":
             let botConfig = callArguments
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.tokenExpiry), name: NSNotification.Name(rawValue: "TokenExpiryNotification"), object: nil)
            
            //Set Korebot Config
            self.searchConnect.botConnect(botConfig: botConfig)
            
        case "sendMessage":
            let myresult = callArguments as? [String: Any]
            if let message = myresult?["message"] as? String{
            // MARK: Send message to bot
                if let msg_data = myresult?["msg_data"] as? [String:Any]{
                    self.searchConnect.sendMessage(message, options: [:], messageData: msg_data)
                }else{
                    self.searchConnect.sendMessage(message, options: [:], messageData: [:])
                }
               
            }
            
        case "initialize":
            let botConfig = callArguments
            //Set Search Config
            self.searchConnect.getJwTokenWithClientId(botConfig: botConfig, success: {  (jwToken) in
                print(jwToken ?? "")
            }, failure: { (error) in
                print(error)
            })
            
        case "getSearchResults":
            let messageDetails = callArguments as? [String: Any]
            guard let serachTxt = messageDetails?["searchQuery"] as? String else{
                return
            }
            let context_data = messageDetails?["context_data"] as? [String:Any]
            var context_data_String = ""
            for (key, value) in context_data ?? [:] {
                context_data_String.append(" \(key):\(value)")
            }
            self.searchConnect.classifyQueryApi(serachTxt,context_data_String) { resultDic in
                let jsonString = Utilities.stringFromJSONObject(object: resultDic)
                NotificationCenter.default.post(name: Notification.Name(callbacksNotification), object: jsonString)
            } failure: { error in
                print(error)
                let jsonString = "No Search can be performed on the query provided"
                NotificationCenter.default.post(name: Notification.Name(callbacksNotification), object: jsonString)
            }

        case "getHistoryResults":
            let historyDetails = callArguments as? [String: Any]
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
    }
    
    @objc func tokenExpiry(notification:Notification){
        let dic = ["event_code": "SESSION_EXPIRED", "event_message": "Your session has been expired. Please re-login."]
        let jsonString = Utilities.stringFromJSONObject(object: dic)
        NotificationCenter.default.post(name: Notification.Name(callbacksNotification), object: jsonString)
    }

}
