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
    
    var searchAccessToken = ""
    var searchAccessTokenType = ""
    var searchBotConfig = [String:Any]()
    // MARK: - init
    public override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func botConnect(botConfig:[String: Any]?){
        let configDetails = botConfig
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
        guard let custom_data = configDetails?["custom_data"] as? [String: Any] else{
            return
        }
        SDKConfiguration.botConfig.clientId = clientId
        SDKConfiguration.botConfig.clientSecret = clientSecret
        SDKConfiguration.botConfig.botId = botId
        SDKConfiguration.botConfig.chatBotName = chatBotName
        SDKConfiguration.botConfig.identity = identity
        SDKConfiguration.botConfig.customJWToken = jwtToken
        SDKConfiguration.botConfig.isAnonymous = false
        SDKConfiguration.serverConfig.JWT_SERVER = jwtServerUrl
        SDKConfiguration.serverConfig.BOT_SERVER = botServerUrl
        SDKConfiguration.botConfig.isReconnect =  isReconnect
        SDKConfiguration.botConfig.customData = custom_data
        
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
    
    public func sendMessage(_ message: String, options: [String: Any]?, messageData: [String: Any]?){
        kaBotClient.sendMessage(message, options: options, messageData: messageData)
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
    public func getJwTokenWithClientIdOld(botConfig:[String:Any]?, success:((_ jwToken: String?) -> Void)?, failure:((_ error: Error) -> Void)?) {
        
        let configDetails = botConfig
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
        guard let customJWToken = configDetails?["jwtToken"] as? String else{
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
        guard let custom_data = configDetails?["custom_data"] as? [String: Any] else{
            return
        }
        SDKConfiguration.botConfig.customData = custom_data
        
        let isAnonymous: Bool = false
        
        if customJWToken != ""{
            SDKConfiguration.botConfig.customJWToken = customJWToken
            success?(customJWToken)
        }else{
            SDKConfiguration.botConfig.botId = botId
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
                    //self.searchJwtToken = ""
                    SDKConfiguration.botConfig.customJWToken = ""
                    return
                }
                if let dictionary = response.value as? [String: Any],
                   let jwToken = dictionary["jwt"] as? String {
                    //self.searchJwtToken = jwToken
                    SDKConfiguration.botConfig.customJWToken = jwToken
                    success?(jwToken)
                } else {
                    let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                    failure?(error)
                    //self.searchJwtToken = ""
                    SDKConfiguration.botConfig.customJWToken = ""
                }
            }
        }
            
    }
    
    public func getSearchResultsOld(_ text: String!, success:((_ dictionary: [String: Any]) -> Void)?, failure:((_ error: Error) -> Void)?) {
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

extension SearchConnect{
    public func getJwTokenWithClientId(botConfig:[String:Any]?, success:((_ jwToken: String?) -> Void)?, failure:((_ error: Error) -> Void)?) {
        if let configDetails = botConfig{
            guard let botId = configDetails["botId"] as? String else{
                        return
            }
            guard let retail_server_url = configDetails["retail_server_url"] as? String else{
                      return
            }
            guard let stage = configDetails["stage"] as? String else{
                      return
            }
            searchBotConfig = configDetails
            let urlString =  "\(retail_server_url)auth/token"
            let headers: HTTPHeaders = [
                "stage": stage
            ]
            let parameters: [String: Any] = ["botId": botId as String]
            let dataRequest = sessionManager.request(urlString, method: .post, parameters: parameters, headers: headers)
            dataRequest.validate().responseJSON { (response) in
                if let _ = response.error {
                    let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                    failure?(error)
                    self.searchAccessToken = ""
                    return
                }
                if let dictionary = response.value as? [String: Any],
                   let accessToken = dictionary["accessToken"] as? String {
                    self.searchAccessToken = accessToken
                    if let accessTokenType = dictionary["type"] as? String {
                        self.searchAccessTokenType = accessTokenType
                    }
                    success?(accessToken)
                } else {
                    let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                    failure?(error)
                    self.searchAccessToken = ""
                }
            }
        }
        
        
    }
    
    public func classifyQueryApi(_ text: String!, success:((_ dictionary: [String: Any]) -> Void)?, failure:((_ error: Error) -> Void)?) {
        let configDetails = searchBotConfig
        guard let retail_server_url = configDetails["retail_server_url"] as? String else{
                  return
        }
        guard let indexName = configDetails["indexName"] as? String else{
                  return
        }
        guard let namespace = configDetails["namespace"] as? String else{
                  return
        }
        guard let stage = configDetails["stage"] as? String else{
                  return
        }
        let urlString =  "\(retail_server_url)semanticSearch/v2/cx/classifyQuery"
        let authorizationToken = "\(self.searchAccessTokenType) \(self.searchAccessToken)"
        let headers: HTTPHeaders = [
            "stage": stage,
            "Authorization": authorizationToken
        ]
        let parameters: [String: Any]  = ["query": text ?? "", "sessionId": self.searchAccessToken, "indexName": indexName, "namespace": namespace]
        
        let dataRequest = sessionManager.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        dataRequest.validate().responseJSON { (response) in
            if let _ = response.error {
                let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                failure?(error)
                return
            }
            
            if let dictionary = response.value as? [String: Any]{
                self.processQueryApi(text) { searchDic in
                    //print(searchDic)
                    success?(searchDic)
                } failure: { error in
                    failure?(error)
                }
            } else {
                let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                    failure?(error)
            }
        }
    }
    
    public func processQueryApi(_ text: String?, success:((_ dictionary: [String: Any]) -> Void)?, failure:((_ error: Error) -> Void)?) {
        let configDetails = searchBotConfig
        guard let retail_server_url = configDetails["retail_server_url"] as? String else{
                  return
        }
        guard let indexName = configDetails["indexName"] as? String else{
                  return
        }
        guard let namespace = configDetails["namespace"] as? String else{
                  return
        }
        guard let stage = configDetails["stage"] as? String else{
                  return
        }
        let urlString =  "\(retail_server_url)semanticSearch/v2/cx/processQuery"
        let authorizationToken = "\(self.searchAccessTokenType) \(self.searchAccessToken)"
        let headers: HTTPHeaders = [
            "stage": stage,
            "Authorization": authorizationToken
        ]
        let metaFilterKeys = ["gender","price","description"]
        
        let priceDic = ["operator":"arithmetic"]
        let genderDic = ["operator":""]
        let metaOptionsDic = ["price":priceDic, "gender":genderDic]
        let metaOptions = NSMutableArray()
        metaOptions.add(metaOptionsDic)
        let parameters: [String: Any]  = ["sessionId": self.searchAccessToken, "indexName": indexName, "namespace": namespace, "metaFilterKeys" : metaFilterKeys, "metaOptions": metaOptions]
        
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
}
