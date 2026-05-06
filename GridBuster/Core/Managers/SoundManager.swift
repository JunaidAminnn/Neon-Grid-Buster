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
    private var colorBuffers: [NeonColor: [AVAudioPCMBuffer]] = [:]
    private var comboColorBuffers: [NeonColor: [AVAudioPCMBuffer]] = [:]
    private var placeBuffer:  AVAudioPCMBuffer?
    private var clickBuffer:  AVAudioPCMBuffer?
    private var gameOverBuffer: AVAudioPCMBuffer?
    private var winBuffer:     AVAudioPCMBuffer?
    
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

        // 8-voice polyphony pool for richer sound layering
        for _ in 0..<8 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            nodes.append(node)
        }

        // Render satisfying UI and gameplay utility sounds
        placeBuffer    = renderPop(format: format, isThud: true)
        clickBuffer    = renderPop(format: format, isThud: false)
        gameOverBuffer = renderGameOver(format: format)
        winBuffer      = renderWin(format: format)

        // Pre-render color-specific chimes for each NeonColor
        for color in NeonColor.allCases {
            var colorList: [AVAudioPCMBuffer] = []
            var comboList: [AVAudioPCMBuffer] = []
            
            let baseFreq = frequencyForColor(color)
            let semitone = pow(2.0, 1.0 / 12.0)
            
            // Render 5 pitch variations per color for variety
            for i in 0..<5 {
                let freq = baseFreq * pow(semitone, Double(i))
                
                // Regular Line Clear
                if let buf = renderChime(frequency: freq, duration: 0.8, isCombo: false, format: format, color: color) {
                    colorList.append(buf)
                }
                
                // Combo / Rich Arpeggio
                if let buf = renderChime(frequency: freq, duration: 2.0, isCombo: true, format: format, color: color) {
                    comboList.append(buf)
                }
            }
            
            colorBuffers[color] = colorList
            comboColorBuffers[color] = comboList
        }

        do {
            try engine.start()
            isReady = true
        } catch {
            print("[SoundManager] start failed: \(error)")
        }
    }
    
    private func frequencyForColor(_ color: NeonColor) -> Double {
        switch color {
        case .ice:    return 1046.50 // C6 (Crystal/Ice)
        case .cyan:   return 523.25  // C5 (Classic)
        case .pink:   return 659.25  // E5 (Sweet)
        case .lime:   return 783.99  // G5 (Energetic)
        case .yellow: return 587.33  // D5 (Warm)
        case .purple: return 440.00  // A4 (Deep/Royal)
        case .blue:   return 493.88  // B4 (Cool)
        case .orange: return 392.00  // G4 (Warm/Brass)
        case .red:    return 349.23  // F4 (Resonant/Heavy)
        }
    }

    /// Play the 'thud' when a block is placed on the grid.
    func playPlace() {
        guard isReady, let buf = placeBuffer else { return }
        playBuffer(buf)
    }
    
    /// Play a crisp UI click.
    func playClick() {
        guard isReady, let buf = clickBuffer else { return }
        playBuffer(buf)
    }
    
    /// Play a dramatic Game Over sound.
    func playGameOver() {
        guard isReady, let buf = gameOverBuffer else { return }
        playBuffer(buf)
    }
    
    /// Play a rewarding Win sound.
    func playWin() {
        guard isReady, let buf = winBuffer else { return }
        playBuffer(buf)
    }

    /// Play the tone for a line clear, optionally specific to a color.
    func playLineClear(comboLevel: Int, color: NeonColor? = nil) {
        guard isReady else { return }
        
        let targetColor = color ?? .cyan
        let buffers = (comboLevel > 1) ? comboColorBuffers[targetColor] : colorBuffers[targetColor]
        
        guard let buffers = buffers, !buffers.isEmpty else { return }
        
        // Pick variation based on combo level (climbing the scale)
        let idx = max(0, min(comboLevel - 1, buffers.count - 1))
        playBuffer(buffers[idx])
    }
    
    private func playBuffer(_ buffer: AVAudioPCMBuffer) {
        let node = nodes[slot % nodes.count]
        slot += 1
        node.stop()
        node.scheduleBuffer(buffer, completionHandler: nil)
        node.play()
    }

    private func renderPop(format: AVAudioFormat, isThud: Bool) -> AVAudioPCMBuffer? {
        let duration = isThud ? 0.08 : 0.04
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        let ch = buf.floatChannelData![0]
        
        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate
            let attack = min(1.0, t / (isThud ? 0.005 : 0.002))
            let decay  = exp(-t * (isThud ? 35.0 : 70.0))
            
            // Rapid pitch drop
            let baseFreq = isThud ? 180.0 : 750.0
            let dropRate = isThud ? 25.0 : 55.0
            let freq = baseFreq * exp(-t * dropRate)
            let wave = sin(2.0 * .pi * freq * t)
            
            // Texture noise (reduced for sweetness)
            let noise = (Double.random(in: -1...1) * (isThud ? 0.05 : 0.02))
            
            ch[f] = Float((wave + noise) * attack * decay * 0.40)
        }
        return buf
    }
    
    private func renderGameOver(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration = 1.8
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        let ch = buf.floatChannelData![0]
        
        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate
            let decay = exp(-t * 1.8)
            
            // Descending groan/thud
            let freq = 100.0 * exp(-t * 0.7)
            let wave = sin(2.0 * .pi * freq * t) * 0.5
            
            // Add a dissonant second layer
            let wave2 = sin(2.0 * .pi * (freq * 0.92) * t) * 0.3
            
            // Low rumble noise
            let noise = Double.random(in: -1...1) * 0.08 * exp(-t * 2.5)
            
            ch[f] = Float((wave + wave2 + noise) * decay * 0.45)
        }
        return buf
    }
    
    private func renderWin(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration = 2.5
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        let ch = buf.floatChannelData![0]
        
        let baseFreq = 523.25 // C5
        
        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate
            let decay = exp(-t * 1.2)
            let attack = min(1.0, t / 0.05)
            
            // Rising fanfare / arpeggio feel (simulated in one buffer)
            // We use a combination of frequencies that form a C major chord
            let f1 = baseFreq
            let f2 = baseFreq * 1.2599 // E5
            let f3 = baseFreq * 1.4983 // G5
            let f4 = baseFreq * 2.0    // C6
            
            let wave = (sin(2.0 * .pi * f1 * t) +
                        sin(2.0 * .pi * f2 * t) * 0.8 +
                        sin(2.0 * .pi * f3 * t) * 0.6 +
                        sin(2.0 * .pi * f4 * t) * 0.4) / 2.8
            
            // Add some "shimmer" vibrato
            let shimmer = 1.0 + 0.005 * sin(2.0 * .pi * 15.0 * t)
            
            ch[f] = Float(wave * attack * decay * 0.45 * shimmer)
        }
        return buf
    }
    
    private func renderChime(frequency: Double, duration: Double, isCombo: Bool, format: AVAudioFormat, color: NeonColor) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        let ch = buf.floatChannelData![0]
        
        // Color-specific characteristics
        let decayMod: Double
        let harmonicScale: Double
        
        switch color {
        case .ice, .cyan:
            decayMod = 3.2
            harmonicScale = 0.25
        case .pink:
            decayMod = 2.5
            harmonicScale = 0.40 // "Sweet" harmonics
        case .lime:
            decayMod = 4.5 // Sharp
            harmonicScale = 0.15
        case .purple, .blue:
            decayMod = 2.0 // Long resonance
            harmonicScale = 0.35
        case .orange, .yellow:
            decayMod = 2.8
            harmonicScale = 0.30
        case .red:
            decayMod = 1.8 // Heavy, slow decay
            harmonicScale = 0.50
        }
        
        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate
            
            // Warmer, softer attack for "premium" chimes
            let attack = min(1.0, t / 0.012)
            let decay  = exp(-t * (isCombo ? (decayMod * 0.6) : decayMod))
            
            // Subtle vibrato for "premium" feel
            let vibrato = 1.0 + (isCombo ? 0.004 : 0.002) * sin(2.0 * .pi * 5.0 * t)
            let fv = frequency * vibrato
            
            // Warm Sine Base
            let fund = sin(2.0 * .pi * fv * t)
            
            // Harmonically varied chimes
            let h2 = sin(2.0 * .pi * (fv * 2.0) * t) * (harmonicScale) * exp(-t * 6.0)
            let h3 = sin(2.0 * .pi * (fv * 3.0) * t) * (harmonicScale * 0.5) * exp(-t * 10.0)
            
            var wave = fund + h2 + h3
            
            if isCombo {
                // Harmonic richness for combos (Major chord)
                let third = sin(2.0 * .pi * (fv * 1.2599) * t) * 0.3 * exp(-t * 2.5)
                let fifth = sin(2.0 * .pi * (fv * 1.4983) * t) * 0.2 * exp(-t * 3.5)
                wave = (fund + third + fifth) * 0.75
                
                // Very subtle high shimmer
                let shimmer = sin(2.0 * .pi * (fv * 4.0) * t) * 0.08 * sin(2.0 * .pi * 12.0 * t)
                wave += shimmer
            }
            
            ch[f] = Float(wave * attack * decay * 0.38)
        }
        return buf
    }
}


