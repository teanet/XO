import Common
import Foundation

final class ScreenshotDownloader {

	private let outputURL: URL
	private let token: String
	private let projectId: String
	private let api: Api
	private let cacheURL: URL

	init(figmaApi: Api, outputURL: URL, token: String, projectId: String) {
		self.outputURL = outputURL
		self.token = token
		self.projectId = projectId
		self.api = figmaApi

		self.cacheURL = self.outputURL.appendingPathComponent("screenshots_cache")
		let fm = FileManager.default
		try? fm.createDirectory(at: self.cacheURL, withIntermediateDirectories: true, attributes: [:])
	}

	private func downloadIds(_ ids: [String], repeatCount: Int = 5, scale: Int) -> Images? {
		if repeatCount < 0 {
			return nil
		}
		do {
			let images = try self.api.images(
				token: self.token,
				projectId: self.projectId,
				ids: ids,
				scale: scale
			)
			if let err = images.err {
				print("⛔️ Download error \(repeatCount - 1), try one more time: \(err)")
				return self.downloadIds(ids, repeatCount: repeatCount - 1, scale: scale)
			} else {
				return images
			}
		} catch {
			print("⛔️ Download batch error \(repeatCount - 1), try one more time after 15 sec: \(error.locd)")
			Thread.sleep(forTimeInterval: 15)
			return self.downloadIds(ids, repeatCount: repeatCount - 1, scale: scale)
		}
	}

	func download(ids: [String], scale: Int) -> [Images] {
		let downloadIDs = ids.unique
		let batch = 10
		var allImages = [Images]()
		for idx in stride(from: downloadIDs.indices.lowerBound, to: downloadIDs.indices.upperBound, by: batch) {
			print("⬇️ Fetching image batch: \(idx)")
			let subsequence = downloadIDs[idx..<min(idx.advanced(by: batch), downloadIDs.count)]
			if let images = self.downloadIds(Array(subsequence), repeatCount: 6, scale: scale) {
				allImages.append(images)
				self.downloadImages(images)
			} else {
				print("💥 Download batch error, maybe we should limit requests other way")
				exit(1)
			}
		}
		return allImages
	}

	private func downloadImages(_ images: Images) {
		DispatchQueue.global().async {
			if let images = images.images {
				_ = DownloadBatch(images: images, url: self.cacheURL).download()
			}
		}
	}

	func download(screens: [Figma.Screen]) throws {
		var imageIDs2x = [String]()
		var imageIDs3x = [String]()

		for screen in screens {
			switch screen.device.scale {
				case 2:
					imageIDs2x.append(screen.id)
				case 3:
					imageIDs3x.append(screen.id)
				default:
					fatalError("🚨Unknown scale \(screen.device.scale)")
			}
		}

		var allImages = [Images]()
		allImages += self.download(ids: imageIDs2x, scale: 2)
		allImages += self.download(ids: imageIDs3x, scale: 3)

		var allImagesKeys = [String: String]()
		allImages
			.compactMap { $0.images }
			.filter { !$0.isEmpty }
			.forEach { (images) in
				for image in images {
					allImagesKeys[image.key] = image.value
				}
			}
		let imageData = DownloadBatch(images: allImagesKeys, url: self.cacheURL).download()

		let screenshotsURL = self.outputURL.appendingPathComponent("screenshots")
		let fm = FileManager.default
		do {
			try fm.removeItem(at: screenshotsURL)
		} catch {
			print("Remove screenshots error: \(error)")
		}
		try fm.createDirectory(at: screenshotsURL, withIntermediateDirectories: true, attributes: [:])
		print("ℹ️ Process screenshots at \(screenshotsURL)")
		for screen in screens {

			let localeURL = screenshotsURL.localeURL(for: screen)
			do {
				try fm.createDirectory(at: localeURL, withIntermediateDirectories: true, attributes: [:])

				if let data = imageData[screen.id] {
					print("ℹ️ Save screenshot \(localeURL.lastPathComponent)/\(screen.fileName)")
					do {
						try data.write(to: localeURL.appendingPathComponent(screen.fileName))
					} catch {
						print("⛔️ Save screenshot error: \(error.locd)")
					}
				}
			} catch {
				print("⛔️ Create locale folder error: \(error.locd)")
			}
		}
	}

}

extension URL {
	func localeURL(for screen: Figma.Screen) -> URL {
		var url = self
		if screen.device.isIMessage {
			// скриншоты для iMessage должны лежать в папке iMessage/Locale/###.jpg
			url.appendPathComponent("iMessage")
		}
		url.appendPathComponent(screen.locale)
		return url
	}
}

extension String {
	var cacheName: String {
		"\(self.MD5String).jpg"
	}
}
