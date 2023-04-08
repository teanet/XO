extension IApi {
	@discardableResult
	func makeMove(state: GameState, completion: @escaping ResponseBlock<GameState>) -> Cancellable {
		self.mehtod(.post, path: "/game/makeMove", body: state, completion: completion)
	}
	@discardableResult
	func reset(completion: @escaping ResponseBlock<GameState>) -> Cancellable {
		self.mehtod(.post, path: "/reset", completion: completion)
	}
}

struct GameState: Codable {
	let state: [GameMove]
}

struct GameMove: Codable {
	let x: Int
	let y: Int
	let value: String
}

enum Sign: String {
	case cross = "X"
	case zero = "O"

	mutating func toggle() {
		if self == .cross {
			self = .zero
		} else {
			self = .cross
		}
	}
}


//POST https://led-hackathon-api.test.crm.2gis.ru/game/makeMove
//Content-Type: application/json
//
//{
//	"state": [
//		{"x": 0, "y": 0, "value": "X"},
//		{"x": 0, "y": 0, "value": "O"},
//		{"x": 0, "y": 0, "value": "Empty"}
//	]
//}

