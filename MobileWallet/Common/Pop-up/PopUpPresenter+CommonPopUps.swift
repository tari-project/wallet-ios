//  PopUpPresenter+CommonPopUps.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/04/2022
	Using Swift 5.0
	Running on macOS 12.3

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

struct PopUpDialogModel {
    let title: String?
    let message: String?
    let buttons: [PopUpDialogButtonModel]
    let hapticType: PopUpPresenter.Configuration.HapticType
}

struct PopUpDialogButtonModel {
    
    enum ButtonType {
        case normal
        case destructive
        case text
        case textDimmed
    }
    
    let title: String
    let icon: UIImage?
    let type: ButtonType
    let callback: (() -> Void)?
    
    init(title: String, icon: UIImage? = nil, type: ButtonType, callback: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.type = type
        self.callback = callback
    }
}

struct MessageModel {
    
    enum MessageType {
        case normal
        case error
    }
    
    let title: String
    let message: String?
    let type: MessageType
}

extension PopUpPresenter {
    
    static func show(message: MessageModel) {
        let model = PopUpDialogModel(title: message.title, message: message.message, buttons: [], hapticType: makeHapticType(model: message))
        showPopUp(model: model)
        log(message: message)
    }
    
    static func showMessageWithCloseButton(message: MessageModel, onCloseButtonAction: (() -> Void)? = nil) {
        
        let model = PopUpDialogModel(
            title: message.title,
            message: message.message,
            buttons: [PopUpDialogButtonModel(title: localized("common.close"), type: .text, callback: onCloseButtonAction)],
            hapticType: makeHapticType(model: message)
        )
        
        showPopUp(model: model)
        log(message: message)
    }
    
    static func showPopUp(model: PopUpDialogModel) {
        
        var headerView: UIView?
        var contentView: UIView?
        var buttonsView: UIView?
        
        if let title = model.title {
            headerView = PopUpComponentsFactory.makeHeaderView(title: title)
        }
        
        if let message = model.message {
            contentView = PopUpComponentsFactory.makeContentView(message: message)
        }
        
        if !model.buttons.isEmpty {
            buttonsView = PopUpComponentsFactory.makeButtonsView(models: model.buttons)
        }
        
        let popUp = TariPopUp(headerSection: headerView, contentSection: contentView, buttonsSection: buttonsView)
        let configuration = makeConfiguration(model: model)
        show(popUp: popUp, configuration: configuration)
    }
    
    private static func log(message: MessageModel) {
        var log = "Pop-up Title=\(message.title)"
        
        if let description = message.message {
            log += " Message=\(description)"
        }
        
        switch message.type {
        case .normal:
            TariLogger.info(log)
        case .error:
            TariLogger.error(log)
        }
    }
    
    // MARK: - Helpers
    
    private static func makeHapticType(model: MessageModel) -> Configuration.HapticType {
        switch model.type {
        case .error:
            return .error
        case .normal:
            return .none
        }
    }
    
    private static func makeConfiguration(model: PopUpDialogModel) -> Configuration {
        model.buttons.isEmpty ? .message(hapticType: model.hapticType) : .dialog(hapticType: model.hapticType)
    }
}

extension PopUpPresenter.Configuration {
    
    static func message(hapticType: Self.HapticType) -> Self {
        Self(displayDuration: 12.0, dismissOnTapOutsideOrSwipe: true, hapticType: hapticType)
    }
    
    static func dialog(hapticType: Self.HapticType) -> Self {
        Self(displayDuration: nil, dismissOnTapOutsideOrSwipe: false, hapticType: hapticType)
    }
}
