import Foundation
import OSLog

public enum Constants {
	static let baseURLDebug: String = "https://casino-zond-api-staging.web-staging.2gis.ru"
	static let pusherBaseURLDebug: String = "https://pusher.web-staging.2gis.ru"

	static let baseURLProd: String = "https://zond.api.2gis.ru"
	static let pusherBaseURLProd: String = "https://pusher.api.2gis.ru"

	//		"ru.doublegis.grymmobile\", \"ru.doublegis.grymmobile.ci\", \"com.urbigulf.2gis\", \"com.gis.maps.app\"}"
	public static let mainBundleId = "ru.doublegis.grymmobile"
}


public typealias ResponseBlock<T> = (Result<T, Error>) -> Void

public protocol IApi: AnyObject {
	var subsystem: String { get }
	var baseURL: String { get set }
	var headers: [String: String] { get set }

	func mehtod<T: Decodable>(
		_ method: Method,
		path: String,
		body: Encodable?,
		headers additionalHeaders: [String: String],
		completion: @escaping ResponseBlock<T>
	) -> Cancellable
}

public extension IApi {
	func mehtod<T: Decodable>(
		_ method: Method,
		path: String,
		body: Encodable? = nil,
		headers additionalHeaders: [String: String] = [:],
		completion: @escaping ResponseBlock<T>
	) -> Cancellable {
		self.mehtod(method, path: path, body: body, headers: additionalHeaders, completion: completion)
	}
}

public struct ApiFactory {
	public static func api(baseUrl: String, headers: [String: String] = [:], subsystem: String) -> IApi {
		Api(baseURL: baseUrl, headers: headers, subsystem: subsystem)
	}
}

public enum Method: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
}

class Api: IApi {

	enum ApiError: Error {
		case general
	}

	public let subsystem: String
	public var baseURL: String
	public var headers: [String: String]

	init(baseURL: String, headers: [String: String], subsystem: String) {
		self.baseURL = baseURL
		self.headers = headers
		self.subsystem = subsystem
	}

	private func logger(category: String) -> Logger {
		Logger(subsystem: self.subsystem, category: category)
	}

	@discardableResult
	public func mehtod<T: Decodable>(
		_ method: Method,
		path: String,
		body: Encodable?,
		headers additionalHeaders: [String: String] = [:],
		completion: @escaping ResponseBlock<T>
	) -> Cancellable {
		var cmp = URLComponents(string: self.baseURL)!
		cmp.path = path
		guard let url = cmp.url else { assertionFailure(); return EmptyCancellable() }

		var req = URLRequest(url: url, timeoutInterval: 10.0)
		req.httpMethod = method.rawValue
		if let body = body {
			req.httpBody = try? JSONEncoder().encode(body)
		}
		var headers = self.headers

		additionalHeaders.forEach { key, value in
			headers[key] = value
		}
		if method != .get {
			headers["Content-Type"] = "application/json"
		}
		req.allHTTPHeaderFields = headers
		self.logger(category: "Request").log(level: .default, "\(req)")
		let task = URLSession.shared.dataTask(with: req) { data, response, error in
			let result: Result<T, Error>
			if let data = data {
				do {
					let response = try JSONDecoder().decode(T.self, from: data)
					result = .success(response)
				} catch {
					if let str = String(data: data, encoding: .utf8) {
						self.logger(category: "Response").error("\(url)>>>\(str)<")
					}
					result = .failure(error)
				}
			} else if let error = error {
				result = .failure(error)
			} else {
				result = .failure(ApiError.general)
			}

			DispatchQueue.main.async {
				completion(result)
			}
		}
		
		task.resume()
		return task
	}
}

public struct Empty: Codable {}

public protocol Cancellable: AnyObject {
	func cancel()
}

extension URLSessionDataTask: Cancellable {}

private class EmptyCancellable: Cancellable {
	func cancel() {}
}
