import UIKit
import SnapKit
import VNBase
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

	let vm = XOViewVM()

	@IBOutlet weak var sv: ARSCNView!
//	lazy var xoVC = XOVC(viewModel: self.vm)
//	lazy var sceneView = ARSCNView(frame: self.view.bounds)

	override func viewDidLoad() {
		super.viewDidLoad()

//		self.view.addSubview(sceneView) {
//			$0.edges.equalToSuperview()
//		}
//
//		print(">>>>>\(sceneView.isUserInteractionEnabled) \(sceneView.isMultipleTouchEnabled)")

//		sceneView.isUserInteractionEnabled = true
//		sceneView.isMultipleTouchEnabled = true
		sv.delegate = self
//		sv.showsStatistics = true

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.reset))
	}

	@objc private func reset() {
		self.vm.reset()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		let configuration = ARImageTrackingConfiguration()
		configuration.trackingImages = [
			ARReferenceImage(UIImage(named: "qr-code1")!.cgImage!, orientation: .up, physicalWidth: 0.3)
		]
		configuration.maximumNumberOfTrackedImages = 1
		sv.session.run(configuration)
	}


	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		sv.session.pause()
	}

}

extension ViewController {
//	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//
//		DispatchQueue.main.async {
//			//			guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//			self.asd(node: node, planeAnchor: anchor)
//		}
//
//		//        switch anchor {
//		//        case let imageAnchor as ARImageAnchor:
//		//            nodeAdded(node, for: imageAnchor)
//		//        case let planeAnchor as ARPlaneAnchor:
//		//            nodeAdded(node, for: planeAnchor)
//		//        default:
//		//            print(#line, #function, "Unknow anchor has been discovered")
//		//
//		//        }
//	}

	func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
		let node = SCNNode()
		guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
		let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
							 height: imageAnchor.referenceImage.physicalSize.height)
		let planeNode = SCNNode(geometry: plane)
		planeNode.eulerAngles.x = -.pi / 2
		createHostingController(for: planeNode)
		node.addChildNode(planeNode)
		return node
	}

	func createHostingController(for node: SCNNode) {
		DispatchQueue.main.async {
			let arVC = XOVC(viewModel: self.vm)
			arVC.willMove(toParent: self)
			self.addChild(arVC)
			arVC.view.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
			self.view.addSubview(arVC.view)
			self.show(hostingVC: arVC, on: node)
			let gr = UITapGestureRecognizer(target: self, action: #selector(self.tap))
			arVC.view.addGestureRecognizer(gr)
		}
	}

	@objc private func tap() {
		print(">>>>>\(123)")
	}

	func show(hostingVC: UIViewController, on node: SCNNode) {
		// create a new material
		let material = SCNMaterial()

		// this allows the card to render transparent parts the right way
		hostingVC.view.isOpaque = false

		// set the diffuse of the material to the view of the Hosting View Controller
		material.diffuse.contents = hostingVC.view

		// Set the material to the geometry of the node (plane geometry)
		node.geometry?.materials = [material]
	}

	func sessionWasInterrupted(_ session: ARSession) {
	}

	func sessionInterruptionEnded(_ session: ARSession) {
	}

	func session(_ session: ARSession, didFailWithError error: Error) {
	}

//	func asd(node: SCNNode, planeAnchor: ARAnchor) {
//		// Create a SceneKit plane to visualize the plane anchor using its position and extent.
//		//        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
////		let plane = SCNPlane(width: sceneView.bounds.width/3000, height: sceneView.bounds.height/3000)
////		let plane = SCNPlane(width: sceneView.bounds.width/1000, height: sceneView.bounds.width/1000)
////		let planeNode = SCNNode(geometry: plane)
//
//		self.xoVC.willMove(toParent: self)
//		self.addChild(self.xoVC)
//		self.xoVC.view.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
//		self.view.addSubview(self.xoVC.view)
//
//		let material = SCNMaterial()
//		self.xoVC.view.isOpaque = false
//
//		material.diffuse.contents = self.xoVC.view
//		node.geometry?.materials = [material]
//		self.xoVC.view.backgroundColor = UIColor.clear
//		// render the view on the plane geometry as a material
//
//		// this allows the card to render transparent parts the right way
////		hostingVC.view.isOpaque = false
//
////		hostingVC.view.backgroundColor = UIColor.clear
//
//		//		planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
//
//		/*
//		 `SCNPlane` is vertically oriented in its local coordinate space, so
//		 rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
//		 */
////		planeNode.eulerAngles.x = -.pi / 2
//
//		// Make the plane visualization semitransparent to clearly show real-world placement.
//		//        planeNode.opacity = 0.1
//
////		plane.firstMaterial?.blendMode = .max
////		plane.firstMaterial?.blendMode = .replace
//
////		let size = self.xoVC.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
////		self.xoVC.view.frame = CGRect(origin: .zero, size: size)
////		plane.firstMaterial?.diffuse.contents = self.xoVC.view //  self.contentController?.view
//		print("setting transparency mode")
////		plane.firstMaterial?.transparencyMode = SCNTransparencyMode.rgbZero
//
////		node.addChildNode(planeNode)
//	}

//	func nodeAdded(_ node: SCNNode, for imageAnchor: ARImageAnchor) {
//		// Add image size
//		let image = imageAnchor.referenceImage
//		let size = image.physicalSize
//		print(size.width)
//		// Create plane of the same size
//		let height = 69 / 65 * size.height
//		let width = image.name == "horses" ?
//		157 / 150 * 15 / 8.1851 * size.width :
//		157 / 150 * 15 / 8.247 * size.width
//		let plane = SCNPlane(width: width, height: height)
//		plane.firstMaterial?.diffuse.contents = UIImage(named: "monument")  ///image.name == "horses" ?
//																			//		UIImage(named: "monument")
//																			//            videoPlayer
//																			//            UIImage(named: "bridge")
//
//		//        if image.name == "horses" {
//		//            videoPlayer.play()
//		//        }
//
//		// Create plane node
//		let planeNode = SCNNode(geometry: plane)
//		planeNode.eulerAngles.x = -.pi / 2
//
//		// Move plane
//		planeNode.position.x += image.name == "theatre" ? -0.002 : 0.001
//		node.addChildNode(planeNode)
//	}


}
