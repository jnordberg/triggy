//
//  Client.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-26.
//  Copyright © 2016 FFFF00 Agents AB. All rights reserved.
//
//  Triggy is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Triggy is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Triggy.  If not, see <http://www.gnu.org/licenses/>.
//

import Dispatch
import Foundation
import Socket
import os.log

public enum PTPError: Error {
    case General(message: String)
    case NotConnected
    case TimedOut(message: String)
    case InvalidPacket(message: String, type: PTPPacketType)
    case OperationError(message: String, code: PTPResponseCode)
    case ReadError(message: String)
}

public enum PTPPacketType: UInt32 {
    case Invalid                = 0
    case InitCommandRequest     = 1
    case InitCommandAck         = 2
    case InitEventRequest       = 3
    case InitEventAck           = 4
    case InitFail               = 5
    case OperationRequest       = 6
    case OperationResponse      = 7
    case Event                  = 8
    case StartDataPacket        = 9
    case DataPacket             = 10
    case CancelTransaction      = 11
    case EndDataPacket          = 12
    case Ping                   = 13
    case Pong                   = 14
}

extension PTPPacketType {
    static func typeFor(_ data: inout Data) -> PTPPacketType {
        return PTPPacketType(rawValue: data.getLittleEndian(start: 4)) ?? .Invalid
    }
}

struct PTPVersion: CustomStringConvertible {
    let rawValue: UInt32
    var minor: UInt32 { return rawValue & 0xffff }
    var major: UInt32 { return (rawValue & 0xffff0000) >> 16 }
    var description: String { return "\(major).\(minor)" }
}

protocol PTPPacket {
    static var type: PTPPacketType { get }
    var payload: Data { get }
    init(payload: Data)
}

extension PTPPacket {
    
    var length: UInt32 {
        return UInt32(payload.count + 8)
    }
    
    var data: Data {
        var rv = Data()
        rv.append(littleEndian: length)
        rv.append(littleEndian: Self.type.rawValue)
        rv.append(payload)
        return rv
    }
    
    static func from(_ packet: inout Data) throws -> Self {
        if packet.count < 8 {
            throw PTPError.InvalidPacket(message: "Too small", type: .Invalid)
        }
        let type = PTPPacketType.typeFor(&packet)
        if type == .Invalid {
            throw PTPError.InvalidPacket(message: "Invalid type", type: type)
        }
        if type != Self.type {
            throw PTPError.InvalidPacket(message: "Type mismatch, expected: \(Self.type), got: \(type)", type: type)
        }
        let length = Int(packet.getLittleEndian(start: 0) as Int32)
        if length != packet.count {
            throw PTPError.InvalidPacket(message: "Size mismatch, expected: \(length), got: \(packet.count)", type: type)
        }
        let payload = packet.subdata(in: 8..<length)
        return Self(payload: payload)
    }
    
}

struct InitCommandRequest : PTPPacket {
    static let type = PTPPacketType.InitCommandRequest
    let payload: Data
    var guid: Data { return payload.subdata(in: 0..<16) }
    var hostname: String {return payload.subdata(in: 16..<data.count-4).asciiValue }
    var version: PTPVersion { return PTPVersion(rawValue: payload.getLittleEndian(start: payload.count-4)) }
}

extension InitCommandRequest {
    init(hostname: String, guid: Data) {
        var d = Data()
        assert(guid.count == 16, "GUID data must be 16 bytes")
        d.append(guid)
        d.append(unicode16: hostname)
        d.append(littleEndian: Int16.allZeros) // hostname terminator
        d.append(littleEndian: Int32(65536)) // version 1.0
        payload = d
    }
}

struct InitCommandAck: PTPPacket {
    static let type = PTPPacketType.InitCommandAck
    let payload: Data
    var sessionId: UInt32 { return payload.getLittleEndian(start: 0) }
    var guid: Data { return payload.subdata(in: 4..<20) }
    var hostname: String { return payload.subdata(in: 20..<data.count-4).asciiValue }
    var version: PTPVersion { return PTPVersion(rawValue: payload.getLittleEndian(start: payload.count-4)) }
}

struct InitEventRequest: PTPPacket {
    static let type = PTPPacketType.InitEventRequest
    let payload: Data
    var sessionId: UInt32 { return payload.getLittleEndian(start: 0) }
}

extension InitEventRequest {
    init(sessionId: UInt32) {
        var d = Data()
        d.append(littleEndian: sessionId)
        payload = d
    }
}

struct InitEventAck: PTPPacket {
    static let type = PTPPacketType.InitEventAck
    let payload: Data
}

struct OperationRequest : PTPPacket {
    init(payload: Data) {
        self.payload = payload
    }
    static let type = PTPPacketType.OperationRequest
    let payload: Data
    var phaseInfo: UInt32 { return payload.getLittleEndian(start: 0) }
    var code: PTPOperationCode {
        return PTPOperationCode(rawValue: payload.getLittleEndian(start: 4)) ?? .Unknown
    }
    var id: UInt32 { return payload.getLittleEndian(start: 6) }
    var requestPayload: Data?
}

extension OperationRequest {
    init(code: PTPOperationCode, id: UInt32, arguments: [PTPArgument] = [], phaseInfo: UInt32 = 1) {
        var d = Data()
        d.append(littleEndian: phaseInfo)
        d.append(littleEndian: code.rawValue)
        d.append(littleEndian: id)
        for argument in arguments {
            d.append(littleEndian: argument.argumentValue)
        }
        payload = d
    }
}

struct OperationResponse: PTPPacket {
    static let type = PTPPacketType.OperationResponse
    let payload: Data
    var code: PTPResponseCode {
        return PTPResponseCode(rawValue: payload.getLittleEndian(start: 0)) ?? .Unknown
    }
    var id: UInt32 { return payload.getLittleEndian(start: 2) }
}

struct StartData: PTPPacket {
    static let type = PTPPacketType.StartDataPacket
    let payload: Data
    var id: UInt32 { return payload.getLittleEndian(start: 0) }
    var dataLength: UInt64 { return payload.getLittleEndian(start: 4) }
}

extension StartData {
    init(id: UInt32, dataLength: UInt64) {
        var d = Data()
        d.append(littleEndian: id)
        d.append(littleEndian: dataLength)
        payload = d
    }
}

struct EndData: PTPPacket {
    static let type = PTPPacketType.EndDataPacket
    let payload: Data
    var id: UInt32 { return payload.getLittleEndian(start: 0) }
    var payloadData: Data { return payload.subdata(in: 4..<payload.count) }
}

extension EndData {
    init(id: UInt32, payloadData: Data) {
        var d = Data()
        d.append(littleEndian: id)
        d.append(payloadData)
        payload = d
    }
}

struct Ping: PTPPacket {
    static let type = PTPPacketType.Ping
    let payload: Data
}

struct Pong: PTPPacket {
    static let type = PTPPacketType.Pong
    let payload: Data
}

public protocol PTPClientDelegate {
    func clientWaitingForCamera(_ client: PTPClient)
    func clientDisconnected(_ client: PTPClient, withError error: Error?)
    func client(_ client: PTPClient, receivedEvent event: PTPEvent)
}

func configureSocket(_ fd: Int32, withTimeout tv_sec: Int) throws {

    if tv_sec > 0 {
        var tv = timeval()
        tv.tv_sec = tv_sec
        if setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size)) < 0 {
            let errmsg = String(cString: strerror(errno))
            throw PTPError.General(message: "Unable to set socket timeout: \(errmsg)")
        }
    }

    var on = 1
    if setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &on, socklen_t(MemoryLayout<Int>.size)) < 0 {
        let errmsg = String(cString: strerror(errno))
        throw PTPError.General(message: "Unable to set socket keepalive: \(errmsg)")
    }
    
    var delay = 30
    if setsockopt(fd, IPPROTO_TCP, TCP_KEEPALIVE, &delay, socklen_t(MemoryLayout<Int>.size)) < 0 {
        let errmsg = String(cString: strerror(errno))
        throw PTPError.General(message: "Unable to set socket keepalive delay: \(errmsg)")
    }
    
    if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &on, socklen_t(MemoryLayout<Int>.size)) < 0) {
        let errmsg = String(cString: strerror(errno))
        throw PTPError.General(message: "Unable to set TCP_NODELAY: \(errmsg)")
    }
    
    if (setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int>.size)) < 0) {
        let errmsg = String(cString: strerror(errno))
        throw PTPError.General(message: "Unable to set SO_NOSIGPIPE: \(errmsg)")
    }
}

enum SocketError : Error {
    case ReadFail(message: String)
    case Disconnected(message: String, errno: Int32)
}

func readData(socket: Int32, len: Int) throws -> Data {
    let ptr: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
    var totalRead = 0
    let chunkSize = 1500
    while totalRead < len {
        let toRead = min(chunkSize, len - totalRead)
        let bytesRead = recv(socket, ptr.advanced(by: totalRead), toRead, MSG_WAITALL)
        if bytesRead == -1 {
            let errmsg = String(cString: strerror(errno))
            throw SocketError.Disconnected(message: errmsg, errno: errno)
        }
        totalRead += bytesRead
    }
    return Data(buffer: UnsafeMutableBufferPointer(start: ptr, count: len))
}

func readPacket(_ socket: Int32) throws -> Data {
    var lengthData = try readData(socket: socket, len: 4)
    let packetLen = lengthData.getLittleEndian(start: 0) as UInt32
    let packetData = try readData(socket: socket, len: Int(packetLen - 4))
    lengthData.append(packetData)
    return lengthData
}

public class PTPClient {

    private static let log = OSLog(subsystem: "com.yellowagents.ptp", category: "PTPClient")

    public typealias OperationCallback = (Data?, Error?) -> Void
    public typealias ConnectCallback = (Error?) -> Void
    
    public internal(set) var isConnected: Bool = false
    
    public var hostname = "SwiftyPTP"
    public var guid = Data(hexEncoded: "ffffffffffffffffffffffffffffffff")
    public var delegate: PTPClientDelegate?
    public var delegateQueue = DispatchQueue.main
    
    var transactionCounter: UInt32 = 0
    
    let commandQueue: DispatchQueue
    let eventQueue: DispatchQueue
    
    var commandSocket: Socket?
    var eventSocket: Socket?
    
    /// Command timeout in seconds
    public let timeout: Int
    
    public init(timeout seconds: Int = 10, qos: DispatchQoS = .userInteractive) {
        timeout = seconds
        commandQueue = DispatchQueue(label: "com.yellowagents.ptp-command", qos: qos)
        eventQueue = DispatchQueue(label: "com.yellowagents.ptp-event", qos: qos)
    }
    
    deinit {
        disconnect()
    }
    
    func _send(request: OperationRequest) throws -> Data? {
        if isConnected == false && request.code != .OpenSession {
            throw PTPError.NotConnected
        }
        guard let socket = commandSocket else {
            throw PTPError.NotConnected
        }
        
        let requestData = request.data
        let bytesWritten = try socket.write(from: requestData)
        
        assert(bytesWritten == requestData.count)
        
        if let dataPayload = request.requestPayload {
            // send start data + end data with payload, this is how my 750d does it, not sure what the spec says
            let startPacket = StartData(id: request.id, dataLength: UInt64(dataPayload.count))
            let endPacket = EndData(id: request.id, payloadData: dataPayload)
            try socket.write(from: startPacket.data)
            try socket.write(from: endPacket.data)
        }
        
        var responseData = try readPacket(socket.socketfd)
        
        func validateOperationResponse() throws {
            let response = try OperationResponse.from(&responseData)
            if response.id != request.id {
                throw PTPError.OperationError(message: "Transaction id mismatch, expected: \(request.id), got: \(response.id)", code: response.code)
            }
            if response.code != .OK {
                throw PTPError.OperationError(message: "Unexpected response code", code: response.code)
            }
        }
        
        let type = PTPPacketType.typeFor(&responseData)
        switch type {
        case .OperationResponse:
            try validateOperationResponse()
            return nil
        case .StartDataPacket:
            let startPacket = try StartData.from(&responseData)
            let size = Int(startPacket.dataLength)
            var data = Data()
            // TODO: this could probably be done more efficient
            repeat {
                let dataPacket = try readData(socket: socket.socketfd, len: 12)
                var b = BinaryData(dataPacket)
                let len: UInt32 = try b.read() - 12
//                let type: UInt32 = try b.read()
//                let txid: UInt32 = try b.read()
                data.append(try readData(socket: socket.socketfd, len: Int(len)))
            } while data.count < size

            responseData = try readPacket(socket.socketfd)
            try validateOperationResponse()
            
            return data
        default:
            throw PTPError.InvalidPacket(message: "Unexpected packet type: \(type)", type: type)
        }
    }
    
    func send(request: OperationRequest, completion: @escaping OperationCallback) {
        commandQueue.async { [weak self] in
            do {
                guard let client = self else { return }
                let data = try client._send(request: request)
                self?.delegateQueue.async {
                    completion(data, nil)
                }
            } catch let error {
                switch error {
                case is Socket.Error, PTPError.TimedOut, SocketError.Disconnected:
                    self?.disconnect(error)
                default:
                    break
                }
                self?.delegateQueue.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    func blockingSend(request: OperationRequest) throws -> Data? {
        return try commandQueue.sync { (Void) -> Data? in
            return try _send(request: request)
        }
    }
    
    public func send(code: PTPOperationCode, arguments: [PTPArgument] = [], data: Data? = nil, completion: @escaping OperationCallback) {
        var request = OperationRequest(code: code, id: transactionCounter, arguments: arguments)
        request.requestPayload = data
        transactionCounter += 1
        send(request: request, completion: completion)
    }
    
    @discardableResult
    public func blockingSend(code: PTPOperationCode, arguments: [PTPArgument] = [], data: Data? = nil) throws -> Data? {
        var request = OperationRequest(code: code, id: transactionCounter, arguments: arguments)
        request.requestPayload = data
        transactionCounter += 1
        return try blockingSend(request: request)
    }
    
    func _connect(to host: String, onPort port: Int32 = 15740) throws {
        let commandSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        self.commandSocket = commandSocket
        
        try configureSocket(commandSocket.socketfd, withTimeout: timeout)
        
        try commandSocket.connect(to: host, port: port)
        
        // send init command request
        let initRequest = InitCommandRequest(hostname: hostname, guid: guid)
        try commandSocket.write(from: initRequest.data)
        
        delegateQueue.async { [weak self] in
            if let client = self, let delegate = client.delegate { delegate.clientWaitingForCamera(client) }
        }
        
        // increase timeout while waiting for camera ack
        try configureSocket(commandSocket.socketfd, withTimeout: 0)
        
        // read init command response
        var initResponseData = try readPacket(commandSocket.socketfd)
        let initAck = try InitCommandAck.from(&initResponseData)
        
        // set standard timeout after init ack
        try configureSocket(commandSocket.socketfd, withTimeout: timeout)
        
        // connect to event socket
        let eventSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        self.eventSocket = eventSocket
        
        try eventSocket.connect(to: host, port: port)
        
        try configureSocket(eventSocket.socketfd, withTimeout: 0)
        
        // send event socket start request
        let eventRequest = InitEventRequest(sessionId: initAck.sessionId)
        try eventSocket.write(from: eventRequest.data)
        
        var eventResponseData = try readPacket(eventSocket.socketfd)
        _ = try InitEventAck.from(&eventResponseData) // just validate response
        
        let openRequest = OperationRequest(code: .OpenSession, id: transactionCounter, arguments: [initAck.sessionId])
        transactionCounter += 1
        _ = try _send(request: openRequest)
        
        isConnected = true
        
        eventQueue.async { [weak self] in
            repeat {
                do {
                    guard let socket = self?.eventSocket?.socketfd else {
                        return
                    }
                    let data = try readPacket(socket)
                    let event = try PTPEvent(data)
                    self?.delegateQueue.async {
                        if let client = self {
                            client.delegate?.client(client, receivedEvent: event)
                        }
                    }
                } catch let error {
                    os_log("Event error: %{public}@", log: PTPClient.log, type: .error, String(describing: error))
                    self?.commandQueue.async { [weak self] in
                        self?.disconnect(error)
                    }

                }
            } while self?.isConnected ?? false
        }
    }
    
    public func blockingConnect(to host: String, onPort port: Int32 = 15740) throws {
        try commandQueue.sync {
            try self._connect(to: host, onPort: port)
        }
    }
    
    public func connect(to host: String, onPort port: Int32 = 15740, completion: @escaping ConnectCallback) {
        commandQueue.async {
            do {
                try self._connect(to: host, onPort: port)
                completion(nil)
            } catch {
                self.delegateQueue.async {
                    completion(error)
                }
            }
        }
    }
    
    public func disconnect(_ error: Error? = nil) {
        eventSocket?.close()
        commandSocket?.close()
        eventSocket = nil
        commandSocket = nil
        guard isConnected else { return }
        isConnected = false
        delegateQueue.async { [weak self] in
            if let client = self {
                client.delegate?.clientDisconnected(client, withError: error)
            }
        }
    }
    
}
