//
//  ViewController.swift
//  SXSW Logo
//
//  Created by Dan Murrell on 3/14/18.
//  Copyright © 2018 Example. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let configuration = ARWorldTrackingConfiguration()
    var logo: SCNNode?      // only one logo at a time
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        addGestureRecognizers()
        
        configuration.planeDetection = .horizontal
        
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.delegate = self
        self.sceneView.session.run(configuration)
    }
    
    @IBAction func reset(_ sender: Any) {
        guard let logo = logo else { return }   // nothing to reset if we don't have a logo placed
        logo.removeFromParentNode()
        self.logo = nil
        self.infoLabel.text = "Tap any horizontal surface to place the logo!"
    }
}

private extension ViewController {
    func addGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        guard logo == nil else { return }   // ignore taps if we already placed a logo
        guard let sceneView = sender.view as? ARSCNView else { return }
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if hitTest.isEmpty == false {
            addLogo(hitTestResult: hitTest.first)
            self.infoLabel.text = "Pinch to resize the logo, or tap reset to place it somewhere else!"
        }
    }
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        guard let _ = logo else { return }      // ignore pinches if we have not already placed a logo
        guard let sceneView = sender.view as? ARSCNView else { return }
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        if let result = hitTest.first, let name = result.node.name {
            if name == "SXSW_Logo" {            // make sure we're pinching our logo
                let node = result.node
                let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
                node.runAction(pinchAction)
                sender.scale = 1.0              // reset scale because pinch grows exponentially
            }
        }
    }
    
    func addLogo(hitTestResult: ARHitTestResult?) {
        guard let hitTestResult = hitTestResult else { return }
        guard let scene = SCNScene(named: "Media.scnassets/SXSW_Logo.scn") else { return }
        guard let node = scene.rootNode.childNode(withName: "SXSW_Logo", recursively: false) else { return }
        
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        self.sceneView.scene.rootNode.addChildNode(node)
        
        self.logo = node
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {  // UI changes *must* be done on the main thread!
            switch self.logo {
            case nil:
                self.infoLabel.text = "Tap any horizontal surface to place the logo!"
            default:
                self.infoLabel.text = "Pinch to resize the logo, or tap reset to place it somewhere else!"
            }
        }
    }
}
