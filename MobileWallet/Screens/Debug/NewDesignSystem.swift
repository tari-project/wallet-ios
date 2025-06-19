//  DesignSystemView.swift
	
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

struct NewDesignSystem: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                TariButton("Primary button large", style: .primary, size: .large) { }
                TariButton("Primary button medium", style: .primary, size: .medium) { }
                TariButton("Primary button small", style: .primary, size: .small) { }
                TariButton("Secondary button large", style: .secondary, size: .large) { }
                TariButton("Secondary button medium", style: .secondary, size: .medium) { }
                TariButton("Secondary button small", style: .secondary, size: .small) { }
                TariButton("Outlined button large", style: .outlined, size: .large) { }
                TariButton("Outlined button medium", style: .outlined, size: .medium) { }
                TariButton("Outlined button small", style: .outlined, size: .small) { }
                
                TariButton("Disabled Primary", style: .primary, size: .large) { }
                    .disabled(true)
                TariButton("Disabled Secondary", style: .secondary, size: .medium) { }
                    .disabled(true)
                TariButton("Disabled Outlined", style: .outlined, size: .small) { }
                    .disabled(true)
                
                Text("Body 1")
                    .body()
                Text("Body 2")
                    .body2()
                Text("Heading 2XL")
                    .heading2XL()
                Text("Heading XL")
                    .headingXL()
                Text("Heading large")
                    .headingLarge()
                Text("Heading medium")
                    .headingMedium()
                Text("Heading small")
                    .headingSmall()
                Text("Menu item")
                    .menuItem()
                Text("Modal title large")
                    .modalTitleLarge()
                Text("Modal title")
                    .modalTitle()
                Text("Text button")
                    .textButton()
                Text("Button large")
                    .buttonLarge()
                Text("Button medium")
                    .buttonMedium()
                Text("Button small")
                    .buttonSmall()
            }
            .padding()
        }
    }
}
