//  View+ObservableFrame.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 19.08.2025
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

extension View {
    func onSizeChange(action: @escaping (CGSize) -> Void) -> some View {
        modifier(ObservableFrame(preferenceKey: SizeKey.self, transform: { $0.size }, onFrameChange: action))
    }
    
    func onWidthChange(action: @escaping (CGFloat) -> Void) -> some View {
        modifier(ObservableFrame(preferenceKey: FloatKey.self, transform: { $0.size.width }, onFrameChange: action))
    }
    
    func onHeightChange(action: @escaping (CGFloat) -> Void) -> some View {
        modifier(ObservableFrame(preferenceKey: FloatKey.self, transform: { $0.size.height }, onFrameChange: action))
    }
}

private struct ObservableFrame<Key: PreferenceKey, Value: Equatable>: ViewModifier where Key.Value == Value {
    let preferenceKey: Key.Type
    let transform: (GeometryProxy) -> Value
    let onFrameChange: (Value) -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(sizeReader)
            .onPreferenceChange(preferenceKey, perform: onFrameChange)
    }

    private var sizeReader: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: preferenceKey, value: transform(geometry))
        }
    }
}

private struct FloatKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct SizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
