//
//  SnakeModel.swift
//  Snake
//
//  Created by Chris Wahlberg on 25/11/2025.
//

import Foundation
import CoreGraphics   // for CGPoint
import SpriteKit
import SwiftUI

// MARK: – Direction

enum Direction {
   case up, down, left, right
}

// MARK: – Model

final class SnakeModel {

    // Grid size (feel free to change – the scene will adapt automatically)
    static let columns = 40
    static let rows    = 40

    // Snake is an array of grid points. Index 0 = head, last = tail.
    private(set) var snake: [CGPoint] = [CGPoint(x: 10, y: 10)]

    // Food position – always on an empty cell.
    private(set) var food: CGPoint = .zero

    // Current travel direction – start moving right.
    private(set) var dir: Direction = .right

    // Game‑over flag.
    private(set) var isGameOver = false

    // MARK: – Init
    
    init() { placeFood() }

   // MARK: – Public API
    /// Turn the snake; 180° turns are ignored.
    /// 
    func turn(to newDir: Direction) {
      switch (dir, newDir) {
   case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return                     // illegal reverse
      default:
      dir = newDir
        }
    }

    /// Advance the snake one step. Returns `true` if the move succeeded,
    /// `false` if the snake collided (game over).
    @discardableResult
    func step() -> Bool {
      guard !isGameOver else { return false }

      // ---- compute new head
        var head = snake[0]
        switch dir {
       case .up:    head.y += 1
      case .down:  head.y -= 1
        case .left:  head.x -= 1
        case .right: head.x += 1
        }

       // --- wall collision
        if head.x < 0 || head.x >= CGFloat(Self.columns) ||
      head.y < 0 || head.y >= CGFloat(Self.rows) {
        isGameOver = true
            return false
        }

        // --- self‑collision
        if snake.contains(head) {
        isGameOver = true
            return false
        }

        // --- insert new head
        snake.insert(head, at: 0)

      // ----  food ?
        if head == food {
            // grow – keep the tail (do **not** remove last element)
            placeFood()
        } else {
            // normal move – drop the tail
            snake.removeLast()
        }

        return true
    }

    // MARK: – Private helpers 
    private func placeFood() {
        var empty: [CGPoint] = []
    for y in 0..<Self.rows {
      for x in 0..<Self.columns {
       let pt = CGPoint(x: x, y: y)
             if !snake.contains(pt) { empty.append(pt) }
            }
        }
        food = empty.randomElement() ?? CGPoint(x: 5, y: 5)
    }
}
