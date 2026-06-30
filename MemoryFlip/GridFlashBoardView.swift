import SwiftUI

// Grid Flash (spatial recall). The model lights a set of cells (flashLitCells) for a
// moment, then hides them; the player taps every cell that was lit. A wrong tap ends the run.
struct GridFlashBoardView: View {
    @ObservedObject var model: GameModel

    private let litColor = Color(red: 0.30, green: 0.85, blue: 1.0)
    private let foundColor = Color(red: 0.25, green: 1.0, blue: 0.55)

    var body: some View {
        VStack(spacing: 22) {
            statusBanner

            GeometryReader { geo in
                let cols = model.flashCols
                let rows = model.flashRows
                let gap: CGFloat = 10
                let side = min(
                    (geo.size.width - CGFloat(cols - 1) * gap) / CGFloat(cols),
                    (geo.size.height - CGFloat(rows - 1) * gap) / CGFloat(rows)
                )
                let gridCols = Array(repeating: GridItem(.fixed(side), spacing: gap), count: cols)

                LazyVGrid(columns: gridCols, spacing: gap) {
                    ForEach(0..<(cols * rows), id: \.self) { i in
                        cell(i)
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
        let revealing = model.flashRevealed
        return VStack(spacing: 4) {
            Text(revealing ? "Memorise!" : "Tap the lit cells")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(revealing
                 ? "\(model.flashLitCells.count) cells"
                 : "\(model.flashSelected.count) / \(model.flashLitCells.count) found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .animation(.easeInOut(duration: 0.2), value: revealing)
    }

    private func cell(_ i: Int) -> some View {
        let isLitNow = model.flashRevealed && model.flashLitCells.contains(i)
        let isFound = model.flashSelected.contains(i)
        let fill: Color = isFound ? foundColor : (isLitNow ? litColor : Color.white.opacity(0.08))
        let active = isLitNow || isFound
        return RoundedRectangle(cornerRadius: 14)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(active ? 0.85 : 0.12), lineWidth: active ? 2.5 : 1.5)
            )
            .shadow(color: active ? fill.opacity(0.7) : .clear, radius: 14)
            .scaleEffect(active ? 1.03 : 1.0)
            .animation(.easeOut(duration: 0.15), value: active)
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture { model.tapFlashCell(i) }
            .allowsHitTesting(!model.flashRevealed)
    }
}
