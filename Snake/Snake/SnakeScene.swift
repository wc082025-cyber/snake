//
//  SnakeScene.swift
//  Snake
//
//  Created by Chris Wahlberg on 01/12/2025.
//

import SpriteKit
#if os(macOS)
import AppKit
#endif

final class SnakeScene: SKScene {


    // MARK: – Board configuration (20 × 20 cells)
    
    static let defaultColumns: Int = 20
    static let defaultRows: Int = 20
    static let defaultCellSize: CGFloat = 30.0
    static let defaultMargin: CGFloat = 20.0
    
    private let columns = SnakeScene.defaultColumns                // horizontal cells
    private let rows    = SnakeScene.defaultRows              // vertical cells
    private let cellSize: CGFloat = SnakeScene.defaultCellSize    // each cell is 30 pt
    private let boardOrigin = CGPoint (x: SnakeScene.defaultMargin,
                                       y: SnakeScene.defaultMargin) //  margin on each side


    // MARK: – Game state
    
    // Start  snake in  centre of the board
    private var snake: [CGPoint] = [
        CGPoint(x: 10, y: 10)   // centre of a 20×20 grid
    ]

    var direction = CGVector(dx: 1, dy: 0)          // exposed for debugging if needed
    private var food: CGPoint = .zero
    private var moveTimer: Timer?
    private var isGameOver = false
    private var score = 0

    //  NEW PROPERTIES FOR SMOOTH MOVEMENT
    private var stepProgress: CGFloat = 0.0                 // 0.0 … 1.0 inside the current step
    private let stepDuration: TimeInterval = 0.19          // seconds per logical step (tweak for speed)
    private var previousSnake: [CGPoint] = []              // snapshot of snake positions before the step
    //

    // Callback to SwiftUI – the view will set this closure
    var onUpdate: ((Int, Bool) -> Void)?

    //
    // MARK: – Lifecycle
    //
    override func didMove(to view: SKView) {
        backgroundColor = #colorLiteral(red: 0.5787474513, green: 0.3215198815, blue: 0, alpha: 1)

        spawnFood()
        startTimer()
        // Initial draw (will be immediately overwritten by the first interpolate call)
        //redraw()
        notifyUI()

        #if os(macOS)
        // Make sure the SKView receives key events (arrow keys)
        view.window?.makeFirstResponder(view)
        #endif
    }

    //
    // MARK: – Timer & per‑frame update (60 Hz)
    //
    private func startTimer() {
        moveTimer?.invalidate()
        // Fire at the screen refresh rate (~60 fps) for smooth interpolation
        moveTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0,
                                         repeats: true) { [weak self] _ in
            self?.updateStep(delta: 1.0 / 60.0)
        }
        RunLoop.main.add(moveTimer!, forMode: .common)
    }

    //
    // MARK: – Per‑frame update (handles interpolation)
    //
    private func updateStep(delta: CGFloat) {
        guard !isGameOver else { return }

        // Advance the progress toward the next logical step
        stepProgress += CGFloat(delta) / CGFloat(stepDuration)

        if stepProgress >= 1.0 {
            // Completed a logical move – reset progress
            stepProgress = 0.0

            // Snapshot the current snake positions *before* we change them
            previousSnake = snake

            // Perform the actual game logic (move one cell, collisions, food, etc.)
            logicalStep()
        }

        // Draw the scene using the current interpolation factor
        interpolateVisuals()
    }

    //
    // MARK: – Logical game step (one cell movement)
    //
    private func logicalStep() {
        //   Move head
        var newHead = snake[0]
        newHead.x += direction.dx
        newHead.y += direction.dy

        // Wall collision
        if !(0..<CGFloat(columns)).contains(newHead.x) ||
           !(0..<CGFloat(rows)).contains(newHead.y) {
            endGame()
            return
        }

        //   Self‑collision
        if snake.contains(newHead) {
            endGame()
            return
        }

        //  Insert new head
        snake.insert(newHead, at: 0)

        //  Food
        if newHead == food {
            score += 10
            spawnFood()                 // keep the tail → snake grows
        } else {
            snake.removeLast()          // normal move – drop the tail
        }

        //  Notify SwiftUI (score / game‑over)
        notifyUI()
    }

    
    // MARK: – Rendering with interpolation
    
    private func interpolateVisuals() {
        // Clear everything from the previous frame
        removeAllChildren()

        //  Gray border (matches the board)
        let boardRect = CGRect(x: boardOrigin.x,
                               y: boardOrigin.y,
                               width: CGFloat(columns) * cellSize,
                               height: CGFloat(rows) * cellSize)
        let border = SKShapeNode(rect: boardRect)
        border.strokeColor = #colorLiteral(red: 0.3098039329, green: 0.2039215714, blue: 0.03921568766, alpha: 1)
        border.lineWidth = 5
        addChild(border)

        //  Food (no white rim)
        let foodNode = SKShapeNode(circleOfRadius: cellSize * 0.4)
        foodNode.fillColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        foodNode.strokeColor = .clear
        foodNode.position = pointForGrid(food)
        addChild(foodNode)

        //  Snake segments (interpolated)
        // `previousSnake` holds the positions *before* the most recent logical step.
        // If it’s empty (first frame) we just use the current positions.
        for (index, current) in snake.enumerated() {
            let previous = previousSnake.indices.contains(index) ? previousSnake[index] : current

            // Linear interpolation (lerp) between previous and current grid coordinates
            let interpX = previous.x + (current.x - previous.x) * stepProgress
            let interpY = previous.y + (current.y - previous.y) * stepProgress
            let interpolatedPoint = CGPoint(x: interpX, y: interpY)

            let node = SKShapeNode(rectOf: CGSize(width: cellSize,
                                                 height: cellSize),
                                  cornerRadius: 10)
            node.fillColor = #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1)
            node.strokeColor = .clear
            node.position = pointForGrid(interpolatedPoint)
            addChild(node)
        }
    }

    
    // MARK: – Helper: convert board coordinates → scene points
    
    private func pointForGrid(_ pt: CGPoint) -> CGPoint {
        // Convert a board coordinate (0‑based) to a scene point (center of the cell)
        CGPoint(x: boardOrigin.x + (pt.x + 0.5) * cellSize,
                y: boardOrigin.y + (pt.y + 0.5) * cellSize)
    }

    
    // MARK: – Food placement
    
    private func spawnFood() {
        var empty: [CGPoint] = []
        for y in 0..<rows {
            for x in 0..<columns {
                let p = CGPoint(x: CGFloat(x), y: CGFloat(y))
                if !snake.contains(p) { empty.append(p) }
            }
        }
        food = empty.randomElement() ?? CGPoint(x: 0, y: 0)
    }


    // MARK: – Game‑over handling
    
    private func endGame() {
        isGameOver = true
        moveTimer?.invalidate()

        let label = SKLabelNode(text: "YOU DIED")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 48
        label.fontColor = .red
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)

        notifyUI()
    }

    
    // MARK: – Notify SwiftUI (score & game‑over)
    
    private func notifyUI() {
        onUpdate?(score, isGameOver)
    }


    // MARK: – Public API for UI (direction change)
    
    /// Called by the SwiftUI buttons or keyboard to turn the snake.
    func changeDirection(_ newDir: CGVector) {
        // Prevent 180° reversal (same rule you already use)
        if (direction.dx == 0 && newDir.dx != 0) ||
           (direction.dy == 0 && newDir.dy != 0) {
            direction = newDir
        }
    }
// MARK: Restart
    // reset and restart the game
    
    // stop timer
    func resetGame() {
        moveTimer?.invalidate()
       // moveTimer = nil
        
        //reset state
        score = 0
        isGameOver = false
        direction = CGVector (dx: 1, dy: 0)
        
        // put snake back in center
        snake = [
            CGPoint (x: SnakeScene.defaultColumns / 2,
                     y: SnakeScene.defaultRows / 2)
        ]
        
        spawnFood()
       // redraw()
        notifyUI()
        
        startTimer()
    }
    
    // MARK: – macOS keyboard handling
    
    #if os(macOS)
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Arrow key codes: 123← 124→ 125↓ 126↑
        switch event.keyCode {
        case 123: changeDirection(.left)
        case 124: changeDirection(.right)
        case 125: changeDirection(.down)
        case 126: changeDirection(.up)
        default: break
        }
    }
    #endif
}
