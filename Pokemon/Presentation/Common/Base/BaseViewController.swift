//
//  BaseViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit
import RxSwift

class BaseViewController: UIViewController {

    var disposeBag = DisposeBag()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setConstraints()
        setConfiguration()
    }

    func setView() { }
    func setConstraints() { }
    func setConfiguration() {
        self.view.backgroundColor = .white
    }
}
