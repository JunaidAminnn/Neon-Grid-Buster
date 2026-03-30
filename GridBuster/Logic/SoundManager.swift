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

        // Pre-render 10 synth-marimba tones: base 523.25 Hz (C5), +1 semitone each step
        let baseFreq  = 523.25
        let semitone  = pow(2.0, 1.0 / 12.0)
        let frameCount = AVAudioFrameCount(sampleRate * 0.4) // longer tail

        for i in 0..<10 {
            let freq = baseFreq * pow(semitone, Double(i))
            guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { continue }
            buf.frameLength = frameCount
            let ch = buf.floatChannelData![0]
            for f in 0..<Int(frameCount) {
                let t = Double(f) / sampleRate
                let attack = min(1.0, t / 0.005)              // 5 ms attack
                let decay  = exp(-t * 6.0)                    // slower fundamental decay
                let harmonicDecay = exp(-t * 22.0)            // fast ping decay for harmonics

                let fundamental = sin(2.0 * .pi * freq * t)
                let harmonic2 = sin(2.0 * .pi * (freq * 2.0) * t) * 0.5 * harmonicDecay
                let harmonic3 = sin(2.0 * .pi * (freq * 3.0) * t) * 0.25 * harmonicDecay
                let harmonic4 = sin(2.0 * .pi * (freq * 4.0) * t) * 0.15 * harmonicDecay
                
                let wave = fundamental + harmonic2 + harmonic3 + harmonic4
                // Factor 0.35 to prevent clipping while keeping it bright
                ch[f] = Float(wave * attack * decay * 0.35)
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
