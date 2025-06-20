//  TariButton.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 18.06.2025
	Using Swift 6.0
	Running on macOS 15.5

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

import SwiftUI

enum TariButtonStyle {
    case primary, secondary, outlined, text
}

enum TariButtonSize {
    case large, medium, small
}

struct TariButton: View {
    @Environment(\.isEnabled) var isEnabled
    let text: String
    let style: TariButtonStyle
    let size: TariButtonSize
    let action: () -> Void
    
    init(_ text: String, style: TariButtonStyle, size: TariButtonSize, action: @escaping () -> Void) {
        self.text = text
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(size.font)
                .foregroundStyle(isEnabled ? style.textColor : .disabled)
                .padding(size.horizontalPadding)
                .frame(maxWidth: size.width, maxHeight: size.height)
                .background {
                    ZStack {
                        if let background = style.backgroundColor {
                            Capsule()
                                .fill(isEnabled ? background : .disabledBackground)
                        }
                        if let stroke = style.strokeColor {
                            Capsule()
                                .stroke(isEnabled ? stroke : .disabledBackground, lineWidth: 1)
                        }
                    }
                }
        }
    }
}

private extension TariButtonStyle {
    var textColor: Color {
        switch self {
        case .primary: .primaryButtonText
        case .secondary: .Common.blackmain
        case .outlined, .text: .primaryText
        }
    }
    
    var backgroundColor: Color? {
        switch self {
        case .primary: .primaryText
        case .secondary: .primaryMain
        case .outlined, .text: nil
        }
    }
    
    var strokeColor: Color? {
        switch self {
        case .outlined: .buttonOutline
        case .primary, .secondary, .text: nil
        }
    }
}

private extension TariButtonSize {
    var horizontalPadding: CGFloat {
        switch self {
        case .large, .medium: 32
        case .small: 22
        }
    }
    
    var width: CGFloat? {
        switch self {
        case .large: .infinity
        case .medium, .small: nil
        }
    }
    
    var height: CGFloat {
        switch self {
        case .large: 50
        case .medium: 36
        case .small: 30
        }
    }
    
    var font: Font {
        switch self {
        case .large: .buttonLarge
        case .medium: .buttonMedium
        case .small: .buttonSmall
        }
    }
}

#Preview {
    VStack {
        TariButton("Tap me!", style: .primary, size: .large) { }
        TariButton("No me!", style: .secondary, size: .medium) { }
        TariButton("Button", style: .outlined, size: .small) { }
        TariButton("Disabled", style: .secondary, size: .medium) { }
            .disabled(true)
    }
    .padding()
}
