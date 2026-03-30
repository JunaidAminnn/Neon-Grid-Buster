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
    private var buffers:  [AVAudioPCMBuffer]  = []
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
        let frameCount = AVAudioFrameCount(sampleRate * 0.6) // longer ring for achievement feel

        for i in 0..<10 {
            let freq = baseFreq * pow(semitone, Double(i))
            guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { continue }
            buf.frameLength = frameCount
            let ch = buf.floatChannelData![0]
            
            for f in 0..<Int(frameCount) {
                let t = Double(f) / sampleRate
                
                // Achievement envelope: very sharp attack, long chime-like decay
                let attack = min(1.0, t / 0.003) // 3ms ultra-sharp attack
                let decay  = exp(-t * 4.5)       // slower decay for ringing effect
                
                // Add a little bit of "shimmer" with vibrato
                let vibrato = 1.0 + 0.003 * sin(2.0 * .pi * 8.0 * t)
                let fv = freq * vibrato
                
                // Layered harmonics for a "bell/chime" richness
                // Candy Crush sounds often have a strong 2nd and 3rd harmonic
                let fundamental = sin(2.0 * .pi * fv * t)
                let h2 = sin(2.0 * .pi * (fv * 2.0) * t) * 0.6 * exp(-t * 8.0)
                let h3 = sin(2.0 * .pi * (fv * 3.0) * t) * 0.4 * exp(-t * 12.0)
                let h4 = sin(2.0 * .pi * (fv * 4.0) * t) * 0.25 * exp(-t * 18.0)
                let h5 = sin(2.0 * .pi * (fv * 1.5) * t) * 0.15 * exp(-t * 22.0) // Fifth for "magical" chime coloring
                
                // Add a high-freq percussive "click" at the start
                let click = (f < 100) ? 0.3 * (Double.random(in: -1...1)) : 0
                
                let wave = fundamental + h2 + h3 + h4 + h5 + click
                
                // Gain 0.32 to avoid clipping with rich harmonics
                ch[f] = Float(wave * attack * decay * 0.32)
            }
            buffers.append(buf)
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
        let idx = max(0, min(comboLevel - 1, 9))
        guard idx < buffers.count else { return }
        let node = nodes[slot % nodes.count]
        slot += 1
        node.stop()
        node.scheduleBuffer(buffers[idx], completionHandler: nil)
        node.play()
    }
}
