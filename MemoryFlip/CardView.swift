import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        ZStack {
            CardBack()
                .rotation3DEffect(
                    .degrees(card.isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
                .opacity(card.isFlipped ? 0 : 1)

            CardFront(emoji: card.emoji, isMatched: card.isMatched)
                .rotation3DEffect(
                    .degrees(card.isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
                .opacity(card.isFlipped ? 1 : 0)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: card.isFlipped)
        .aspectRatio(1.0, contentMode: .fit)
    }
}

struct CardBack: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.18, blue: 0.75),
                        Color(red: 0.18, green: 0.08, blue: 0.50)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.18), lineWidth: 1.5)
            )
            .overlay(
                Text("?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            )
    }
}

struct CardFront: View {
    let emoji: String
    let isMatched: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                isMatched
                    ? LinearGradient(
                        colors: [Color(red: 0.10, green: 0.55, blue: 0.22), Color(red: 0.05, green: 0.38, blue: 0.14)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(
                        colors: [Color(red: 0.98, green: 0.97, blue: 1.0), Color(red: 0.92, green: 0.90, blue: 0.98)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isMatched ? Color.green.opacity(0.7) : Color.clear, lineWidth: 2.5)
            )
            .overlay(
                Text(emoji)
                    .font(.system(size: 500))
                    .minimumScaleFactor(0.01)
                    .padding(10)
            )
    }
}
