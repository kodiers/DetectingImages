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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
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
    
}
