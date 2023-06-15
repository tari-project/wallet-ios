//  RotaryMenuOverlay.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/06/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class RotaryMenuOverlay: UIViewController {

    // MARK: - Properties

    var onMenuButtonTap: ((_ contactID: UUID, _ menuItem: UInt) -> Void)?

    private let mainView: RotaryMenuOverlayView = {
        switch UserSettingsManager.rotaryMenuPosition {
        case .left:
            return RotaryMenuOverlayView(presentationSide: .left)
        case .right:
            return RotaryMenuOverlayView(presentationSide: .right)
        }
    }()

    private let contactID: UUID

    // MARK: - Initialisers

    init(model: ContactsManager.Model) {
        contactID = model.id
        super.init(nibName: nil, bundle: nil)

        if let avatarImage = model.avatarImage {
            mainView.avatar = .image(avatarImage)
        } else {
            mainView.avatar = .text(model.avatar)
        }

        mainView.models = model.menuItems.map { $0.buttonViewModel }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupController()
        setupCallbacks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showOverlay()
    }

    // MARK: - Setups

    private func setupController() {
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }

    private func setupCallbacks() {

        mainView.onMenuButtonTap = { [weak self] in
            guard let self else { return }
            self.onMenuButtonTap?(self.contactID, $0)
        }

        mainView.onCloseButtonTap = { [weak self] in
            Task {
                self?.dismiss()
            }
        }

        mainView.onSwitchSideButtonTap = { [weak self] in
            self?.switchPresentationSide()
        }
    }

    // MARK: - Actions

    private func showOverlay() {
        Task {
            await mainView.show()
        }
    }

    private func dismiss() {
        Task {
            await mainView.hide()
            dismiss(animated: true)
        }
    }

    private func switchPresentationSide() {

        let userSettingsPosition: UserSettings.RotaryMenuPosition
        let viewPosition: RotaryMenuOverlayView.PresentationSide

        switch mainView.presentationSide {
        case .left:
            userSettingsPosition = .right
            viewPosition = .right
        case .right:
            userSettingsPosition = .left
            viewPosition = .left
        }

        UserSettingsManager.rotaryMenuPosition = userSettingsPosition

        Task {
            await mainView.switchSide(presentationSide: viewPosition)
        }
    }
}

private extension ContactBookModel.MenuItem {

    var buttonViewModel: RotaryMenuView.MenuButtonViewModel { RotaryMenuView.MenuButtonViewModel(id: rawValue, icon: icon, title: title) }

    private var icon: UIImage? {
        switch self {
        case .send:
            return .icons.send
        case .addToFavorites:
            return .icons.star.filled
        case .removeFromFavorites:
            return .icons.star.border
        case .link:
            return .icons.link
        case .unlink:
            return .icons.unlink
        case .details:
            return .icons.profile
        }
    }

    private var title: String? {
        switch self {
        case .send:
            return localized("contact_book.details.menu.option.send")
        case .addToFavorites:
            return localized("contact_book.details.menu.option.add_to_favorites")
        case .removeFromFavorites:
            return localized("contact_book.details.menu.option.remove_from_favorites")
        case .link:
            return localized("contact_book.details.menu.option.link")
        case .unlink:
            return localized("contact_book.details.menu.option.unlink")
        case .details:
            return localized("contact_book.menu.option.details")
        }
    }
}
