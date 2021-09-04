//
//  AdharaSocket.swift
//  adhara_socket_io
//
//  Created by soumya thatipamula on 19/11/18.
//

import Foundation


import Flutter
import UIKit
import SocketIO


public class AdharaSocket: NSObject, FlutterPlugin {
    
    let socket: SocketIOClient
    let channel: FlutterMethodChannel
    let manager: SocketManager
    let config: AdharaSocketIOClientConfig
    
    private func log(_ items: Any...){
        if(config.enableLogging){
            print(items)
        }
    }

    public init(_ channel:FlutterMethodChannel, _ config:AdharaSocketIOClientConfig) {
        manager = SocketManager(socketURL: URL(string: config.uri)!, config: [.log(true),.forceWebsockets(true),.path(config.path), .connectParams(config.query)])
        socket = manager.defaultSocket
        self.channel = channel
        self.config = config
    }

    public static func getInstance(_ registrar: FlutterPluginRegistrar, _ config:AdharaSocketIOClientConfig) ->  AdharaSocket{
        let channel = FlutterMethodChannel(name: "adhara_socket_io:socket:"+String(config.adharaId), binaryMessenger: registrar.messenger())
        let instance = AdharaSocket(channel, config)
        instance.log("initializing with URI", config.uri)
        registrar.addMethodCallDelegate(instance, channel: channel)
        return instance
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var arguments: [String: AnyObject]
        if(call.arguments != nil){
            arguments = call.arguments as! [String: AnyObject]
        }else{
            arguments = [String: AnyObject]()
        }
        switch call.method{
            case "connect":
                socket.connect()
                result(nil)
            case "on":
                let eventName: String = arguments["eventName"] as! String
                self.log("registering event:::", eventName)
                socket.on(eventName) {data, ack in
                    self.log("incoming:::", eventName, data, ack)
                    self.channel.invokeMethod("incoming", arguments: [
                        "eventName": eventName,
                        "args": data
                    ]);
                }
                result(nil)
            case "off":
                let eventName: String = arguments["eventName"] as! String
                self.log("un-registering event:::", eventName)
                socket.off(eventName);
                result(nil)
            case "emit":
                let eventName: String = arguments["eventName"] as! String
                let data: [Any] = arguments["arguments"] as! [Any]
                self.log("emitting:::", data, ":::to:::", eventName);
                socket.emit(eventName, with: data)
//                socket.emit(eventName, with: data)
                result(nil)
            case "isConnected":
                self.log("connected")
                result(socket.status == .connected)
            case "disconnect":
                self.log("dis-connected")
                socket.disconnect()
                result(nil)
            default:
                result(FlutterError(code: "404", message: "No such method", details: nil))
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        //        Do nothing...
    }
    
}

public class AdharaSocketIOClientConfig: NSObject{
    
    let adharaId:Int
    let uri:String
    public var query:[String:String]
    public var enableLogging:Bool
    public var path:String

    init(_ adharaId:Int, uri:String) {
        self.adharaId = adharaId
        self.uri = uri
        self.query = [String:String]()
        self.enableLogging = false
        self.path = String()
    }
    
}
