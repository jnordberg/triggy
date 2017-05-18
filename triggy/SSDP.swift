//
//  SSDP.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-23.
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

import Foundation
import CocoaAsyncSocket

import os.log

enum SSDPError: Error {
    case InvalidServiceDescriptor
    case ParseError(message: String)
}

struct SSDPService {
    let host: String
    let port: UInt16
    let headers: [String: String]
}

protocol SSDPBrowserDelegate {
    func browser(_ browser: SSDPBrowser, didFindService service: SSDPService)
    func browser(_ browser: SSDPBrowser, didError error: Error)
}

let SSDPHeaderFormat = "M-SEARCH * HTTP/1.1\r\n" +
    "HOST: 239.255.255.250:1900\r\n" +
    "MAN: \"ssdp:discover\"\r\n" +
    "MX: 10\r\n" +
    "ST: %@\r\n" +
    "\r\n"

class SSDPBrowser: NSObject, GCDAsyncUdpSocketDelegate {

    static let log = OSLog(subsystem: App.id, category: "SSDP")

    // TODO: use BlueSocket and drop AsyncSocket as a dep
    var socket: GCDAsyncUdpSocket?
    var delegate: SSDPBrowserDelegate?
    var broadcastInterval: TimeInterval = 0.5

    public internal(set) var isBrowsing: Bool = false
    
    private var broadcastTimer: Timer?
    private var currentSt: String?

    deinit {
        stopBrowsing()
    }
    
    func beginBrowsing(forService st: String = "ssdp:all") throws {
        os_log("Begin browsing for: %@", log: SSDPBrowser.log, type: .info, st)

        socket = GCDAsyncUdpSocket()
        socket?.setDelegate(self, delegateQueue: DispatchQueue.main)
        try socket?.bind(toPort: 0)
        try socket?.enableBroadcast(true)
        try socket?.beginReceiving()

        guard let data = String(format: SSDPHeaderFormat, st).data(using: String.Encoding.ascii) else {
            throw SSDPError.InvalidServiceDescriptor
        }
        currentSt = st
        isBrowsing = true
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: broadcastInterval, repeats: true) { _ in
            self.socket?.send(data, toHost: "239.255.255.250", port: 1900, withTimeout: -1, tag: 1)
        }
        broadcastTimer?.fire()
    }
    
    func stopBrowsing() {
        os_log("Stop browsing", log: SSDPBrowser.log, type: .debug)
        isBrowsing = false
        broadcastTimer?.invalidate()
        socket?.close()
        socket = nil
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        if error != nil {
            delegate?.browser(self, didError: error!)
        }
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        if error != nil {
            delegate?.browser(self, didError: error!)
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        if error != nil {
            delegate?.browser(self, didError: error!)
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        guard let body = String(data: data, encoding: String.Encoding.ascii) else {
            delegate?.browser(self, didError: SSDPError.ParseError(message: "Got invalid response body"))
            return
        }
        
        let rawHeaders = body.components(separatedBy: "\r\n\r\n").first!
        let lines = rawHeaders.components(separatedBy: "\r\n").dropFirst()
        
        var headers = [String: String]()
        for line in lines {
            guard let r = line.range(of: ":") else {
                delegate?.browser(self, didError: SSDPError.ParseError(message: "Encountered invalid header: \(line)"))
                continue
            }
            let name = line.substring(to: r.lowerBound).lowercased()
            let value = line.substring(from: r.upperBound).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            headers[name] = value
        }
        
        let service = SSDPService(
            host: GCDAsyncUdpSocket.host(fromAddress: address)!,
            port: GCDAsyncUdpSocket.port(fromAddress: address),
            headers: headers
        )

        os_log("Got response from %@:%d", log: SSDPBrowser.log, type: .debug, service.host, service.port)

        var valid = false
        if let st = service.headers["st"] {
            valid = st == currentSt
        }
        
        if valid {
            delegate?.browser(self, didFindService: service)
        } else {
            os_log("WARNING: Got invalid service descriptor", log: SSDPBrowser.log, type: .error)
        }
    }
    
}

