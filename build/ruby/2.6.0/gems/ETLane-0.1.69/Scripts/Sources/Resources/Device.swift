enum Device: String {
	case iPhone8
	case iPhone11
	case iPhone8Messages = "iPhone8-message"
	case iPhone11Messages = "iPhone11-message"
	case iPadPro
	case iPadPro3Gen
	case iPadProMessages = "iPadPro-message"
	case iPadPro3GenMessages = "iPadPro3Gen-message"
	case watch = "Watch"
	case watch4 = "Watch Series4"
}

extension Device {
	var scale: Int {
		switch self {
			case .iPhone8, .iPhone11, .iPhone8Messages, .iPhone11Messages: return 3
			case .iPadPro, .iPadPro3Gen, .iPadProMessages, .iPadPro3GenMessages, .watch, .watch4: return 2
		}
	}
	var isIMessage: Bool {
		switch self {
			case .iPadProMessages, .iPadPro3GenMessages, .iPhone8Messages, .iPhone11Messages: return true
			default: return false
		}
	}
	/// ipadPro129 это обязательный компонент имени для iPad 3 Gen, все остальное определяется по размерам
	var id: String {
		switch self {
			case .iPhone8: return "APP_IPHONE_55"
			case .iPhone11: return "APP_IPHONE_65"
			case .iPadPro: return "ipad-pro"
			case .iPadPro3Gen: return "ipadPro129"
			case .iPadProMessages: return "ipad-pro"
			case .iPadPro3GenMessages: return "ipadPro129"
			case .iPhone8Messages: return "APP_IPHONE_55"
			case .iPhone11Messages: return "APP_IPHONE_65"
			case .watch: return "APP_WATCH"
			case .watch4: return "APP_WATCH_SERIES_4"
		}
	}
}
