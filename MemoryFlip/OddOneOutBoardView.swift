import SwiftUI

// Odd One Out. Every tile shows the same emoji except one; tap the different tile
// before the countdown empties. A wrong tap or running out of time ends the run.
struct OddOneOutBoardView: View {
    @ObservedObject var model: GameModel

    var body: some View {
        VStack(spacing: 18) {
            Text("Spot the odd one!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            countdownBar

            GeometryReader { geo in
                let cols = model.oddCols
                let rows = model.oddRows
                let gap: CGFloat = 8
                let side = min(
                    (geo.size.width - CGFloat(cols - 1) * gap) / CGFloat(cols),
                    (geo.size.height - CGFloat(rows - 1) * gap) / CGFloat(rows)
                )
                let gridCols = Array(repeating: GridItem(.fixed(side), spacing: gap), count: cols)

                LazyVGrid(columns: gridCols, spacing: gap) {
                    ForEach(0..<(cols * rows), id: \.self) { i in
                        cell(i, side: side)
                            .frame(width: side, height: side)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var countdownBar: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(model.oddRoundStart)
            let progress = max(0, min(1, 1 - elapsed / model.oddRoundDuration))
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

    private func cell(_ i: Int, side: CGFloat) -> some View {
        let emoji = i == model.oddIndex ? model.oddDifferentEmoji : model.oddBaseEmoji
        return RoundedRectangle(cornerRadius: 12)
            .fill(.white.opacity(0.07))
            .overlay(
                Text(emoji)
                    .font(.system(size: side * 0.52))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture { model.tapOddCell(i) }
    }
}
