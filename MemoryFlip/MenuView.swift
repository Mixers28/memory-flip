import SwiftUI

struct MenuView: View {
    @AppStorage("highScore") private var highScore = 0
    @AppStorage("bestLevel") private var bestLevel = 0

    var body: some View {
        NavigationStack {
            ZStack {
                background
                ScrollView {
                    VStack(spacing: 28) {
                        titleSection
                            .padding(.top, 24)
                        if highScore > 0 {
                            recordsSection
                        }
                        modeButtons
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(for: GameStart.self) { start in
                GameBoardView(start: start)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.04, blue: 0.22),
                Color(red: 0.18, green: 0.08, blue: 0.44)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("🃏")
                .font(.system(size: 72))
            Text("PairFlip")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Pick a game · beat your best score")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    private var recordsSection: some View {
        HStack(spacing: 12) {
            RecordPill(icon: "trophy.fill", label: "High Score", value: "\(highScore)", color: Color(red: 1.0, green: 0.75, blue: 0.1))
            RecordPill(icon: "arrow.up.circle.fill", label: "Best Level", value: "\(bestLevel)", color: Color(red: 0.35, green: 0.75, blue: 1.0))
        }
    }

    private var modeButtons: some View {
        VStack(spacing: 14) {
            ModeButton(
                start: .marathon,
                icon: "flag.checkered",
                title: "Marathon",
                subtitle: "Every game, one run — keep your score going",
                colors: [Color(red: 1.0, green: 0.55, blue: 0.0), Color(red: 0.95, green: 0.18, blue: 0.45)],
                glow: Color(red: 0.95, green: 0.35, blue: 0.2)
            )

            Text("OR PRACTICE A GAME")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1.2)
                .padding(.top, 6)

            ModeButton(
                start: .practice(.cards),
                icon: GamePhase.cards.icon,
                title: GamePhase.cards.title,
                subtitle: GamePhase.cards.rules,
                colors: [Color(red: 0.45, green: 0.25, blue: 1.0), Color(red: 0.28, green: 0.10, blue: 0.80)],
                glow: .purple
            )
            ModeButton(
                start: .practice(.pattern),
                icon: GamePhase.pattern.icon,
                title: GamePhase.pattern.title,
                subtitle: GamePhase.pattern.rules,
                colors: [Color(red: 0.0, green: 0.70, blue: 0.65), Color(red: 0.85, green: 0.20, blue: 0.55)],
                glow: Color(red: 0.85, green: 0.20, blue: 0.55)
            )
            ModeButton(
                start: .practice(.gridFlash),
                icon: GamePhase.gridFlash.icon,
                title: GamePhase.gridFlash.title,
                subtitle: GamePhase.gridFlash.rules,
                colors: [Color(red: 0.15, green: 0.45, blue: 0.95), Color(red: 0.10, green: 0.75, blue: 0.85)],
                glow: Color(red: 0.15, green: 0.55, blue: 0.95)
            )
            ModeButton(
                start: .practice(.numberOrder),
                icon: GamePhase.numberOrder.icon,
                title: GamePhase.numberOrder.title,
                subtitle: GamePhase.numberOrder.rules,
                colors: [Color(red: 0.95, green: 0.45, blue: 0.10), Color(red: 0.80, green: 0.20, blue: 0.30)],
                glow: Color(red: 0.95, green: 0.45, blue: 0.10)
            )
            ModeButton(
                start: .practice(.oddOneOut),
                icon: GamePhase.oddOneOut.icon,
                title: GamePhase.oddOneOut.title,
                subtitle: GamePhase.oddOneOut.rules,
                colors: [Color(red: 0.35, green: 0.30, blue: 0.85), Color(red: 0.65, green: 0.20, blue: 0.75)],
                glow: Color(red: 0.5, green: 0.25, blue: 0.85)
            )
            ModeButton(
                start: .practice(.stroop),
                icon: GamePhase.stroop.icon,
                title: GamePhase.stroop.title,
                subtitle: GamePhase.stroop.rules,
                colors: [Color(red: 0.90, green: 0.30, blue: 0.45), Color(red: 0.45, green: 0.35, blue: 0.95)],
                glow: Color(red: 0.7, green: 0.30, blue: 0.7)
            )
        }
    }
}

private struct ModeButton: View {
    let start: GameStart
    let icon: String
    let title: String
    let subtitle: String
    let colors: [Color]
    let glow: Color

    var body: some View {
        NavigationLink(value: start) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: glow.opacity(0.45), radius: 12, y: 5)
        }
    }
}

struct RecordPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
