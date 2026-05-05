//
//  SoundManager.swift
//  NeonGridBuster
//
//  Prompt 4.2 — 10 incremental ping tones, each one semitone higher.
//  Uses AVAudioEngine with pre-rendered sine-wave buffers (no audio files needed).
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private let engine    = AVAudioEngine()
    private var nodes:    [AVAudioPlayerNode] = []
    private var lineBuffers:  [AVAudioPCMBuffer]  = []
    private var comboBuffers: [AVAudioPCMBuffer]  = []
    private var slot      = 0
    private var isReady   = false

    private init() { setup() }

    private func setup() {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // 4-voice polyphony pool
        for _ in 0..<4 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            nodes.append(node)
        }

        // Pre-render 10 bright achievement chimes: base 523.25 Hz (C5), +1 semitone each step
        let baseFreq  = 523.25
        let semitone  = pow(2.0, 1.0 / 12.0)

        // Render regular Line Clear sounds (Inc. pings)
        for i in 0..<10 {
            let freq = baseFreq * pow(semitone, Double(i))
            guard let buf = renderChime(frequency: freq, duration: 0.5, format: format) else { continue }
            lineBuffers.append(buf)
        }
        
        // Render magical Combo sounds (Higher richness, longer ring)
        for i in 0..<10 {
            let freq = baseFreq * 1.5 * pow(semitone, Double(i)) // Start from a higher base (G5 approx)
            guard let buf = renderChime(frequency: freq, duration: 1.2, isCombo: true, format: format) else { continue }
            comboBuffers.append(buf)
        }

        do {
            try engine.start()
            isReady = true
        } catch {
            print("[SoundManager] start failed: \(error)")
        }
    }

    /// Play the tone for `comboLevel` (1-based, clamped to 1…10).
    func playLineClear(comboLevel: Int) {
        guard isReady else { return }
        let isHighCombo = comboLevel >= 3
        let buffers = isHighCombo ? comboBuffers : lineBuffers
        
        let idx = max(0, min(comboLevel - 1, 9))
        guard idx < buffers.count else { return }
        let node = nodes[slot % nodes.count]
        slot += 1
        node.stop()
        node.scheduleBuffer(buffers[idx], completionHandler: nil)
        node.play()
    }
    
    private func renderChime(frequency: Double, duration: Double, isCombo: Bool = false, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        let ch = buf.floatChannelData![0]
        
        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate
            let attack = min(1.0, t / 0.004)
            let decay  = exp(-t * (isCombo ? 2.5 : 5.0))
            
            let vibrato = 1.0 + (isCombo ? 0.005 : 0.002) * sin(2.0 * .pi * 6.0 * t)
            let fv = frequency * vibrato
            
            let fund = sin(2.0 * .pi * fv * t)
            let h2   = sin(2.0 * .pi * (fv * 2.0) * t) * 0.5 * exp(-t * 10.0)
            let h3   = sin(2.0 * .pi * (fv * 3.0) * t) * 0.3 * exp(-t * 15.0)
            let h4   = sin(2.0 * .pi * (fv * 4.0) * t) * 0.2 * exp(-t * 20.0)
            
            // Magical fifth harmonic for combos
            let fifth = isCombo ? sin(2.0 * .pi * (fv * 1.5) * t) * 0.4 * exp(-t * 5.0) : 0
            
            let wave = (fund + h2 + h3 + h4 + fifth)
            ch[f] = Float(wave * attack * decay * 0.35)
        }
        return buf
    }
}
