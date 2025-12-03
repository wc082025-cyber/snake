//
//  ViewController.swift
//  Snake
//
//  Created by Chris Wahlberg on 25/11/2025.
//

import Cocoa
import SpriteKit

class GameViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else {
            fatalError("Root view is not an SKView")
        }

        // The scene size must match the size we use in ContentView 
        let scene = SnakeScene(size: CGSize(width: 640, height: 640))
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)

        // Give the SKView keyboard focus so arrow keys work
        skView.window?.makeFirstResponder(skView)

        // Optional debug overlays
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
    }
}
