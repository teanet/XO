import SnapKit
import VNBase

final class CrossView: BaseView<CrossVM> {
	override var intrinsicContentSize: CGSize {
		CGSize(width: 100, height: 100)
	}

	let dot = UIView()

	override init() {
		super.init()

		self.addSubview(dot) {
			$0.center.equalToSuperview()
			$0.size.equalTo(50)
		}

		let b = BlockButton { [weak self] _ in
			guard let vm = self?.viewModel else { return }

			vm.onSelected?(vm)
		}
		self.addSubview(b) {
			$0.edges.equalToSuperview()
		}
	}

	override func viewModelChanged() {
		super.viewModelChanged()
		guard let vm = self.viewModel else { return }

		self.backgroundColor = vm.isSuccess ? .yellow : .black

		switch vm.sign {
			case .cross:
				self.dot.backgroundColor = .green
			case .zero:
				self.dot.backgroundColor = .red
			case .none:
				self.dot.backgroundColor = .clear
		}

	}


}

final class CrossVM: BaseVM {

	var onSelected: ((CrossVM) -> Void)?
	let x: Int, y: Int
	init(x: Int, y: Int) {
		self.x = x
		self.y = y
	}

	var isSuccess: Bool = false {
		didSet {
			self.viewModelChanged()
		}
	}

	var sign: Sign? {
		didSet {
			self.viewModelChanged()
		}
	}
}
