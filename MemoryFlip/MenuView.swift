import SwiftUI

struct MenuView: View {
    @AppStorage("highScore") private var highScore = 0
    @AppStorage("bestLevel") private var bestLevel = 0

    var body: some View {
        NavigationStack {
            ZStack {
                background
                VStack(spacing: 44) {
                    titleSection
                    if highScore > 0 {
                        recordsSection
                    }
                    startButton
                }
                .padding(.horizontal, 28)
            }
            .navigationDestination(for: Bool.self) { _ in
                GameBoardView()
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
            Text("Match pairs · survive on 3 lives · beat your best")
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

    private var startButton: some View {
        NavigationLink(value: true) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("Start Run")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.45, green: 0.25, blue: 1.0), Color(red: 0.28, green: 0.10, blue: 0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .purple.opacity(0.5), radius: 14, y: 6)
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
