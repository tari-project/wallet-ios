//  AddRecipientViewController.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/10
	Using Swift 5.0
	Running on macOS 10.15

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

class AddRecipientViewController: UIViewController, ContactsTableDelegate, ScanViewControllerDelegate {
    private let SIDE_PADDING = Theme.shared.sizes.appSidePadding
    private let INPUT_CORNER_RADIUS: CGFloat = 6
    private let INPUT_CONTAINER_HEIGHT: CGFloat = 90

    private let inputContainerView = UIView()
    private let inputBox = UITextField()
    private let scanButton = QRButton()
    private let continueButton = ActionButton()
    private var continueButtonBottomConstraint = NSLayoutConstraint()
    private let contactsTableVC = ContactsTableViewController(style: .grouped)
    private let pasteEmojisView = PasteEmojisView()
    private var pasteEmojisViewBottomAnchorConstraint = NSLayoutConstraint()
    private let dimView = UIView()

    private var isEditingSearchBox: Bool = false {
        didSet {
            if isEditingSearchBox {
                inputBox.becomeFirstResponder()
            } else {
                inputBox.resignFirstResponder()
            }
        }
    }

    private var selectedRecipientPublicKey: PublicKey? = nil {
        didSet {
            if selectedRecipientPublicKey != nil {
                inputBox.textAlignment = .center
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                contactsTableVC.tableView.removeFromSuperview()

                continueButtonBottomConstraint.isActive = false

                UIView.animate(withDuration: 0.5) { [weak self] in
                    guard let self = self else { return }
                    self.continueButtonBottomConstraint = self.continueButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.SIDE_PADDING)
                    self.continueButtonBottomConstraint.isActive = true
                    self.inputContainerView.layer.shadowOpacity = 0.1
                    self.view.layoutIfNeeded()
                }
            } else {
                inputBox.textAlignment = .left
                continueButtonBottomConstraint.isActive = false
                continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100)
                continueButtonBottomConstraint.isActive = true
            }
        }
    }

    private var clipboardEmojis: String = "" {
        didSet {
            if clipboardEmojis.isEmpty {
                pasteEmojisView.isHidden = true
            } else {
                pasteEmojisView.setEmojis(emojis: clipboardEmojis) { [weak self] in
                    guard let self = self else { return }

                    do {
                        let pubKey = try PublicKey(privateKey: PrivateKey()) //TODO add back real check // try PublicKey(emojis: self.clipboardEmojis)
                        self.onAdd(publicKey: pubKey)
                    } catch {
                        UserFeedback.shared.error(
                            title: NSLocalizedString("Could not use Emoji ID", comment: "Add recipient screen"),
                            description: "Failed to create a valid contact from the pasted Emoji ID",
                            error: error)
                    }

                    self.inputBox.text = self.clipboardEmojis
                    self.isEditingSearchBox = false
                }
                pasteEmojisView.isHidden = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contactsTableVC.actionDelegate = self

        setup()
        hideKeyboardWhenTappedAroundOrSwipedDown()
        contactsTableVC.tableView.keyboardDismissMode = .interactive
        inputBox.addTarget(self, action: #selector(textInputidChange(_:)), for: .editingChanged)
        setupPasteEmojisView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        styleNavigatorBar(isHidden: false)

        //If they're going back a view, don't check the clipboard if they already have text in it
        if self.inputBox.text?.isEmpty ?? true {
            checkClipboard()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(showClipboardEmojis), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideClipboardEmojis), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isEditingSearchBox = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        clipboardEmojis = ""
    }

    @objc private func openScanner() {
        let vc = ScanViewController()
        vc.actionDelegate = self as ScanViewControllerDelegate
        vc.modalPresentationStyle = .popover
        present(vc, animated: true, completion: nil)
    }

    @objc private func textInputidChange(_ textField: UITextField) {
        if let text = textField.text {
            //TODO as soon as it's a valid emoji ID, init a pub key

            contactsTableVC.filter = text
        }
    }

    private func setup() {
        styleNavigatorBar(isHidden: false)
        view.backgroundColor = Theme.shared.colors.appBackground
        navigationItem.title = NSLocalizedString("Send To", comment: "Navigation bar title on send view screen")

        setupContactInputBar()
        setupContactsTable()
        setupContinueButton()
        setupDimView()
    }

    private func setupContactInputBar() {
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputContainerView)

        //Container view layout
        inputContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        inputContainerView.heightAnchor.constraint(equalToConstant: INPUT_CONTAINER_HEIGHT).isActive = true
        inputContainerView.backgroundColor = Theme.shared.colors.navigationBarBackground

        //Container view style
        inputContainerView.layer.shadowOpacity = 0
        inputContainerView.layer.shadowOffset = CGSize(width: 0, height: 5)
        inputContainerView.layer.shadowRadius = 10
        inputContainerView.layer.shadowColor = Theme.shared.colors.navigationBottomShadow!.cgColor

        //Input layout
        inputBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBox)
        inputBox.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor).isActive = true
        inputBox.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: SIDE_PADDING).isActive = true
        inputBox.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        inputBox.heightAnchor.constraint(equalToConstant: 46).isActive = true

        //Input style
        inputBox.placeholder = NSLocalizedString("Enter Emoji ID or Contact Name", comment: "Add recipient view")
        inputBox.backgroundColor = Theme.shared.colors.appBackground
        inputBox.font = Theme.shared.fonts.searchContactsInputBoxText

        inputBox.leftView = UIView(frame: CGRect(x: 0, y: 0, width: SIDE_PADDING / 2, height: inputBox.frame.height))
        inputBox.leftViewMode = .always

        inputBox.layer.cornerRadius = INPUT_CORNER_RADIUS
        inputBox.layer.shadowOpacity = 0.15
        inputBox.layer.shadowOffset = CGSize(width: 0, height: 0)
        inputBox.layer.shadowRadius = INPUT_CORNER_RADIUS
        inputBox.layer.shadowColor = Theme.shared.colors.navigationBottomShadow!.cgColor

        //Scan button
        inputBox.rightView = scanButton
        inputBox.rightViewMode = .always
        scanButton.addTarget(self, action: #selector(openScanner), for: .touchUpInside)
    }

    private func setupContactsTable() {
        contactsTableVC.tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contactsTableVC.tableView)

        contactsTableVC.tableView.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor).isActive = true
        contactsTableVC.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contactsTableVC.tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contactsTableVC.tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    private func setupContinueButton() {
        continueButton.setTitle(NSLocalizedString("Continue", comment: "Add recipient view"), for: .normal)
        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SIDE_PADDING).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -SIDE_PADDING).isActive = true
        continueButtonBottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 200)
        continueButtonBottomConstraint.isActive = true

        continueButton.addTarget(self, action: #selector(onContinue), for: .touchUpInside)
    }

    private func setupPasteEmojisView() {
        pasteEmojisView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pasteEmojisView)

        pasteEmojisView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pasteEmojisView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pasteEmojisView.heightAnchor.constraint(equalToConstant: 78).isActive = true

        pasteEmojisViewBottomAnchorConstraint = pasteEmojisView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100)
        pasteEmojisViewBottomAnchorConstraint.isActive = true

        pasteEmojisView.layer.shadowOpacity = 0.1
        pasteEmojisView.layer.shadowOffset = CGSize(width: 0, height: 5)
        pasteEmojisView.layer.shadowRadius = 10
        pasteEmojisView.layer.shadowColor = Theme.shared.colors.navigationBottomShadow!.cgColor
    }

    private func setupDimView() {
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0)
        view.addSubview(dimView)
        dimView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        dimView.isHidden = true
    }

    private func checkClipboard() {
        let pasteboardString: String? = UIPasteboard.general.string

        if let text = pasteboardString {
            do {
                //_ = try PublicKey(emojis: text)
                //TODO add real chec in once the lib is working
                if text.containsEmoji {
                    clipboardEmojis = text
                }
            } catch {
                //Not valid emojis, don't show them
                clipboardEmojis = ""
            }
        }
    }

    @objc private func showClipboardEmojis(notification: NSNotification) {
        if clipboardEmojis.isEmpty {
            return
        }

        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            pasteEmojisViewBottomAnchorConstraint.isActive = false

            self.dimView.isHidden = false
            dimView.addSubview(inputBox)
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.pasteEmojisViewBottomAnchorConstraint = self.pasteEmojisView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -keyboardHeight)
                self.pasteEmojisViewBottomAnchorConstraint.isActive = true
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.62)
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func hideClipboardEmojis() {
        if clipboardEmojis.isEmpty {
            return
        }

        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            guard let self = self else { return }
            self.pasteEmojisViewBottomAnchorConstraint.isActive = false
            self.pasteEmojisViewBottomAnchorConstraint = self.pasteEmojisView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 100)
            self.pasteEmojisViewBottomAnchorConstraint.isActive = true
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.dimView.isHidden = true
            self.view.addSubview(self.inputBox)
        }
    }

    func onScrollTopHit(_ isAtTop: Bool) {
        if isAtTop {
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.inputContainerView.layer.shadowOpacity = 0
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.5) { [weak self] in
                guard let self = self else { return }
                self.inputContainerView.layer.shadowOpacity = 0.1
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func onContinue() {
        let amountVC = AddAmountViewController()
        amountVC.publicKey = selectedRecipientPublicKey
        self.navigationController?.pushViewController(amountVC, animated: true)
    }

    func onSelect(publicKey: PublicKey) {
        //TODO this will probably set the emojis when we have the custom emoji view
        inputBox.text = publicKey.emojis.0
        inputBox.rightView = nil

        //Remove table and show continue button
        selectedRecipientPublicKey = publicKey
    }

    func onSelect(contact: Contact) {
        let (publicKey, publicKeyError) = contact.publicKey
        guard publicKeyError == nil else {
            return
        }

        onSelect(publicKey: publicKey!)
    }

    //Used by the scanner and paste from clipboard
    func onAdd(publicKey: PublicKey) {
        onSelect(publicKey: publicKey)
    }
}
