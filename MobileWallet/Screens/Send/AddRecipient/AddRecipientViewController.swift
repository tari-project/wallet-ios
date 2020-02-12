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

class AddRecipientViewController: UIViewController, ContactsTableDelegate {
    private let SIDE_PADDING = Theme.shared.sizes.appSidePadding
    private let INPUT_CORNER_RADIUS: CGFloat = 6
    private let INPUT_CONTAINER_HEIGHT: CGFloat = 90

    private let inputContainerView = UIView()
    private let inputBox = UITextField()
    private let scanButton = QRButton()

    private let contactsTableVC = ContactsTableViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        contactsTableVC.actionDelegate = self

        setup()
    }

    func found(code: String) {
        //TODO something with the code
        UserFeedback.shared.info(title: "Scanned", description: "")
    }

    @objc func openScanner() {
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        guard let vc = storyBoard.instantiateViewController(identifier: "ScanViewController") as? ScanViewController else { return }
        vc.delegate = self as? ScanViewControllerDelegate
        vc.modalPresentationStyle = .popover
        present(vc, animated: true, completion: nil)
    }

    private func setup() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        view.backgroundColor = Theme.shared.colors.appBackground
        navigationItem.title = NSLocalizedString("Send to", comment: "Navigation bar title on send view screen")

        setupContactInputBar()
        setupContactsTable()
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
        inputContainerView.addSubview(inputBox)
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

        //inputContainerView.bringSubviewToFront(view)
    }

    func onScrollTopHit(_ isAtTop: Bool) {
        if isAtTop {
            UIView.animate(withDuration: 0.5) {
                self.inputContainerView.layer.shadowOpacity = 0
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.inputContainerView.layer.shadowOpacity = 0.1
                self.view.layoutIfNeeded()
            }
        }
    }

    func onSelect(contact: Contact) {
        UserFeedback.shared.success(title: "Selected \(contact.alias.0)")
    }
}
