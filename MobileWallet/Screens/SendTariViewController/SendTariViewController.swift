//  SendTariView.swift

/*
	Package MobileWallet
	Created by Gugulethu on 2019/11/11
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

import Foundation
import UIKit

class SendTariViewController: UIViewController {

    enum CardFillStates: CGFloat {
        case setupState = 50.0
        case dismissState = 100.0
        case displayReceipientInfo = 194.0
        case displayingContacts = 292.0
        case displayClipboard = 402.0
        case validID = 233.0
    }

    lazy var sendTariView: SendTariCardView = {
        let view = SendTariCardView()
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.shared.colors.transactionViewValueLabel!.withAlphaComponent(0.7)
        setupCard()

        /*
            Functions to Simulate the Heigh Changes of the View.
            Will be removed in next PR
         */
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissCardView)))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        animateCard(forCardState: SendTariViewController.CardFillStates.displayReceipientInfo)
    }

    private func setupCard() {
        self.view.addSubview(sendTariView)
        self.setupCardFrame(forCardState: SendTariViewController.CardFillStates.setupState)

        /*
         Functions to Simulate the Heigh Changes of the View.
         Will be removed in next PR
        */
        sendTariView.isUserInteractionEnabled = true
        sendTariView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(updateHeight)))
    }

    /*
     Card animation manager to handle the change in the card states
     */
    private func animateCard(forCardState cardState: CardFillStates) {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.setupCardFrame(forCardState: cardState)
            self.view.layoutIfNeeded()
        }) { (_) in
            //  TO DO: Do any view setup
        }
    }

    private func setupCardFrame(forCardState cardState: CardFillStates) {
        let viewHeight = self.view.frame.height
        let viewWidth = self.view.frame.width

        switch cardState {
        case .setupState:
            sendTariView.frame = CGRect(x: 0,
                                        y: viewHeight + CardFillStates.setupState.rawValue,
                                        width: viewWidth,
                                        height: viewHeight + CardFillStates.setupState.rawValue)
        case .dismissState:
            sendTariView.frame = CGRect(x: 0,
                                        y: viewHeight + CardFillStates.dismissState.rawValue,
                                        width: viewWidth,
                                        height: viewHeight + CardFillStates.dismissState.rawValue)
            view.backgroundColor = Theme.shared.colors.transactionViewValueLabel!.withAlphaComponent(0.0)
        default:
            sendTariView.frame = CGRect(x: 0,
                                        y: viewHeight - cardState.rawValue,
                                        width: viewWidth,
                                        height: cardState.rawValue)
        }
    }

    /*
     Functions to Simulate the Heigh Changes of the View.
     Will be removed when setting up the view
    */
    @objc func updateHeight() {
        self.animateCard(forCardState: SendTariViewController.CardFillStates.displayingContacts)
    }

    /*
     Removes of the card and controller in an animated approach
     */
    @objc func dismissCardView() {
        self.animateCard(forCardState: SendTariViewController.CardFillStates.dismissState)
        self.perform(#selector(dismissView), with: self, afterDelay: 0.2)
    }

    @objc func dismissView() {
        self.dismiss(animated: true) {
            //  TO DO: Any setup when dismissing the controller
        }
    }

}
