import SwiftUI

// Simon-style colour board. The model flashes a sequence (patternSequence);
// the player taps the tiles back in order. A wrong tap ends the run.
struct PatternBoardView: View {
    @ObservedObject var model: GameModel

    // Classic four-colour Simon palette. Index matches the tile index in the model.
    private let tiles: [PatternTile] = [
        PatternTile(dim: Color(red: 0.10, green: 0.42, blue: 0.20), lit: Color(red: 0.25, green: 1.0, blue: 0.45)),  // green
        PatternTile(dim: Color(red: 0.45, green: 0.10, blue: 0.14), lit: Color(red: 1.0, green: 0.30, blue: 0.38)),  // red
        PatternTile(dim: Color(red: 0.46, green: 0.38, blue: 0.08), lit: Color(red: 1.0, green: 0.86, blue: 0.25)),  // yellow
        PatternTile(dim: Color(red: 0.08, green: 0.28, blue: 0.50), lit: Color(red: 0.30, green: 0.70, blue: 1.0))   // blue
    ]

    var body: some View {
        VStack(spacing: 22) {
            statusBanner

            GeometryReader { geo in
                let gap: CGFloat = 14
                let side = (min(geo.size.width, geo.size.height) - gap) / 2
                let cols = [GridItem(.fixed(side), spacing: gap), GridItem(.fixed(side), spacing: gap)]

                LazyVGrid(columns: cols, spacing: gap) {
                    ForEach(tiles.indices, id: \.self) { i in
                        tileView(i)
                            .frame(width: side, height: side)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var statusBanner: some View {
        let watching = model.isPlayingBack
        return VStack(spacing: 4) {
            Text(watching ? "Watch the pattern" : "Repeat it!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(watching ? "Memorise the order" : "\(model.patternInputCount) / \(model.patternSequence.count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .animation(.easeInOut(duration: 0.2), value: watching)
    }

    private func tileView(_ i: Int) -> some View {
        let isLit = model.litTile == i
        let tile = tiles[i]
        return RoundedRectangle(cornerRadius: 20)
            .fill(isLit ? tile.lit : tile.dim)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(isLit ? 0.85 : 0.12), lineWidth: isLit ? 3 : 1.5)
            )
            .shadow(color: isLit ? tile.lit.opacity(0.7) : .clear, radius: 18)
            .scaleEffect(isLit ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isLit)
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .onTapGesture { model.tapTile(i) }
            .allowsHitTesting(!model.isPlayingBack)
    }
}

private struct PatternTile {
    let dim: Color
    let lit: Color
}
