//
//  ViewController.swift
//  SXSW Logo
//
//  Created by Dan Murrell on 3/14/18.
//  Copyright © 2018 Example. All rights reserved.
//

import UIKit
import ARKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var snapshot: SnapshotButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let configuration = ARWorldTrackingConfiguration()
    var logo: SCNNode?      // only one logo at a time
    let skins = [0, 1, 2, 3, 4]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        addGestureRecognizers()
        
        configuration.planeDetection = .horizontal
        
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.automaticallyUpdatesLighting = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.delegate = self
        self.sceneView.session.run(configuration)
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.snapshot.delegate = self
    }
    
    @IBAction func reset(_ sender: Any) {
        guard let logo = logo else { return }   // nothing to reset if we don't have a logo placed
        logo.removeFromParentNode()
        self.logo = nil
        self.infoLabel.text = "Tap any horizontal surface to place the logo!"
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
}

private extension ViewController {
    func addGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        guard logo == nil else { return }   // ignore taps if we already placed a logo
        guard let sceneView = sender.view as? ARSCNView else { return }
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if hitTest.isEmpty == false {
            addLogo(hitTestResult: hitTest.first)
            self.infoLabel.text = "Pinch to resize the logo, long press to rotate it, or tap reset to place it somewhere else!\nTap below to change its texture!\nOr just tap the shutter to take its picture!"
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
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        guard let _ = logo else { return }      // ignore long presses if we have not already placed a logo
        guard let sceneView = sender.view as? ARSCNView else { return }
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        if hitTest.isEmpty == false {
            let results = hitTest.first!
            if sender.state == .began {
                let action = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 3)
                let forever = SCNAction.repeatForever(action)
                results.node.runAction(forever)
            } else if sender.state == .ended {
                results.node.removeAllActions()
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
        self.sceneView.debugOptions = []
        self.sceneView.scene.rootNode.addChildNode(node)

        self.logo = node
    }
    
    @IBAction func takeSnapshot(_ sender: Any) {
        let takeSnapshotBlock = {
            UIImageWriteToSavedPhotosAlbum(self.sceneView.snapshot(), nil, nil, nil)
            DispatchQueue.main.async {
                // Briefly flash the screen.
                let flashOverlay = UIView(frame: self.sceneView.frame)
                flashOverlay.backgroundColor = UIColor.white
                self.sceneView.addSubview(flashOverlay)
                UIView.animate(withDuration: 0.25, animations: {
                    flashOverlay.alpha = 0.0
                }, completion: { _ in
                    flashOverlay.removeFromSuperview()
                })
            }
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            takeSnapshotBlock()
        case .restricted, .denied:
            let title = "Photos access denied"
            let message = "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots."
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            self.present(alert, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    takeSnapshotBlock()
                }
            })
        }
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
                self.infoLabel.text = "Pinch to resize the logo, long press to rotate it, or tap reset to place it somewhere else!\nTap below to change its texture!\nOr just tap the shutter to take its picture!"
            }
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return skins.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "skin", for: indexPath) as! SkinCell
        cell.image.image = UIImage(named: "SXSW_Diffuse_\(self.skins[indexPath.row])")
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let logo = logo else { return }   // make sure we've placed a logo
        
        logo.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "SXSW_Diffuse_\(self.skins[indexPath.row])")
        logo.geometry?.firstMaterial?.normal.contents = UIImage(named: "SXSW_Normal_\(self.skins[indexPath.row])")
        logo.geometry?.firstMaterial?.roughness.contents = UIImage(named: "SXSW_Roughness_\(self.skins[indexPath.row])")
    }
}


extension ViewController: SnapshotButtonDelegate {
    func countdownStarting() {
        print("Countdown starting until snapshot taken")
    }
    
    func countdown(remaining: Int) {
        print("\(remaining) seconds until snapshot")
    }
    
    func countdownStopped(at: Int) {
        print("Countdown stopped early at \(at) remaining")
    }
    
    func countdownFinished() {
        print("Countdown finished, taking snapshot")
        takeSnapshot(self.snapshot)
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}


