import Foundation

public extension Error {

	var locd: String {
		return "\(self.localizedDescription) - \(self)"
	}

}

