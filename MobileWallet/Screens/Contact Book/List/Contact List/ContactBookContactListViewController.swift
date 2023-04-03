//  ContactBookContactListViewController.swift

/*
	Package MobileWallet
	Created by Browncoat on 21/02/2023
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

final class ContactBookContactListViewController: UIViewController {

    // MARK: - Properties

    var models: [ContactBookContactListView.Section] {
        get { mainView.viewModels }
        set { mainView.viewModels = newValue }
    }

    var selectedRows: Set<UUID> {
        get { mainView.selectedRows }
        set { mainView.selectedRows = newValue }
    }

    var placeholderViewModel: ContactBookListPlaceholder.ViewModel? {
        get { mainView.placeholderViewModel }
        set { mainView.placeholderViewModel = newValue }
    }

    var isPlaceholderVisible: Bool {
        get { mainView.isPlaceholderVisible }
        set { mainView.isPlaceholderVisible = newValue }
    }

    var isFooterVisible: Bool {
        get { mainView.isFooterVisible }
        set { mainView.isFooterVisible = newValue }
    }

    var onFooterTap: (() -> Void)? {
        get { mainView.onFooterTap }
        set { mainView.onFooterTap = newValue }
    }

    var onRowTap: ((UUID) -> Void)? {
        get { mainView.onRowTap }
        set { mainView.onRowTap = newValue }
    }

    var isInSharingMode: Bool {
        get { mainView.isInSharingMode }
        set { mainView.isInSharingMode = newValue }
    }

    var onButtonTap: ((UUID, UInt) -> Void)?

    private let mainView = ContactBookContactListView()

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    // MARK: - Sutups

    private func setupCallbacks() {
        mainView.onButtonTap = { [weak self] in self?.onButtonTap?($0, $1) }
    }
}
