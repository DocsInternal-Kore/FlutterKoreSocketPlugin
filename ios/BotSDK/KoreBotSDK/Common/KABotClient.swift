//
//  KABotClient.swift
//  KoraApp
//
//  Created by Srinivas Vasadi on 29/01/18.
//  Copyright © 2018 Srinivas Vasadi. All rights reserved.
//

import UIKit
import ObjectMapper
import Alamofire

public protocol KABotClientDelegate: NSObjectProtocol {
    func botConnection(with connectionState: BotClientConnectionState)
    func showTypingStatusForBot()
}

open class KABotClient: NSObject {
    // MARK:- shared instance
    fileprivate var isConnected: Bool = false {
        didSet {
            if isConnected {
                //fetchMessages()
            }
        }
    }
    fileprivate var isConnecting: Bool = false
    private static var client: KABotClient!
    fileprivate var retryCount = 0
    fileprivate(set) var maxRetryAttempts = 5
    fileprivate var botClientQueue = DispatchQueue(label: "com.kora.botclient")
    
    var historyRequestInProgress: Bool = false
    private static var instance: KABotClient!
    static let shared: KABotClient = {
        if (instance == nil) {
            instance = KABotClient()
        }
        return instance
    }()
    
    
    let defaultTimeDifference = 15
    
    // properties
    public static var suggestions: NSMutableOrderedSet = NSMutableOrderedSet()
    private var botClient: BotClient = BotClient()
    
    public var identity: String!
    public var userId: String!
    public var streamId: String = ""
    let sessionManager: Session = {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 30
        return Session(configuration: configuration)
    }()
    
    public var connectionState: BotClientConnectionState! {
        get {
            return botClient.connectionState
        }
    }
    open weak var delegate: KABotClientDelegate?
    
    // MARK: - init
    public override init() {
        super.init()
        configureBotClient()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - fetch messages
    func fetchMessages(completion block: ((Bool) -> Void)? = nil) {
        let limit = 10
        self.getMessages(offset: 0, limit: limit + 1, completion:{ (success) in
            if success {
                //self.reconnectStatus(completion: block)
            } else {
                block?(false)
            }
        })
        
    }
    
    
    
    // MARK: - connect/reconnect - tries to reconnect the bot when isConnected is false
    @objc func tryConnect() {
        let delayInMilliSeconds = 250
        //let delayInSeconds = 2
        SDKConfiguration.botConfig.isReconnect = true
        botClientQueue.asyncAfter(deadline: .now() + .milliseconds(delayInMilliSeconds)) { [weak self] in
            if self?.isConnected == true {
                self?.retryCount = 0
            } else if let weakSelf = self {
                if weakSelf.isConnecting == false  {
                    weakSelf.isConnecting = true
                    weakSelf.isConnected = false
                    
                    if weakSelf.retryCount + 1 > weakSelf.maxRetryAttempts {
                        weakSelf.retryCount = 0
                    }
                    weakSelf.retryCount += 1
                    weakSelf.connect(block: {(client) in
//                        botConnectStatus = true
//                        let dic = ["event_code": "BotConnected", "event_message": "Bot connected successfully"]
//                        let jsonString = Utilities.stringFromJSONObject(object: dic)
//                        NotificationCenter.default.post(name: Notification.Name(tokenExipryNotification), object: jsonString)
                    }, failure:{(error) in
                        self?.isConnecting = false
                        self?.isConnected = false
                        if weakSelf.retryCount <= 4{
                            self?.tryConnect()
                        }else{
                            botConnectStatus = false
                            let dic = ["event_code": "Error_Socket", "event_message": "Unable to connect. Please try again later"]
                            let jsonString = Utilities.stringFromJSONObject(object: dic)
                            NotificationCenter.default.post(name: Notification.Name(tokenExipryNotification), object: jsonString)
                        }
                    })
                }
            }
        }
    }
    
    
    // MARK: -
    public func sendMessage(_ message: String, options: [String: Any]?, messageData: [String: Any]?) {
        botClient.sendMessage(message, options: options, messageData: messageData)
    }
    
    // methods
    func configureBotClient() {
        // events
        botClient.connectionWillOpen =  { [weak self] () in
            if let weakSelf = self {
                DispatchQueue.main.async {
                    weakSelf.delegate?.botConnection(with: weakSelf.connectionState)
                }
            }
        }
        
        botClient.connectionDidOpen = { [weak self] () in
            self?.isConnected = true
            self?.isConnecting = false
            
            DispatchQueue.main.async {
                for _ in 0..<notDeliverdMsgsArray.count{
                    self?.sendMessage(notDeliverdMsgsArray[0], options: nil)
                    notDeliverdMsgsArray.remove(at: 0)
                }
            }
        }
        
        botClient.connectionReady = {
            
        }
        
        botClient.connectionRetry = { [weak self] () in
            self?.isConnected = false
            self?.isConnecting = false
            
            if let weakSelf = self {
                DispatchQueue.main.async {
                    weakSelf.delegate?.botConnection(with: weakSelf.connectionState)
                }
            }
            self?.tryConnect()
        }
        botClient.connectionDidClose = { [weak self] (code, reason) in
            self?.isConnected = false
            self?.isConnecting = false
            
            if let weakSelf = self {
                DispatchQueue.main.async {
                    weakSelf.delegate?.botConnection(with: weakSelf.connectionState)
                }
            }
            self?.tryConnect()
            
        }
        
        botClient.connectionDidFailWithError = { [weak self] (error) in
            self?.isConnected = false
            self?.isConnecting = false
            
            if let weakSelf = self {
                DispatchQueue.main.async {
                    weakSelf.delegate?.botConnection(with: weakSelf.connectionState)
                }
            }
            if !botConnectStatus{
                let dic = ["event_code": "BotDisconnected", "event_message": "Bot disconnected"]
                let jsonString = Utilities.stringFromJSONObject(object: dic)
                NotificationCenter.default.post(name: Notification.Name(tokenExipryNotification), object: jsonString)
            }
            //self?.tryConnect() //kk
            
        }
        
        botClient.onMessage = { [weak self] (object) in
            let jsonString = Utilities.stringFromJSONObject(object: object ?? [:])
            NotificationCenter.default.post(name: Notification.Name(callbacksNotification), object: jsonString)
        }
        
        botClient.onMessageAck = { (ack) in
            
        }
        
        botClient.onUserMessageReceived = { [weak self] (object) in
            if let message = object["message"] as? [String:Any]{
                if let agentTyping = message["type"] as? String{
                    if agentTyping == "typing"{
                        NotificationCenter.default.post(name: Notification.Name("StartTyping"), object: nil)
                    }else{
                        NotificationCenter.default.post(name: Notification.Name("StopTyping"), object: nil)
                    }
                }
            }
        }
    }
    public func sendMessage(_ message: String, options: [String: Any]?) {
        botClient.sendMessage(message, options: options)
    }
    
    func deConfigureBotClient() {
        // events
        botConnectStatus = false
        botClient.disconnect()
//        botClient.connectionWillOpen = nil
//        botClient.connectionDidOpen = nil
//        botClient.connectionReady = nil
//        botClient.connectionDidClose = nil
//        botClient.connectionDidFailWithError = nil
//        botClient.onMessage = nil
//        botClient.onMessageAck = nil
//        botClient.onUserMessageReceived = nil
//        botClient.connectionRetry = nil
        
        let dic = ["event_code": "BotDisconnected", "event_message": "Bot disconnected"]
        let jsonString = Utilities.stringFromJSONObject(object: dic)
        NotificationCenter.default.post(name: Notification.Name(tokenExipryNotification), object: jsonString)
    }
    
    // MARK: -
    public func connect(block:((BotClient?) -> ())?, failure:((_ error: Error) -> Void)?){
        
        let clientId: String = SDKConfiguration.botConfig.clientId
        let clientSecret: String = SDKConfiguration.botConfig.clientSecret
        let isAnonymous: Bool = SDKConfiguration.botConfig.isAnonymous
        let chatBotName: String = SDKConfiguration.botConfig.chatBotName
        let botId: String = SDKConfiguration.botConfig.botId
        let isReconnect: Bool = SDKConfiguration.botConfig.isReconnect
        
        var identity: String! = nil
        if (isAnonymous) {
            identity = self.getUUID()
        } else {
            identity =  SDKConfiguration.botConfig.identity
        }
        //let botInfo: [String: Any] = ["chatBot": chatBotName, "taskBotId": botId, "customData": customData]
        //let botInfo: [String: Any] = ["chatBot": chatBotName, "taskBotId": botId]
        var botInfo: [String: Any] = [:]
        if SDKConfiguration.botConfig.customData.isEmpty{
            if  !updatedCustomData.isEmpty{
                var customData: [String: Any] = [:]
                for (key, value) in updatedCustomData{
                    customData[key] = value
                }
                botInfo = ["chatBot": chatBotName, "taskBotId": botId,"customData": customData]
            }else{
                botInfo = ["chatBot": chatBotName, "taskBotId": botId]
            }
        }else{
            var customData: [String: Any] = SDKConfiguration.botConfig.customData
            if  !updatedCustomData.isEmpty{
                    for (key, value) in updatedCustomData{
                        customData[key] = value
                    }
                }
            botInfo = ["chatBot": chatBotName, "taskBotId": botId,"customData": customData]
        }
        if SDKConfiguration.botConfig.customJWToken != ""{
            let jwToken =  SDKConfiguration.botConfig.customJWToken
            self.botClient.initialize(botInfoParameters: botInfo, customData: [:])
            if (SDKConfiguration.serverConfig.BOT_SERVER.count > 0) {
                self.botClient.setKoreBotServerUrl(url: SDKConfiguration.serverConfig.BOT_SERVER)
            }
            self.botClient.connectWithJwToken(jwToken, intermediary: { [weak self] (client) in
                self?.botClient.connect(isReconnect: isReconnect)
            }, success: { (client) in
                block?(nil)
            }, failure: { (error) in
                failure?(error!)
            })
        }else{
            self.getJwTokenWithClientId(clientId, clientSecret: clientSecret, identity: identity, isAnonymous: isAnonymous, success: { [weak self] (jwToken) in
                
                self?.botClient.initialize(botInfoParameters: botInfo, customData: [:])
                if (SDKConfiguration.serverConfig.BOT_SERVER.count > 0) {
                    self?.botClient.setKoreBotServerUrl(url: SDKConfiguration.serverConfig.BOT_SERVER)
                }
                self?.botClient.connectWithJwToken(jwToken, intermediary: { [weak self] (client) in
                    self?.botClient.connect(isReconnect: isReconnect)
                }, success: { (client) in
                    block?(nil)
                }, failure: { (error) in
                    failure?(error!)
                })
                
            }, failure: { (error) in
                print(error)
                failure?(error)
            })
        }
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
    
    // MARK: get JWT token request
    func getJwTokenWithClientId(_ clientId: String!, clientSecret: String!, identity: String!, isAnonymous: Bool!, success:((_ jwToken: String?) -> Void)?, failure:((_ error: Error) -> Void)?) {
        
        let urlString = SDKConfiguration.serverConfig.koreJwtUrl()
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
                return
            }
            
            if let dictionary = response.value as? [String: Any],
               let jwToken = dictionary["jwt"] as? String {
                SDKConfiguration.botConfig.customJWToken = jwToken
                success?(jwToken)
            } else {
                let error: NSError = NSError(domain: "bot", code: 100, userInfo: [:])
                failure?(error)
            }
            
        }
        
    }
    
    func request(with url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url) else {
            return request
        }
        
        request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
        return request
    }
    
    
    // MARK: - get history
    public func getMessages(offset: Int, limit: Int, completion block:((Bool) -> Void)?) {
        guard historyRequestInProgress == false else {
            return
        }
        //getHistory - fetch all the history that the bot has previously
        botClient.getHistory(offset: offset, limit: limit, success: { [weak self] (responseObj) in
            if let responseObject = responseObj as? [String: Any], let messages = responseObject["messages"] as? Array<[String: Any]>{
                print("History messges \(messages.count) \(messages)")
                let jsonString = Utilities.stringFromJSONObject(object: responseObject)
                NotificationCenter.default.post(name: Notification.Name(callbacksNotification), object: jsonString)
            }
            self?.historyRequestInProgress = false
            block?(true)
        }, failure: { [weak self] (error) in
            self?.historyRequestInProgress = false
            print("Unable to fetch messges \(error?.localizedDescription ?? "")")
            block?(false)
        })
    }
    
    // MARK: -
    public func setReachabilityStatusChange(_ status: NetworkReachabilityManager.NetworkReachabilityStatus) {
        botClient.setReachabilityStatusChange(status)
    }
}

// MARK: - UserDefaults Sign-In status
extension UserDefaults {
    func setKoraStartEventStatus(_ status: Bool, for identity: String) {
        set(status, forKey: identity)
        synchronize()
    }
    
    func koraStartEventStatus(for identity: String) -> Bool {
        return bool(forKey: identity)
    }
}
