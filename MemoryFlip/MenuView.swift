import SwiftUI

struct MenuView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                background
                VStack(spacing: 48) {
                    titleSection
                    difficultySection
                }
                .padding(.horizontal, 28)
            }
            .navigationDestination(for: Difficulty.self) { difficulty in
                GameBoardView(difficulty: difficulty)
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
            Text("Memory Flip")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Match all the pairs to win")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var difficultySection: some View {
        VStack(spacing: 14) {
            Text("Choose Difficulty")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(1.5)

            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                NavigationLink(value: difficulty) {
                    DifficultyRow(difficulty: difficulty)
                }
            }
        }
    }
}

struct DifficultyRow: View {
    let difficulty: Difficulty

    var accentColor: Color {
        switch difficulty {
        case .easy:   return Color(red: 0.20, green: 0.80, blue: 0.40)
        case .medium: return Color(red: 1.00, green: 0.60, blue: 0.10)
        case .hard:   return Color(red: 0.95, green: 0.25, blue: 0.35)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Text(difficulty.emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(difficulty.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(difficulty.gridLabel)  ·  \(difficulty.pairsLabel)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.white.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
