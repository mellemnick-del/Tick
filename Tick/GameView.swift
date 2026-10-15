import SwiftUI

struct GameView: View {
    @State private var game = GameModel()
    @State private var touchDown = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    game.step(to: time)
                    GameRenderer.draw(game: game, in: &context, size: size, time: time)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                // Fires the moment a finger touches the screen, not when it lifts
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !touchDown {
                            touchDown = true
                            game.tap()
                        }
                    }
                    .onEnded { _ in
                        touchDown = false
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Tick game")
            .accessibilityHint("Tap when the hand reaches the glowing marker.")
            .accessibilityAddTraits(.allowsDirectInteraction)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
}

#Preview {
    GameView()
}
