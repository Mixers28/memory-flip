import SwiftUI

struct WinOverlayView: View {
    @ObservedObject var model: GameModel
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("🏆")
                    .font(.system(size: 76))

                VStack(spacing: 6) {
                    Text("You Won!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(model.difficulty.rawValue + " · " + model.difficulty.gridLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }

                HStack(spacing: 0) {
                    statCell(value: "\(model.moves)", label: "Moves")
                    Divider()
                        .frame(width: 1, height: 44)
                        .background(.white.opacity(0.25))
                    statCell(value: model.formattedTime, label: "Time")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(.white.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 11) {
                    Button { model.newGame() } label: {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(red: 0.28, green: 0.55, blue: 1.0))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }

                    Button(action: onMenu) {
                        Text("Main Menu")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }
}
