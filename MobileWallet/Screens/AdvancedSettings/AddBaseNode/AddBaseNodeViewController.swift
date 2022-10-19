//  AddBaseNodeViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 19/07/2021
	Using Swift 5.0
	Running on macOS 12.0

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import Combine

final class AddBaseNodeViewController: SettingsParentViewController {

    // MARK: - Properties

    private let mainView = AddBaseNodeView()
    private let model = AddBaseNodeModel()
    private var cancelables: Set<AnyCancellable> = []

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFeedbacks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mainView.focusOnNameTextField()
    }

    // MARK: - Setups

    override func setupViews() {
        super.setupViews()

        view.addSubview(mainView)
        mainView.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            mainView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            mainView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = localized("add_base_node.title")
    }

    private func setupFeedbacks() {

        mainView.onTapOnSaveButton = { [weak self] in
            self?.model.viewModel.name = self?.mainView.name ?? ""
            self?.model.viewModel.peer = self?.mainView.peer ?? ""
            self?.model.saveNode()
        }

        model.viewModel.$isFinished
            .sink { [weak self] in
                guard $0 else { return }
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancelables)

        model.viewModel.$errorMessage
            .sink { [weak self] in
                guard let errorMessage = $0 else { return }
                self?.show(errorMessage: errorMessage)
            }
            .store(in: &cancelables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] in

                guard let keyboardFrame = $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let animationTime = $0.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
                else {
                    return
                }

                self?.mainView.update(bottomMargin: keyboardFrame.height, animationTime: animationTime)
            }
            .store(in: &cancelables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] in
                guard let animationTime = $0.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
                self?.mainView.update(bottomMargin: 0.0, animationTime: animationTime)
            }
            .store(in: &cancelables)
    }

    // MARK: - Actions

    private func show(errorMessage: String) {
        let controller = UIAlertController(title: localized("add_base_node.error.title"), message: errorMessage, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: localized("add_base_node.error.button"), style: .default, handler: nil))
        present(controller, animated: true)
    }
}
