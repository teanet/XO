public extension Array where Element: Equatable {

	/// Remove Dublicates
	var unique: [Element] {
		// Thanks to https://github.com/sairamkotha for improving the method
		return self.reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
	}
}
