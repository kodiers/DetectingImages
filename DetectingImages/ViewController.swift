//
//  ViewController.swift
//  DetectingImages
//
//  Created by Viktor Yamchinov on 26/12/2018.
//  Copyright © 2018 Viktor Yamchinov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var correct: UIImageView!
    
    var answer: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        askQuestion()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Numbers", bundle: nil) else {
            fatalError("Could not load images")
        }
        // tell ARKit to track this images
        configuration.trackingImages = trackingImages
        // tracks 2 images
        configuration.maximumNumberOfTrackedImages = 2
        // run configuration
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // make sure this is an image anchor
        guard let imageAnchor = anchor as? ARImageAnchor else {
            return nil
        }
        // create a plane at the exact width and height of our image
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        // make the plane have a transparent blue color
        plane.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
        // wrap plane in a node and rotate it so it's facing us
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        // wrap it in another node and send it back
        let node = SCNNode()
        node.addChildNode(planeNode)
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // pull out all the anchors in our current AR frame
        guard let anchors = sceneView.session.currentFrame?.anchors else {
            return
        }
        // filter that array down so we only have tracked image anchors
        let visibleAnchors = anchors.filter {
            guard let anchor = $0 as? ARImageAnchor else {
                return false
            }
            return anchor.isTracked
        }
        // sort all our anchors left to right
        let nodes = visibleAnchors.sorted { (anchor1, anchor2) -> Bool in
            guard let node1 = sceneView.node(for: anchor1) else {
                return false
            }
            guard let node2 = sceneView.node(for: anchor2) else {
                return false
            }
            return node1.worldPosition.x < node2.worldPosition.x
        }
        // boil our node names to single string
        let combined = nodes.reduce("") {$0 + ($1.name ?? "")}
        // convert that single string to an int or 0 if conversion fails
        let userAnswer = Int(combined) ?? 0
        if userAnswer == answer {
            // if they got it right, clear answer so we don't have multiple submissions of the same answer
            answer = nil
            // bring in the checkmark
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.correctAnswer()
            }
        }
    }
    
    func createUniqueQuestion() -> (text: String, answer: Int) {
        // choose either adding or multiplying
        let operation = MathOperations.allCases.randomElement()!
        var question: String
        var answer: Int
        // keep running this loop until we have an answer with unique digits
        repeat {
            switch operation {
            case .add:
                // we're adding; use numbers up to 50 and 49
                let firstNumber = Int.random(in: 1...50)
                let secondNumber = Int.random(in: 1...49)
                question = "What is \(firstNumber) plus \(secondNumber)"
                answer = firstNumber + secondNumber
            case .multiply:
                // we're multiplying; use numbers up to 10 and 9
                let firstNumber = Int.random(in: 1...10)
                let secondNumber = Int.random(in: 1...9)
                question = "What is \(firstNumber) times \(secondNumber)"
                answer = firstNumber * secondNumber
            }
        } while !answer.hasUniqueDigits
        return (question, answer)
    }
    
    func askQuestion() {
        // call createUniqueQuestion and puts its content into UI
        let newQuestion = createUniqueQuestion()
        question.text = newQuestion.text
        answer = newQuestion.answer
        // make question label invisible so we can fade it in
        question.alpha = 0
        UIView.animate(withDuration: 0.5) {
            // fade in the new question
            self.question.alpha = 1
            // hide and scale out the correct check mark
            self.correct.alpha = 0
            self.correct.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }
    }
    
    func correctAnswer() {
        // make the checkmark nice and big
        correct.transform = CGAffineTransform(scaleX: 2, y: 2)
        // animate the checkmark down to its regular size while it fades in
        UIView.animate(withDuration: 0.5) {
            self.correct.transform = .identity
            self.correct.alpha = 1
        }
        // then call askQuestion to m ove app onwards
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.askQuestion()
        }
    }
    
}

extension Int {
    var hasUniqueDigits: Bool {
        let str = String(self)
        let uniqueLetters = Set(str)
        return str.count == uniqueLetters.count
    }
}

enum MathOperations: CaseIterable {
    case add, multiply
}
