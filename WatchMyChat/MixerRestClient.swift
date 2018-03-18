//
//  MixerRestClient.swift
//  WatchMyChat
//
//  Created by Gary Waliczek on 2/20/18.
//  Copyright © 2018 Gary Waliczek. All rights reserved.
//

import Foundation
import OAuthSwift

public class MixerRest
{
    private static var instance : MixerRest? = nil
    
    private var cred: OAuthSwiftCredential? = nil
    
    public var chatEndpoints : [String] = []
    
    public var chatConnection : ChatClient = ChatClient(endpointList: ["http://mixer.com"])
    
    private var oauthClient : OAuth2Swift = OAuth2Swift(
        consumerKey:    "00dd436c3eaeedb39cbef172cd585d85f91957111d402de7",
        consumerSecret: "73560dd739e93890c214ae858ac273c8e47f79c870bbd24aa81ad3916fb4c8d0",
        authorizeUrl:   "https://mixer.com/oauth/authorize",
        accessTokenUrl: "https://mixer.com/api/v1/oauth/token",
        responseType:   "code"
    )
    
    public static var oauthUxParent : UIViewController? = nil
    
    public static func client() -> MixerRest
    {
        if let singleton = MixerRest.instance {
            return singleton
        }
        
        MixerRest.instance = MixerRest()
        return MixerRest.instance!
    }
    
    private init()
    {
        if let data = UserDefaults.standard.object(forKey: "oauthCredentials") as? NSData {
            if let creds = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? OAuthSwiftCredential {
                self.cred = creds
            }
        }
        
        validateToken()
    }
    
    public func validateToken()
    {
        if let viewController = MixerRest.oauthUxParent
        {
            if (cred == nil)
            {
                oauthClient.allowMissingStateCheck = true
                
                // Make safari the handler
                let urlHandler = SafariURLHandler(viewController: viewController, oauthSwift: oauthClient)
                
                oauthClient.authorizeURLHandler = urlHandler
                
                guard let rwURL = URL(string: "WatchMyChat://www.threedayweekend.solutions/oauth2Callback") else { return }
                
                // Run the authentication
                oauthClient.authorize(withCallbackURL: rwURL, scope: "chat:connect", state: "", success: {
                    (credential, response, parameters) in
                    self.onOauthTokenGranted(credential: credential, response: response, parameters: parameters)
                    self.readMixerUserId()
                }, failure: { (error) in
                    print(error.localizedDescription)
                })
            } else if (cred!.isTokenExpired()) {
                oauthClient.renewAccessToken(withRefreshToken: self.cred!.oauthRefreshToken, success:{
                    (credential, response, parameters) in
                    self.onOauthTokenGranted(credential: credential, response: response, parameters: parameters)
                    if (UserDefaults.standard.object(forKey: "channelId") == nil)
                    {
                        self.readMixerUserId()
                    }
                    else
                    {
                        self.readMixerChatInfo(channelId: UserDefaults.standard.object(forKey: "channelId") as! Int)
                    }
                }, failure: { (error) in
                    print(error.localizedDescription)
                })
            }
            else if (UserDefaults.standard.object(forKey: "channelId") == nil)
            {
                readMixerUserId()
            }
            else {
                readMixerChatInfo(channelId: UserDefaults.standard.object(forKey: "channelId") as! Int)
            }
        }
    }
    
    public func readMixerUserId()
    {
        let uri : String = "https://mixer.com/api/v1/users/current"
        
        _ = oauthClient.client.get(uri, parameters: [:], headers: nil, success: {
            (response) in
            
            print(response.dataString()!)

            if let json = try? response.jsonObject() {
                if let userDictionary = json as? [String : Any] {
                    if let userId = userDictionary["id"] as? Int {
                        UserDefaults.standard.set(userId, forKey: "mixerId")
                    }
                    
                    if let userName = userDictionary["username"] as? String {
                        UserDefaults.standard.set(userName, forKey: "mixerUserName")
                    }
                    
                    if let channelDictionary = userDictionary["channel"] as? [String : Any] {
                        if let channelId = channelDictionary["id"] as? Int {
                            UserDefaults.standard.set(channelId, forKey: "channelId")
                            self.readMixerChatInfo(channelId: channelId)
                        }
                    }
                }
            }
        }, failure: { (error) in
            print(error.localizedDescription)
        })
    }
    
    public func readMixerChatInfo(channelId: Int)
    {
        let uri : String = "https://mixer.com/api/v1/chats/\(channelId)"
        
        _ = oauthClient.client.get(uri, parameters: [:], headers: nil, success: {
            (response) in
            
            print(response.dataString()!)
            
            if let json = try? response.jsonObject() {
                if let chatDictionary = json as? [String : Any] {
                    if let authKey = chatDictionary["authkey"] as? String {
                        UserDefaults.standard.set(authKey, forKey: "chatAuthkey")
                    }
                    
                    if let endpoints = chatDictionary["endpoints"] as? [String] {
                        self.chatEndpoints = endpoints
                        UserDefaults.standard.set(endpoints, forKey: "chatEndpoints")
                        self.chatConnection = ChatClient(endpointList: endpoints)
                        self.chatConnection.connect()
                    }
                }
            }
        }, failure: { (error) in
            print(error.localizedDescription)
        })
    }
    
    private func onOauthTokenGranted(credential: OAuthSwiftCredential, response: OAuthSwiftResponse?, parameters: [String: Any]) -> Void
    {
        self.cred = credential
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: credential), forKey: "oauthCredentials")
    }
}
