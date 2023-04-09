import Foundation

class DownloadBatch {

	static let kMaximumDownloadsCount = 3

	private let images: [String: String]
	private var imagesLeft = [String: String]()
	private let downloadGroup = DispatchGroup()
	private let session = URLSession.shared
	private var imageData = [String: Data]()
	private var currentDownloadKeys = Set<String>()
	private let url: URL
	private let syncQueue = DispatchQueue(label: "download_image_q")
	private var isFinished = false

	init(images: [String: String], url: URL) {
		self.images = images
		self.imagesLeft = images
		self.url = url
	}

	func download() -> [Figma.PageId: Data] {
		self.downloadGroup.enter()
		self.downloadNext()
		self.downloadGroup.wait()
		return self.imageData
	}

	private func downloadNext() {
		let isFinished = self.syncQueue.sync {
			self.imagesLeft.isEmpty && self.currentDownloadKeys.isEmpty && !self.isFinished
		}
		let canDonwloadMore = self.syncQueue.sync {
			self.currentDownloadKeys.count < DownloadBatch.kMaximumDownloadsCount
		}
		if isFinished {
			self.isFinished = true
			print("Download batch finished: \(self.images)")
			self.downloadGroup.leave()
		} else if canDonwloadMore {

			if let first = self.imagesLeft.first {

				self.syncQueue.sync {
					self.imagesLeft.removeValue(forKey: first.key)
					self.currentDownloadKeys.insert(first.key)
				}
				self.downloadItem(key: first.key, value: first.value, retryCount: 5) { data in
					self.syncQueue.sync {
						self.imageData[first.key] = data
						_ = self.currentDownloadKeys.remove(first.key)
					}
					self.downloadNext()
				}
				self.downloadNext()
			}
		}
	}

	private func downloadItem(key: String, value: String, retryCount: Int, completion: @escaping (Data?) -> Void) {
		let data = self.syncQueue.sync {
			self.imageData[key]
		}
		if data != nil {
			completion(data); return
		}
		if retryCount < 0 {
			print("⛔️ Download image \(value) retry count limit")
			completion(nil); return
		}

		let fileUrl = self.url.appendingPathComponent(value.cacheName)

		if let data = try? Data(contentsOf: fileUrl) {
			print("✅ Image already exist at \(value.cacheName), skip download \(value)")
			completion(data)
			return
		}

		let imageURL = URL(string: value)!
		print("⬇️ Download image(\(retryCount)) with url: \(value)")
		let request = URLRequest(
			url: imageURL,
			cachePolicy: .reloadIgnoringLocalCacheData,
			timeoutInterval: 7 * 60
		)
		self.session.downloadTask(with: request) { (url, r, e) in
			if let url = url {
				do {
					let data = try Data(contentsOf: url)
					try data.write(to: fileUrl)
					print("✅ Did finish \(value) at \(value.cacheName)")
					completion(data)
				} catch {
					print("⛔️ Did fail download, retry: \(value), \(error)")
					self.downloadItem(key: key, value: value, retryCount: retryCount - 1, completion: completion)
				}
			} else {
				if let error = e {
					print("⛔️ Did fail download, retry: \(value), \(error)")
				}
				self.downloadItem(key: key, value: value, retryCount: retryCount - 1, completion: completion)
			}
		}.resume()
	}

}
