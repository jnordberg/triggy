//
//  SoundPlayer.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-30.
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
import AVFoundation


class Sound : Equatable {
    
    let file: URL
    var buffer: AVAudioPCMBuffer?

    init(_ file: URL) {
        self.file = file
    }
    
    var filename: String {
        return file.lastPathComponent
    }
    
    lazy var title: String = {
        var title: String?
        let asset = AVAsset(url: self.file)
        for meta in asset.metadata {
            if meta.commonKey == "title" {
                title = meta.value as? String
                break
            }
        }
        return title ?? "N/A"
    }()

    func load() throws {
        if buffer != nil { return }
        let audioFile = try AVAudioFile(forReading: file)
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(audioFile.length)
        let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        try audioFile.read(into: audioFileBuffer)
        buffer = audioFileBuffer
    }
    
    public static func ==(lhs: Sound, rhs: Sound) -> Bool {
        return lhs.file == rhs.file
    }

}

final class SoundPlayer {
    
    enum Error: Swift.Error {
        case InvalidIndex
        case NoActiveBuffer
    }
    
    static let shared: SoundPlayer = {
        return SoundPlayer()
    }()
    
    let sounds: [Sound]
    var active: Sound?
    
    var audioEngine: AVAudioEngine = AVAudioEngine()
    var audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
    
    private init() {
        let paths = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: "Sounds").map { URL(fileURLWithPath: $0) }
        var sounds = paths.map { Sound($0) }
        sounds.sort { $1.filename > $0.filename }
        self.sounds = sounds
    }
    
    func activate(_ index: Int) throws {
        if index >= sounds.count {
            throw Error.InvalidIndex
        }
        
        active = sounds[index]
        try active!.load()
        
        if !audioEngine.isRunning {
            let mainMixer = audioEngine.mainMixerNode
            audioEngine.attach(audioFilePlayer)
            audioEngine.connect(audioFilePlayer, to: mainMixer, format: active!.buffer?.format)
            try audioEngine.start()
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
        } catch let error {
            print("WARNING: Unable to activate shared audio session", error)
        }
    }
    
    func deactivate() {
        if active == nil { return }
        active = nil
        audioFilePlayer.stop()
        audioEngine.stop()
        audioEngine.detach(audioFilePlayer)
        do {
            try AVAudioSession.sharedInstance().setActive(false, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
        } catch let error {
            print("WARNING: Unable to deactivate shared audio session", error)
        }
    }

    func play() throws {
        guard let buffer = active?.buffer else {
            throw Error.NoActiveBuffer
        }
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        audioFilePlayer.stop()
        audioFilePlayer.play()
        audioFilePlayer.scheduleBuffer(buffer, completionHandler: nil)
    }
    
}
