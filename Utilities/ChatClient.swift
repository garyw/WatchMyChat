//
//  ChatClient.swift
//  WatchMyChat
//
//  Created by Gary Waliczek on 2/22/18.
//  Copyright © 2018 Gary Waliczek. All rights reserved.
//

import Foundation
import Starscream

public class ChatClient : NSObject
{
    var endpoints : [String]
    var currentEndpoint : Int = 0
    //var manager : SocketManager
    var socket : WebSocket
    var messageId : Int = 0
    
    private override init() {
        self.endpoints = []
        let url = Url("wss://mixer.com")
        let req = URLRequest(url: url)
        self.socket = WebSocket(request: req)
        super.init()
    }
    
    public init(endpointList : [String]) {
        self.endpoints = endpointList
        self.currentEndpoint = Int(arc4random() % UInt32(endpoints.count))
        let socketUrl = URL(string:endpoints[currentEndpoint])!
        //var config : SocketIOClientConfiguration = []
        
        config.insert(.secure(true))
        config.insert(.forceWebsockets(true))
        config.insert(.log(true))
        
        var req = URLRequest(url: urlWebSocketWithSid)
        
        addHeaders(to: &req)
        
        ws = WebSocket(request: req)
        ws?.callbackQueue = engineQueue
        ws?.enableCompression = compress
        ws?.delegate = self
        ws?.disableSSLCertValidation = selfSigned
        ws?.security = security?.security
        
        //ws?.connect()
        
        self.manager = SocketManager(socketURL:socketUrl, config: config)
        self.socket = SocketIOClient(manager: manager, nsp: endpoints[currentEndpoint])
        super.init()
    }
    
    public func connect()
    {
        self.socket = SocketIOClient(manager: manager, nsp: endpoints[currentEndpoint])
        socket.connect()
        socket.on("WelcomeEvent", callback: { (message, ack) -> Void in
            print(message)
            self.SendAuthPacket()
            }
        )
    }
    
    public func disconnect()
    {
        socket.disconnect()
    }
    
    private func SendAuthPacket()
    {
        let authParams : [Any] = [ UserDefaults.standard.integer(forKey: "channelId"), UserDefaults.standard.integer(forKey:"mixerId"), UserDefaults.standard.string(forKey: "chatAuthkey")! ]
        
        var authMessage = [String:Any]()
        authMessage["type"] = "method"
        authMessage["method"] = "auth"
        authMessage["arguments"] = authParams
        authMessage["id"] = messageId
        messageId += 1
        
        let jsonData = try! JSONSerialization.data(withJSONObject: authMessage)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        socket.emit("auth", jsonString)
        socket.onAny({ (message) -> Void in
            print(message)
            }
        )
    }
}
