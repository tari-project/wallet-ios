//  Text+Typography.swift
	
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

public extension Font {
    static var heading2XL: Font {
        .poppins(.semiBold, size: 24)
    }
    
    static var headingXL: Font {
        .poppins(.semiBold, size: 18)
    }
    
    static var headingLarge: Font {
        .poppins(.semiBold, size: 16)
    }
    
    static var headingMedium: Font {
        .poppins(.semiBold, size: 14)
    }
    
    static var headingSmall: Font {
        .poppins(.semiBold, size: 12)
    }
    
    static var body: Font {
        .poppins(.medium, size: 16)
    }
    
    static var body2: Font {
        .poppins(.medium, size: 14)
    }
    
    static var modalTitleLarge: Font {
        .poppins(.medium, size: 24)
    }
    
    static var modalTitle: Font {
        .poppins(.semiBold, size: 16)
    }
    
    static var menuItem: Font {
        .poppins(.regular, size: 18)
    }
    
    static var textButton: Font {
        .poppins(.semiBold, size: 14)
    }
    
    static var buttonLarge: Font {
        .poppins(.semiBold, size: 15)
    }
    
    static var buttonMedium: Font {
        .poppins(.semiBold, size: 14)
    }
    
    static var buttonSmall: Font {
        .poppins(.semiBold, size: 12)
    }
}

public extension View {
    func heading2XL() -> some View {
        font(.heading2XL)
    }
    
    func headingXL() -> some View {
        font(.headingXL)
    }
    
    func headingLarge() -> some View {
        font(.headingLarge)
    }
    
    func headingMedium() -> some View {
        font(.headingMedium)
    }
    
    func headingSmall() -> some View {
        font(.headingSmall)
    }
    
    func body() -> some View {
        font(.body)
    }
    
    func body2() -> some View {
        font(.body2)
    }
    
    func modalTitleLarge() -> some View {
        font(.modalTitleLarge)
    }
    
    func modalTitle() -> some View {
        font(.modalTitle)
    }
    
    func menuItem() -> some View {
        font(.menuItem)
    }
    
    func textButton() -> some View {
        font(.textButton)
    }
    
    func buttonLarge() -> some View {
        font(.buttonLarge)
    }
    
    func buttonMedium() -> some View {
        font(.buttonMedium)
    }
    
    func buttonSmall() -> some View {
        font(.buttonSmall)
    }
}

public extension Text {
    func heading2XL() -> Text {
        font(.heading2XL)
    }
    
    func headingXL() -> Text {
        font(.headingXL)
    }
    
    func headingLarge() -> Text {
        font(.headingLarge)
    }
    
    func headingMedium() -> Text {
        font(.headingMedium)
    }
    
    func headingSmall() -> Text {
        font(.headingSmall)
    }
    
    func body() -> Text {
        font(.body)
    }
    
    func body2() -> Text {
        font(.body2)
    }
    
    func modalTitleLarge() -> Text {
        font(.modalTitleLarge)
    }
    
    func modalTitle() -> Text {
        font(.modalTitle)
    }
    
    func menuItem() -> Text {
        font(.menuItem)
    }
    
    func textButton() -> Text {
        font(.textButton)
    }
    
    func buttonLarge() -> Text {
        font(.buttonLarge)
    }
    
    func buttonMedium() -> Text {
        font(.buttonMedium)
    }
    
    func buttonSmall() -> Text {
        font(.buttonSmall)
    }
}
