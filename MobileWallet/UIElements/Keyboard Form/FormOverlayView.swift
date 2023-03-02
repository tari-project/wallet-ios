//  FormOverlayView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 01/03/2023
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

protocol FormShowable: UIView {
    var focusedView: UIView? { get }
    var initalReturkKeyType: UIReturnKeyType { get }
    var onCloseAction: (() -> Void)? { get set }
}

final class FormOverlayView: UIView, UIKeyInput {

    // MARK: - Properties

    var onCloseAction: (() -> Void)?

    private(set) var formView: FormShowable

    override var canBecomeFirstResponder: Bool { true }
    override var canResignFirstResponder: Bool { true }
    override var inputAccessoryView: UIView? { formView }

    // MARK: - UIKeyInput

    var returnKeyType: UIReturnKeyType = .default
    var hasText: Bool { false }

    func insertText(_ text: String) {}
    func deleteBackward() {}

    // MARK: - Initialisers

    init(formView: FormShowable) {
        self.formView = formView
        formView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)
        setupViews(formView: formView)
        setupCallbacks()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews(formView: FormShowable) {
        backgroundColor = .static.black?.withAlphaComponent(0.7)
        formView.translatesAutoresizingMaskIntoConstraints = false
        returnKeyType = formView.initalReturkKeyType
    }

    private func setupCallbacks() {
        formView.onCloseAction = { [weak self] in
            self?.onCloseAction?()
        }
    }
}
