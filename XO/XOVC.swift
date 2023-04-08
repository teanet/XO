import SnapKit
import VNBase

final class XOVC: BaseVC<XOViewVM> {

	override func viewDidLoad() {
		super.viewDidLoad()

		let superStack = UIStackView()
		superStack.isUserInteractionEnabled = true
		superStack.axis = .vertical
		superStack.distribution = .equalSpacing
		superStack.spacing = 20
		for vmH in self.viewModel.vms {

			vmH.forEach {
				$0.onSelected = { [weak self] vm in
					self?.viewModel.processVM(vm)
				}
			}

			let views = vmH.map {
				let view = CrossView()
				view.viewModel = $0
				return view
			}
			let stack = UIStackView(arrangedSubviews: views)
			stack.axis = .horizontal
			stack.spacing = 20
			stack.distribution = .equalSpacing
			superStack.addArrangedSubview(stack)
		}

		self.view.addSubview(superStack) {
			$0.edges.equalToSuperview()
		}
		let gr = UITapGestureRecognizer(target: self, action: #selector(self.tap))
		self.view.addGestureRecognizer(gr)
	}

	@objc private func tap() {
		print(">>>>>\(123)")
	}


}

class XOViewVM: BaseViewControllerVM {
	enum Constants {
		static let count = 3
	}

	let vms: [[CrossVM]] = {
		var yVMs = [[CrossVM]]()
		for y in 0..<Constants.count {
			let xVMs = (0..<Constants.count).map {
				CrossVM(x: $0, y: y)
			}
			yVMs.append(xVMs)
		}
		return yVMs
	}()

	let api = ApiFactory.api(baseUrl: "https://led-hackathon-api.test.crm.2gis.ru", subsystem: "Cross")

	var allVMs: [CrossVM] {
		self.vms.flatMap { $0 }
	}

	var currentSign: Sign = .cross
	var isDone: Bool = false

	func reset() {
		self.allVMs.forEach {
			$0.sign = nil
			$0.isSuccess = false
		}
		self.isDone = false
	}

	func processVM(_ vm: CrossVM) {
		guard vm.sign == nil, !self.isDone else { return }

		vm.sign = self.currentSign

		let value = vm.sign?.rawValue ?? "Empty"
		let state = GameState(state: [GameMove(x: vm.x, y: vm.y, value: value)])
		self.api.makeMove(state: state) { r in
			print(">>>>>\(r)")
		}

		self.currentSign.toggle()
		self.checkCondition()
	}

	func checkCondition() {
		for lineIdx in (0..<self.vms.count) {
			if let rows = self.checkLine(at: lineIdx) {
				self.winRows(rows)
				return
			}
		}

		for lineIdx in (0..<self.vms[0].count) {
			if let rows = self.checkRow(at: lineIdx) {
				self.winRows(rows)
				return
			}
		}

		if let diagonal = self.checkDiagonal() {
			self.winRows(diagonal)
		}
	}

	private func winRows(_ rows: [CrossVM]) {
		for row in rows {
			row.isSuccess = true
		}
		self.isDone = true
	}

	private func checkLine(at idx: Int) -> [CrossVM]? {
		let vms = self.vms[idx]
		return self.checkVMsAreSame(vms)
	}

	private func checkVMsAreSame(_ vms: [CrossVM]) -> [CrossVM]? {
		guard let sign = vms[0].sign else { return nil }

		let isCompleted = vms.count == vms.filter { $0.sign == sign }.count

		return isCompleted ? vms : nil
	}

	private func checkRow(at idx: Int) -> [CrossVM]? {
		let vms = self.vms.map { $0[idx] }
		return self.checkVMsAreSame(vms)
	}

	private func checkDiagonal() -> [CrossVM]? {
		let vms1 = self.vms.enumerated().compactMap { idx, vms in
			vms[idx]
		}
		if let vms1 = self.checkVMsAreSame(vms1) {
			return vms1
		}

		let vms2 = self.vms.enumerated().compactMap { idx, vms in
			vms[Constants.count - idx - 1]
		}
		return self.checkVMsAreSame(vms2)
	}

}
