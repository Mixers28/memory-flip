import SwiftUI

// Colour Stroop. A colour-word is printed in a mismatched ink colour; tap the swatch
// matching the INK colour, not the word. A wrong tap or running out of time ends the run.
struct ColourStroopBoardView: View {
    @ObservedObject var model: GameModel

    private func color(_ paletteIndex: Int) -> Color {
        let c = GameModel.stroopPalette[paletteIndex]
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("Tap the INK colour")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("not the word")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }

            countdownBar

            Spacer()

            // The word: spells one colour, painted in another.
            Text(GameModel.stroopPalette[model.stroopWordIndex].name)
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .foregroundStyle(color(model.stroopInkIndex))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            // Colour swatches — tap the one matching the ink.
            let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: min(3, model.stroopOptions.count))
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(model.stroopOptions, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color(idx))
                        .frame(height: 64)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1.5))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture { model.tapStroopOption(idx) }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var countdownBar: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(model.stroopRoundStart)
            let progress = max(0, min(1, 1 - elapsed / model.stroopRoundDuration))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule()
                        .fill(progress > 0.4
                              ? Color(red: 0.3, green: 1.0, blue: 0.5)
                              : Color(red: 1.0, green: 0.35, blue: 0.3))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .frame(height: 8)
    }
}
