//  ThemeSettingsViewController.swift

/*
	Package MobileWallet
	Created by Browncoat on 18/12/2022
	Using Swift 5.0
	Running on macOS 13.0

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

final class ThemeSettingsViewController: UIViewController {

    // MARK: - Properties

    private let mainView = ThemeSettingsView()
    private let model: ThemeSettingsModel

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initalisers

    init(model: ThemeSettingsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
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
        setupCallbacks()
        model.reloadData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        Publishers.CombineLatest(model.$elements, model.$selectedIndex)
            .sink { [weak self] elements, selectedIndex in
                let viewModels = elements.map { ThemeSettingsView.ViewModel(id: $0.id, image: $0.element.image, title: $0.element.title) }
                self?.mainView.update(viewModels: viewModels, selectedIndex: selectedIndex)
            }
            .store(in: &cancellables)

        mainView.onCellSelected = { [weak self] in
            self?.model.select(elementIndex: $0.row)
        }
    }
}

private extension ThemeSettingsModel.Element {

    var image: UIImage? {
        switch self {
        case .system:
            return Theme.shared.images.colorThemeSystem
        case .light:
            return Theme.shared.images.colorThemeLight
        case .dark:
            return Theme.shared.images.colorThemeDark
        case .purple:
            return Theme.shared.images.colorThemePurple
        }
    }

    var title: String? {
        switch self {
        case .system:
            return localized("theme_switcher.element.title.system")
        case .light:
            return localized("theme_switcher.element.title.light")
        case .dark:
            return localized("theme_switcher.element.title.dark")
        case .purple:
            return localized("theme_switcher.element.title.purple")
        }
    }
}
