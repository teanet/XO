//
//  HelpVC.swift
//  XO
//
//  Created by teanet on 09.04.2023.
//

import UIKit
import VNBase

class HelpVC: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = .white

		let vc = XOVC(viewModel: XOViewVM())
		self.dgs_add(vc: vc, view: self.view) {
			$0.center.equalToSuperview()
			$0.size.equalTo(350)
		}
	}

}
