import Common
import Foundation

final class PreviewDownloader {

	private let outputURL: URL
	private let session = URLSession.shared

	init(outputURL: URL) {
		self.outputURL = outputURL
	}

	func download(deploys: [Deploy]) throws {
		let downloadGroup = DispatchGroup()
		let fm = FileManager.default
		let previewsURL = self.outputURL.appendingPathComponent("previews")
		try fm.createDirectory(at: previewsURL, withIntermediateDirectories: true, attributes: [:])

		for deploy in deploys {
			let localeURL = previewsURL.appendingPathComponent(deploy[.locale])

			do {
				try fm.createDirectory(at: localeURL, withIntermediateDirectories: true, attributes: [:])
			} catch {
				print("Create locale folder error: \(error.locd)")
			}
			if let preview = URL(string: deploy[.iPhone8]) {
				let to = localeURL.appendingPathComponent("iphone58.mp4")
				downloadGroup.enter()
				self.download(from: preview, to: to) {
					downloadGroup.leave()
				}
			}
			if let preview = URL(string: deploy[.iPhone11]) {
				let to = localeURL.appendingPathComponent("iphone65.mp4")
				downloadGroup.enter()
				self.download(from: preview, to: to) {
					downloadGroup.leave()
				}
			}
			let timestamp = deploy[.previewTimestamp]
			if timestamp.isEmpty {
				do {
					let timestampURL = localeURL.appendingPathComponent("timestamp")
					try timestamp.write(to: timestampURL, atomically: true, encoding: .utf8)
					print("Save timestamp: \(timestamp)")
				} catch {
					print("Timestamp write error: \(error)")
				}
			}
			downloadGroup.wait()
		}

	}

	private func download(from: URL, to: URL, completion: @escaping () -> Void) {
		print("Download \(from) to: \(to)")
		let request = URLRequest(
			url: from,
			cachePolicy: .
			reloadIgnoringLocalCacheData,
			timeoutInterval: 5 * 60
		)
		self.session.downloadTask(with: request) { (url, response, error) in
			if let url = url, error == nil {
				do {
					try? FileManager.default.removeItem(at: to)
					try FileManager.default.copyItem(at: url, to: to)
					print("Did finish download: \(from)")
				} catch {
					print("Copy error: \(error)")
				}
			} else if let error = error {
				print("Download error: \(error)")
			}
			completion()
		}.resume()
	}

}
