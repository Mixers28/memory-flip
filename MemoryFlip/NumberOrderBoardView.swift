import SwiftUI

// Number Order (chimp test). Numbers are placed on a grid; the player taps 1 while
// everything is visible, then the remaining numbers blank out and must be tapped 2…N
// from memory. A wrong tap ends the run.
struct NumberOrderBoardView: View {
    @ObservedObject var model: GameModel

    private let numberColor = Color(red: 0.98, green: 0.97, blue: 1.0)
    private let solvedColor = Color(red: 0.25, green: 1.0, blue: 0.55)

    var body: some View {
        VStack(spacing: 22) {
            statusBanner

            GeometryReader { geo in
                let cols = model.numberCols
                let rows = model.numberRows
                let gap: CGFloat = 10
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

    private var statusBanner: some View {
        VStack(spacing: 4) {
            Text(model.numbersHidden ? "From memory!" : "Tap 1 to start")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Next: \(min(model.numberNextExpected, model.numberCount)) of \(model.numberCount)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .animation(.easeInOut(duration: 0.2), value: model.numbersHidden)
    }

    private func cell(_ i: Int, side: CGFloat) -> some View {
        let number = model.numberAtCell[i]
        let isSolved = model.numberSolved.contains(i)
        let hasNumber = number != nil
        // Show the digit only before the first tap (or this is the live tile awaiting tap 1).
        let showsDigit = hasNumber && !isSolved && !model.numbersHidden

        let fill: Color = isSolved
            ? solvedColor.opacity(0.85)
            : (hasNumber ? Color.white.opacity(0.14) : Color.white.opacity(0.05))

        return RoundedRectangle(cornerRadius: 14)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(hasNumber ? 0.25 : 0.08), lineWidth: 1.5)
            )
            .overlay(
                Group {
                    if showsDigit, let n = number {
                        Text("\(n)")
                            .font(.system(size: side * 0.42, weight: .bold, design: .rounded))
                            .foregroundStyle(numberColor)
                    } else if isSolved, let n = number {
                        Text("\(n)")
                            .font(.system(size: side * 0.42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .onTapGesture { model.tapNumberCell(i) }
    }
}
