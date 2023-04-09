enum Figma {
	typealias Language = String
	typealias PageId = String

	struct Child: Codable {
		let id: PageId
		let name: String
	}
	struct Pages: Codable {
		struct Node: Codable {
			struct Document: Codable {
				let name: String
				let children: [Child]
			}
			let document: Document
		}
		let name: String
		let nodes: [PageId: Node]
	}
	struct Screen {
		let id: PageId
		let locale: Language
		let page: Int
		let device: Device
	}
}

extension Figma.Child {
	func screen() -> Figma.Screen? {
		let cmp = self.name.components(separatedBy: "/")
		guard cmp.count == 4,
			  cmp[0] == "screen",
			  let device = Device(rawValue: cmp[2]),
			  let page = Int(cmp[3]) else { return nil }

		return Figma.Screen(id: self.id, locale: cmp[1], page: page, device: device)
	}
}

extension Figma.Screen {
	var fileName: String {
		"\(self.device.id)_\(self.page).jpg"
	}
}

extension Figma.Pages {

	func screens(for page: String) -> [Figma.Screen] {
		var screens = [Figma.Screen]()
		if let node = self.nodes[page] {
			screens = node.document.children.compactMap {
				$0.screen()
			}
		}
		return screens
	}

}
