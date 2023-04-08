import SnapKit
import VNBase

final class CrossView: BaseView<CrossVM> {
	let dot = UIImageView()

	override init() {
		super.init()

		self.addSubview(dot) {
			$0.edges.equalToSuperview().inset(10)
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

		self.backgroundColor = (vm.isSuccess ? UIColor.yellow : .black).withAlphaComponent(0.1)

		switch vm.sign {
			case .cross:
				self.dot.image = .named("X")
			case .zero:
				self.dot.image = .named("O")
			case .none:
				self.dot.image = nil
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
