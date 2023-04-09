import Foundation

struct Deploy {
	private let keyValue: [Deploy.NamedKey: String]
}

extension Deploy.NamedKey {

	var fileName: String? {
		switch self {
			case .title: return "name.txt"
			case .subtitle: return "subtitle.txt"
			case .keywords: return "keywords.txt"
			case .whatsNew: return "release_notes.txt"
			default: return nil
		}
	}

}

public extension Array {

	func isIndexValid(index: Int) -> Bool {
		return index >= 0 && index < self.count
	}

	func safeObject(at index: Int) -> Element? {
		guard self.isIndexValid(index: index) else { return nil }
		return self[index]
	}
}

extension String {
	func fixedValue() -> String {
		self
			.replacingOccurrences(of: "\\n", with: "\n")
			.replacingOccurrences(of: "\r", with: "")
	}
}

extension Deploy {

	enum NamedKey: String, CaseIterable {
		case title = "Title"
		case subtitle = "Subtitle"
		case keywords = "keywords"
		case iPhone8 = "iPhone8"
		case iPhone11 = "iPhone11"
		case whatsNew = "What's new"
		case locale = "locale"
		case previewTimestamp
		case iPadPro = "iPadPro"
		case iPadPro3Gen = "iPadPro3Gen"
	}

	init(string: String, map: [Int: NamedKey]) {
		let cmp = string.components(separatedBy: "\t")
		var keyValue = [Deploy.NamedKey: String]()
		cmp.enumerated().forEach { (idx, item) in
			if let key = map[idx] {
				keyValue[key] = item.fixedValue()
			}
		}
		self.keyValue = keyValue
	}

	subscript(key: NamedKey) -> String {
		let text = self.keyValue[key] ?? ""
		return text
	}

	func createFiles(at url: URL) {
		NamedKey.allCases.forEach {
			if let fileName = $0.fileName {
				url.write(self[$0], to: fileName)
			}
		}
	}

}


extension URL {

	func write(_ text: String, to path: String) {
		let url = self.appendingPathComponent(path)
		do {
			print("Write \(url.path)")
			try text.write(to: url, atomically: true, encoding: .utf8)
			print("Done")
		} catch {
			print(">>>>>\(text) write error: \(error) to path \(url)")
		}

	}

}

extension Deploy {

	static func fromTSV(_ url: String) throws -> [Deploy] {
		let data = try Data(contentsOf: URL(string: url)!)
		var map = [Int: Deploy.NamedKey]()
		let deploys: [Deploy]
		do {
			let tsv = String(data: data, encoding: .utf8)!.components(separatedBy: "\n")
			guard tsv.count > 1 else { print("TSV should have more than 1 line"); exit(-1) }
			let keys = tsv[0].components(separatedBy: "\t")
			print("Raw keys: \(keys)")
			keys.enumerated().forEach { (idx, key) in
				map[idx] = Deploy.NamedKey(rawValue: key.fixedValue())
			}
			print("Found keys: \(map.map({ "\($0.key):\($0.value.rawValue)" }))")
			deploys = tsv.dropFirst().map { Deploy(string: $0, map: map) }
		}
		return deploys
	}

}

//fileprivate extension String {
//
//	func ids(scale: Int) -> [Deploy.IdWithScale] {
//		return self.components(separatedBy: ",").map {
//			($0 as NSString).trimmingCharacters(in: CharacterSet(charactersIn: "0123456789:").inverted)
//		}.filter {
//			!$0.isEmpty
//		}.map {
//			Deploy.IdWithScale(id: $0, scale: scale)
//		}
//	}
//
//}
