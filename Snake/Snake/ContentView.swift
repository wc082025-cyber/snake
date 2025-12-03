import SwiftUI
import SpriteKit

extension CGVector {
    static let left  = CGVector(dx: -1, dy:  0)
    static let right = CGVector(dx:  1, dy:  0)
    static let up    = CGVector(dx:  0, dy:  1)
    static let down  = CGVector(dx:  0, dy: -1)
}

struct ContentView: View {
    @State private var scene = SnakeScene(
        size: CGSize(
            width: SnakeScene.defaultMargin * 2 + CGFloat(SnakeScene.defaultColumns) * SnakeScene.defaultCellSize,
            height: SnakeScene.defaultMargin * 2 + CGFloat(SnakeScene.defaultRows) * SnakeScene.defaultCellSize
        )
    )
    @State private var isGameOver = false
    @State private var score = 0

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Score: \(score)").font(.headline)
                Spacer()
                if isGameOver {
                    Text("YOU DIED").foregroundColor(.red).font(.headline)
                }
            }
            .padding(.horizontal, 16)

            SpriteView(scene: scene,
                       options: [.ignoresSiblingOrder, .allowsTransparency])
                .frame(minWidth: 640, minHeight: 640)
                .border(Color.gray.opacity(0.4), width: 1)
            #if os(macOS)
                .focusable(true) // allow keyboard focus
                .onAppear { NSApp.activate(ignoringOtherApps: true) }
            #endif

            HStack(spacing: 24) {
                Button { scene.changeDirection(.left) }  label: { Image(systemName: "arrow.left") }
                Button { scene.changeDirection(.right) } label: { Image(systemName: "arrow.right") }
                Button { scene.changeDirection(.up) }    label: { Image(systemName: "arrow.up") }
                Button { scene.changeDirection(.down) }  label: { Image(systemName: "arrow.down") }
            }
            .buttonStyle(.borderedProminent)
            .font(.title2)

            if isGameOver {
                Button("Restart") {
                    scene.resetGame()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 12)
            }
        }
        .padding()
        .onAppear {
            scene.scaleMode = .aspectFit
            scene.onUpdate = { newScore, gameOver in
                DispatchQueue.main.async {
                    score = newScore
                    isGameOver = gameOver
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
