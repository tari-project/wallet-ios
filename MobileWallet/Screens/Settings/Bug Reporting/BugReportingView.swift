//  BugReportingView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 28/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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
import TariCommon

final class BugReportingView: BaseNavigationContentView {
    
    // MARK: - Subviews
    
    @View private var headerLabel: UILabel = {
        let view = UILabel()
        view.text = localized("bug_reporting.label.header")
        view.textColor = .tari.text.heading
        view.font = .Avenir.medium.withSize(13.0)
        return view
    }()
    
    @View private var nameTextField: UITextField = {
        let view = UITextField()
        view.placeholder = localized("bug_reporting.text_field.name")
        view.font = .Avenir.medium.withSize(14.0)
        view.textColor = .tari.text.heading
        return view
    }()
    
    @View private var nameTextFieldSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .tari.separators.primary
        return view
    }()
    
    @View private var emailTextField: UITextField = {
        let view = UITextField()
        view.placeholder = localized("bug_reporting.text_field.email")
        view.font = .Avenir.medium.withSize(14.0)
        view.textColor = .tari.text.heading
        return view
    }()
    
    @View private var emailTextFieldSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .tari.separators.primary
        return view
    }()
    
    @View private var messageHeaderLabel: UILabel = {
        let view = UILabel()
        view.text = localized("bug_reporting.label.message_header")
        view.textColor = .tari.text.heading
        view.font = .Avenir.medium.withSize(13.0)
        return view
    }()
    
    @View private var messageTextView: UITextView = {
        let view = UITextView()
        view.backgroundColor = .tari.backgrounds.secondary
        view.layer.cornerRadius = 10.0
        view.textColor = .tari.text.heading
        view.font = .Avenir.medium.withSize(13.0)
        view.textContainerInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return view
    }()
    
    @View private var footerLabel: UILabel = {
        let view = UILabel()
        view.text = localized("bug_reporting.label.footer")
        view.textColor = .tari.text.body
        view.font = .Avenir.medium.withSize(14.0)
        view.numberOfLines = 0
        return view
    }()
    
    @View private var sendButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("bug_reporting.button.send"), for: .normal)
        return view
    }()
    
    @View private var logsButton: TextButton = {
        let view = TextButton()
        view.setVariation(.secondary)
        view.setTitle(localized("bug_reporting.button.view_logs"), for: .normal)
        return view
    }()
    
    // MARK: - Properties
    
    var name: String? { nameTextField.text }
    var email: String? { emailTextField.text }
    var message: String? { messageTextView.text }
    
    var isProcessing: Bool = false {
        didSet { updateSendButton() }
    }
    
    var onSendButtonTap: (() -> Void)?
    var onShowLogsButtonTap: (() -> Void)?
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        navigationBar.title = localized("bug_reporting.title")
        navigationBar.backButtonType = .close
    }
    
    private func setupConstraints() {
        
        [headerLabel, nameTextField, nameTextFieldSeparator, emailTextField, emailTextFieldSeparator, messageHeaderLabel, messageTextView, footerLabel, sendButton, logsButton].forEach { addSubview($0) }
        
        let constraints = [
            headerLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 34.0),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            nameTextField.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 26.0),
            nameTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            nameTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            nameTextFieldSeparator.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 26.0),
            nameTextFieldSeparator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            nameTextFieldSeparator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            nameTextFieldSeparator.heightAnchor.constraint(equalToConstant: 1.0),
            emailTextField.topAnchor.constraint(equalTo: nameTextFieldSeparator.bottomAnchor, constant: 26.0),
            emailTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            emailTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            emailTextFieldSeparator.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 26.0),
            emailTextFieldSeparator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            emailTextFieldSeparator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            emailTextFieldSeparator.heightAnchor.constraint(equalToConstant: 1.0),
            messageHeaderLabel.topAnchor.constraint(equalTo: emailTextFieldSeparator.bottomAnchor, constant: 20.0),
            messageHeaderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            messageHeaderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            messageTextView.topAnchor.constraint(equalTo: messageHeaderLabel.bottomAnchor, constant: 10.0),
            messageTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            messageTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            messageTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200.0), // TODO: !
            footerLabel.topAnchor.constraint(equalTo: messageTextView.bottomAnchor, constant: 20.0),
            footerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            footerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            sendButton.topAnchor.constraint(equalTo: footerLabel.bottomAnchor, constant: 20.0),
            sendButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            logsButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 20.0),
            logsButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            logsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            logsButton.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: -30.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        sendButton.onTap = { [weak self] in
            self?.onSendButtonTap?()
        }
        
        logsButton.onTap = { [weak self] in
            self?.onShowLogsButtonTap?()
        }
    }
    
    // MARK: - Updates
    
    private func updateSendButton() {
        sendButton.variation = isProcessing ? .loading : .normal
    }
}
