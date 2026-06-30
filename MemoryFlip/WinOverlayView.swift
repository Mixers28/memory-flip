import SwiftUI

// Shown when a level is cleared — presents score breakdown and advances to next level
struct LevelClearOverlay: View {
    @ObservedObject var model: GameModel
    let onContinue: () -> Void

    private var levelTotal: Int {
        model.lastLevelBase + model.lastLevelTimeBonus + model.lastLevelEfficiencyBonus
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Level \(model.level) Clear!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(model.lastLevelWasPerfect ? "Perfect — no mistakes!" : "Stage complete")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(model.lastLevelWasPerfect
                            ? Color(red: 0.3, green: 1.0, blue: 0.5)
                            : .white.opacity(0.55))
                }

                // Score breakdown
                VStack(spacing: 0) {
                    ScoreLine(label: "Stage base", value: model.lastLevelBase, color: .white)
                    Divider().background(.white.opacity(0.12))
                    ScoreLine(label: "Time bonus", value: model.lastLevelTimeBonus, color: Color(red: 0.35, green: 0.75, blue: 1.0))
                    if model.lastLevelEfficiencyBonus > 0 {
                        Divider().background(.white.opacity(0.12))
                        ScoreLine(label: "Efficiency bonus", value: model.lastLevelEfficiencyBonus, color: Color(red: 0.3, green: 1.0, blue: 0.5))
                    }
                    Divider().background(.white.opacity(0.18))
                    ScoreLine(label: "This level", value: levelTotal, color: Color(red: 1.0, green: 0.8, blue: 0.2), bold: true)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 4) {
                    Text("Run total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text("\(model.score)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Level \(model.level + 1)")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.25, blue: 1.0), Color(red: 0.28, green: 0.10, blue: 0.80)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.15), lineWidth: 1))
            )
            .padding(.horizontal, 28)
        }
    }
}

// Shown in marathon when a mode segment is cleared — announces the next game.
struct HandoffOverlay: View {
    @ObservedObject var model: GameModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color(red: 0.3, green: 1.0, blue: 0.5))
                    Text("\(model.phase.title) cleared!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if model.willCompleteLapNext {
                        Text("Lap \(model.lap) complete — speeding up!")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.2))
                    }
                }

                VStack(spacing: 4) {
                    Text("Run total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text("\(model.score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text("Up next")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Label(model.nextMarathonMode.title, systemImage: model.nextMarathonMode.icon)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Play")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.25, blue: 1.0), Color(red: 0.28, green: 0.10, blue: 0.80)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.15), lineWidth: 1))
            )
            .padding(.horizontal, 28)
        }
    }
}

// Shown when the player runs out of lives
struct RunOverOverlay: View {
    @ObservedObject var model: GameModel
    let onRestart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(model.isNewHighScore ? "🏆" : "💀")
                        .font(.system(size: 64))
                    Text("Run Over")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Reached Level \(model.level)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }

                // Final score + new high score callout
                VStack(spacing: 8) {
                    Text("\(model.score)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if model.isNewHighScore {
                        Text("New High Score!")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(Color(red: 1.0, green: 0.80, blue: 0.15).opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        Text("Best: \(model.highScore)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 11) {
                    Button(action: onRestart) {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.45, green: 0.25, blue: 1.0), Color(red: 0.28, green: 0.10, blue: 0.80)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }

                    Button(action: onMenu) {
                        Text("Main Menu")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.15), lineWidth: 1))
            )
            .padding(.horizontal, 28)
        }
    }
}

private struct ScoreLine: View {
    let label: String
    let value: Int
    let color: Color
    var bold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: bold ? 15 : 14, weight: bold ? .bold : .regular))
                .foregroundStyle(.white.opacity(bold ? 0.9 : 0.65))
            Spacer()
            Text("+\(value)")
                .font(.system(size: bold ? 16 : 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.vertical, 8)
    }
}
