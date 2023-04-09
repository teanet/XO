import Common

extension Api {

	func pages(
		token: String,
		projectId: String,
		page: String
	) throws -> Figma.Pages {
		try self.get(
			path: "files/\(projectId)/nodes",
			query: [
				"ids" : page,
				"depth": "1",
			],
			headers: [
				"X-FIGMA-TOKEN" : token
			],
			timeoutInterval: 300
		)
	}

	func images(
		token: String,
		projectId: String,
		ids: [String],
		scale: Int
	) throws -> Images {
		try self.get(
			path: "images/\(projectId)",
			query: [
				"ids" : ids.joined(separator: ","),
				"format": "jpg",
				"scale": "\(scale)",
			],
			headers: [
				"X-FIGMA-TOKEN" : token
			],
			timeoutInterval: 300
		)
	}

}
