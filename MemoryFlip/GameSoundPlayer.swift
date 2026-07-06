import AVFoundation

/// Central synthesized sound effects for the game — one distinct tone per Colour
/// Patterns tile (Simon-style), plus a shared success/failure feedback chime used
/// by the other modes. Tones are generated in-memory (no bundled audio assets).
final class GameSoundPlayer {
    static let shared = GameSoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private let tileBuffers: [AVAudioPCMBuffer]
    private let successBuffers: [AVAudioPCMBuffer]
    private let failureBuffer: AVAudioPCMBuffer

    // Green, red, yellow, blue — matches PatternBoardView's tile order.
    private static let tileFrequencies: [Double] = [329.63, 415.30, 277.18, 220.00]

    private init() {
        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        tileBuffers = Self.tileFrequencies.map {
            Self.makeToneBuffer(frequency: $0, sampleRate: sampleRate, duration: 0.16, format: format)
        }
        // Quick ascending two-note chime for a correct tap/match.
        successBuffers = [523.25, 783.99].map {
            Self.makeToneBuffer(frequency: $0, sampleRate: sampleRate, duration: 0.11, format: format)
        }
        // Low, slightly longer buzz for a wrong tap/mismatch.
        failureBuffer = Self.makeToneBuffer(frequency: 146.83, sampleRate: sampleRate, duration: 0.22, format: format)

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    /// Colour Patterns: distinct pitch per tile index, so the sequence can be followed by ear.
    func playTile(_ index: Int) {
        guard tileBuffers.indices.contains(index) else { return }
        playSequence([tileBuffers[index]])
    }

    /// Correct tap / match feedback, shared by the non-Pattern modes.
    func playSuccess() {
        playSequence(successBuffers)
    }

    /// Wrong tap / mismatch feedback, shared by the non-Pattern modes.
    func playFailure() {
        playSequence([failureBuffer])
    }

    private func playSequence(_ buffers: [AVAudioPCMBuffer]) {
        if !engine.isRunning { try? engine.start() }
        player.stop()
        for buffer in buffers {
            player.scheduleBuffer(buffer, at: nil)
        }
        player.play()
    }

    private static func makeToneBuffer(frequency: Double, sampleRate: Double, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let channel = buffer.floatChannelData![0]

        let attackFrames = Int(sampleRate * 0.01)
        let releaseStart = Int(frameCount) - Int(sampleRate * 0.05)
        for frame in 0..<Int(frameCount) {
            let sample = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
            var envelope = 1.0
            if frame < attackFrames {
                envelope = Double(frame) / Double(attackFrames)
            } else if frame > releaseStart {
                envelope = max(0, Double(Int(frameCount) - frame) / Double(Int(frameCount) - releaseStart))
            }
            channel[frame] = Float(sample * envelope * 0.3)
        }
        return buffer
    }
}
