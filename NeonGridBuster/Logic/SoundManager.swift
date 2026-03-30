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

        // Pre-render 10 sine-wave ping tones: base 880 Hz, +1 semitone each step
        let baseFreq  = 880.0
        let semitone  = pow(2.0, 1.0 / 12.0)
        let frameCount = AVAudioFrameCount(sampleRate * 0.22)

        for i in 0..<10 {
            let freq = baseFreq * pow(semitone, Double(i))
            guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { continue }
            buf.frameLength = frameCount
            let ch = buf.floatChannelData![0]
            for f in 0..<Int(frameCount) {
                let t = Double(f) / sampleRate
                let attack   = min(1.0, t / 0.004)          // 4 ms attack
                let decay    = exp(-t * 14.0)                // fast decay
                ch[f] = Float(sin(2.0 * .pi * freq * t)) * Float(attack * decay) * 0.55
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
