import Foundation

public final class Api {

	public struct NoContent: Decodable {
		init() {}
	}

	public enum ApiError: Error {
		case nilDataError
		case pathError
		case repeatCountLimitReached
	}

	enum Method: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
	}

	private let session = URLSession(configuration: URLSessionConfiguration.default)
	private let baseURL: URL

	public init(baseURL: String) {
		self.baseURL = URL(string: baseURL)!
	}

	public func get<T: Codable>(
		path: String,
		query: [String: String] = [:],
		headers: [String: String] = [:],
		timeoutInterval: TimeInterval
	) throws -> T {
		return try self.method(.get, path: path, query: query, headers: headers, timeoutInterval: timeoutInterval)
	}

	public func post<T: Codable, TBody: Encodable>(
		path: String,
		body: TBody,
		query: [String: String] = [:],
		headers: [String: String] = [:],
		timeoutInterval: TimeInterval
	) throws -> T {
		let body = try JSONEncoder().encode(body)
		return try self.method(.post, path: path, query: query, headers: headers, timeoutInterval: timeoutInterval, body: body)
	}

	private func get<T: Codable>(path: String, completion: @escaping (Result<T, Error>) -> Void) {
		self.method(.get, path: path, completion: completion)
	}

	private func post<T: Codable, TBody: Encodable>(
		path: String,
		body: TBody, headers: [String: String] = [:],
		completion: @escaping (Result<T, Error>) -> Void
	) {
		let body = try? JSONEncoder().encode(body)
		self.method(.post, path: path, headers: headers, body: body, completion: completion)
	}

	private func method<T: Decodable>(
		_ method: Method,
		path: String,
		query: [String: String] = [:],
		headers: [String: String] = [:],
		timeoutInterval: TimeInterval,
		body: Data? = nil
	) throws -> T {
		let s = DispatchSemaphore(value: 0)
		var statsResponse: Result<T, Error>!
		let completion: (Result<T, Error>) -> Void = { result in
			statsResponse = result
			s.signal()
		}
		self.method(
			method,
			path: path,
			query: query,
			headers: headers,
			body: body,
			timeoutInterval: timeoutInterval,
			completion: completion
		)
		s.wait()
		return try statsResponse.get()
	}

	private func method<T: Decodable>(
		_ method: Method,
		path: String,
		query: [String: String] = [:],
		headers: [String: String] = [:],
		body: Data? = nil,
		timeoutInterval: TimeInterval = 60,
		completion: @escaping (Result<T, Error>) -> Void
	) {
		let baseURL = self.baseURL.appendingPathComponent(path)
		var cmp = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
		cmp?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
		guard let url = cmp?.url else { completion(.failure(ApiError.pathError)); return }
		var request = URLRequest(url: url)
		request.timeoutInterval = timeoutInterval
		request.httpBody = body
		request.httpMethod = method.rawValue
		var allHTTPHeaderFields = headers
		if headers["content-type"] == nil {
			allHTTPHeaderFields["content-type"] = "application/json"
		}
		request.allHTTPHeaderFields = allHTTPHeaderFields
		print("Start request: \(method.rawValue) \(url)")
		self.session.dataTask(with: request) { (data, _, error) in

			if let error = error {
				completion(.failure(error))
				return
			}
			guard let data = data else {
				completion(.failure(ApiError.nilDataError))
				return
			}
			if data.isEmpty, let noContent = NoContent() as? T {
				completion(.success(noContent))
				return
			}

			if let string = String(data: data, encoding: .utf8)?.prefix(3000) {
				print("Finish: \(string)...")
			} else {
				print("Finish")
			}

			do {
				let response = try JSONDecoder().decode(T.self, from: data)
				completion(.success(response))
			} catch {
				print("Decode response \(url) error: \(error)")
				completion(.failure(error))
			}
		}.resume()
	}

}
