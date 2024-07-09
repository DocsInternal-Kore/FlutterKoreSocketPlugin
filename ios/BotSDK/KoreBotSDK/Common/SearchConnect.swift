//
//  BotConnect.swift
//  KoreBotSDKFrameWork
//
//  Created by Kartheek.Pagidimarri on 17/05/21.
//  Copyright © 2021 Kartheek.Pagidimarri. All rights reserved.
//

import UIKit
import Alamofire
//import korebotplugin
import Foundation

public class SearchConnect: NSObject {
    let kaBotClient: KABotClient = KABotClient()
    let sessionManager: Session = {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 30
        return Session(configuration: configuration)
    }()
    
    var searchJwtToken = ""
    // MARK: - init
    public override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func botConnect(_ koreClientId: String!, koreClientSecret: String!, koreBotID: String!, KoreBotName: String!, Koreidentity: String!, KoreisAnonymous: Bool!,jwt_Server_Url:String,botServerUrl:String, customJWToken: String, isReconnect: Bool){
        SDKConfiguration.botConfig.clientId = koreClientId
        SDKConfiguration.botConfig.clientSecret = koreClientSecret
        SDKConfiguration.botConfig.botId = koreBotID
        SDKConfiguration.botConfig.chatBotName = KoreBotName
        SDKConfiguration.botConfig.identity = Koreidentity
        SDKConfiguration.botConfig.isAnonymous = KoreisAnonymous
        SDKConfiguration.serverConfig.JWT_SERVER = jwt_Server_Url
        SDKConfiguration.serverConfig.BOT_SERVER = botServerUrl
        SDKConfiguration.botConfig.customJWToken = customJWToken
        SDKConfiguration.botConfig.isReconnect =  isReconnect
        
        kaBotClient.connect(block: { [weak self] (client) in
            print("Sucess")
            let dic = ["event_code": "BotConnected", "event_message": "Bot connected successfully"]
            let jsonString = Utilities.stringFromJSONObject(object: dic)
            NotificationCenter.default.post(name: Notification.Name(callbacksNotification), object: jsonString)
        }) { (error) in
            print(error.localizedDescription)
            let dic = ["event_code": "BotConnected", "event_message": "Bot connected failed"]
            let jsonString = Utilities.stringFromJSONObject(object: dic)
            NotificationCenter.default.post(name: Notification.Name(callbacksNotification), object: jsonString)
        }
    }
    
    public func sendMessage(_ message: String, options: [String: Any]?){
        kaBotClient.sendMessage(message, options: options)
    }
    // MARK: chat history
    public func getChatHistory(offset:Int, limit:Int){
        kaBotClient.getMessages(offset: offset, limit: limit, completion:{ (success) in
            if success {
                
            } else {
                
            }
        })
    }
    // MARK: get JWT token request for search
    public func getJwTokenWithClientId(_ clientId: String!, clientSecret: String!, botID: String!, identity: String!, isAnonymous: Bool!,jwtServerUrl:String,botServerUrl:String, customJWToken:String!,isReconnect:Bool, success:((_ jwToken: String?) -> Void)?, failure:((_ error: Error) -> Void)?) {
        if customJWToken != ""{
            SDKConfiguration.botConfig.customJWToken = customJWToken
            success?(customJWToken)
        }else{
            SDKConfiguration.botConfig.botId = botID
            SDKConfiguration.serverConfig.JWT_SERVER = jwtServerUrl
            SDKConfiguration.serverConfig.BOT_SERVER = botServerUrl
            SDKConfiguration.botConfig.isReconnect = isReconnect
            
            let urlString =  "\(SDKConfiguration.serverConfig.JWT_SERVER)users/sts"
            let headers: HTTPHeaders = [
                "Keep-Alive": "Connection",
                "Accept": "application/json",
                "alg": "RS256",
                "typ": "JWT"
            ]
            
            let parameters: [String: Any] = ["clientId": clientId as String,
                                             "clientSecret": clientSecret as String,
                                             "identity": identity as String,
                                             "aud": "https://idproxy.kore.com/authorize",
                                             "isAnonymous": isAnonymous as Bool]
            let dataRequest = sessionManager.request(urlString, method: .post, parameters: parameters, headers: headers)
            dataRequest.validate().responseJSON { (response) in
                if let _ = response.error {
                    let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                    failure?(error)
                    self.searchJwtToken = ""
                    SDKConfiguration.botConfig.customJWToken = ""
                    return
                }
                if let dictionary = response.value as? [String: Any],
                   let jwToken = dictionary["jwt"] as? String {
                    self.searchJwtToken = jwToken
                    SDKConfiguration.botConfig.customJWToken = jwToken
                    success?(jwToken)
                } else {
                    let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                    failure?(error)
                    self.searchJwtToken = ""
                    SDKConfiguration.botConfig.customJWToken = ""
                }
            }
        }
        
    }
    
    public func getSearchResults(_ text: String!, success:((_ dictionary: [String: Any]) -> Void)?, failure:((_ error: Error) -> Void)?) {
        let urlString: String = "\(SDKConfiguration.serverConfig.BOT_SERVER)/api/public/stream/\(SDKConfiguration.botConfig.botId)/advancedSearch"
        let authorizationStr = "\(SDKConfiguration.botConfig.customJWToken)"
        let headers: HTTPHeaders = [
            "Keep-Alive": "Connection",
            "Content-Type": "application/json",
            "auth": authorizationStr
        ]
        let parameters: [String: Any]  = ["query": text ?? ""]
        
        let dataRequest = sessionManager.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        dataRequest.validate().responseJSON { (response) in
            if let _ = response.error {
                let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                failure?(error)
                return
            }
            
            if let dictionary = response.value as? [String: Any]{
                    success?(dictionary)
            } else {
                let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                    failure?(error)
            }
        }
    }
    
    public func closeBot(){
        KABotClient.shared.deConfigureBotClient()
    }

}

