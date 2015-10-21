//
//  TwitchChatManager.swift
//  GamingStreamsTVApp
//
//  Created by Olivier Boucher on 2015-10-18.
//  Copyright © 2015 Rivus Media Inc. All rights reserved.
//

import Foundation

class TwitchChatManager {
    
    static func generateAnonymousIRCCredentials() -> IRCCredentials {
        let rnd = Int(arc4random_uniform(99999))
        return IRCCredentials(username: nil, password: nil, nick: "justinfan\(rnd)")
    }
    
    private var connection : IRCConnection?
    private var credentials : IRCCredentials?
    private var capabilities = IRCCapabilities(capabilities: ["twitch.tv/tags"])
    private var messageQueue : TwitchChatMessageQueue?
    private var emotesDictionnary = [String : NSData]() //Dictionnary that holds all the emotes (Acts as cache)
    private var consumer : TwitchChatConsumer?
    private var channel : TwitchChannel?
    
    init(consumer : TwitchChatConsumer) {
        self.consumer = consumer
        self.messageQueue = TwitchChatMessageQueue(delegate: self)
        connection = IRCConnection(delegate: self)

        //Command handlers
        connection!.commandHandlers["PRIVMSG"] = handleMsg
        connection!.commandHandlers["433"] = handle433
    }
    
    func connect() {
        if let token = TokenHelper.getTwitchToken(), username = TokenHelper.getTwitchUsername() {
            credentials = IRCCredentials(username: username, password: "oauth:\(token)", nick: username.lowercaseString)
        } else {
            
            credentials = TwitchChatManager.generateAnonymousIRCCredentials()
        }
        connection!.connect(IRCEndpoint(host: "irc.twitch.tv", port: 6667), credentials: credentials!, capabilities: capabilities)
    }
    
    func disconnect() {
        connection?.disconnect()
    }
    
    func joinTwitchChannel(channel : TwitchChannel) {
        self.channel = channel
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.connection?.sendStringMessage("JOIN #\(channel.name)", immedtiately: true)
        })
    }
    
    func sendMessage(message: String) {
        guard let _ = TokenHelper.getTwitchToken(), channel = self.channel else {
            return
        }
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.connection?.sendStringMessage("PRIVMSG #\(channel.name) :\(message)", immedtiately: true)
        })
    }
    
/////////////////////////////////////////
// MARK - Command handlers
/////////////////////////////////////////
    
    private func handleMsg(message : IRCMessage) -> () {
        guard let _ = message.sender as String! else {
            return
        }
        
        guard message.parameters.count == 2 else {
            return
        }
        
        messageQueue?.addNewMessage(message)
        print("Received: \(message)")
    }
    
    private func handle433(message : IRCMessage) -> () {
        print("Received 433")
    }
}

/////////////////////////////////////////
// MARK - TwitchChatMessageQueueDelegate
/////////////////////////////////////////

extension TwitchChatManager : TwitchChatMessageQueueDelegate {
    
    func handleProcessedAttributedString(message: NSAttributedString) {
        self.consumer!.messageReadyForDisplay(message)
    }
    func handleNewEmoteDownloaded(id: String, data : NSData) {
        emotesDictionnary[id] = data
    }
    func hasEmoteInCache(id: String) -> Bool {
        return self.emotesDictionnary[id] != nil
    }
    func getEmoteDataFromCache(id: String) -> NSData? {
        return self.emotesDictionnary[id]
    }
}

/////////////////////////////////////////
// MARK - IRCConnectionDelegate
/////////////////////////////////////////

extension TwitchChatManager : IRCConnectionDelegate {
    func IRCConnectionDidConnect() {
        print("DID CONNECT")
    }
    func IRCConnectionDidDisconnect() {
        print("DID DISCONNECT")
    }
    func IRCConnectionDidNotConnect() {
        print("DID NOT CONNECT")
    }
}