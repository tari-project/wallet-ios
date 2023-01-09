//  ThemeSettingsModel.swift

/*
	Package MobileWallet
	Created by Browncoat on 18/12/2022
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

import Combine

final class ThemeSettingsModel {

    enum Element {
        case system
        case light
        case dark
        case purple
    }

    struct ElementModel: Identifiable {
        let id: UUID
        let element: Element
    }

    // MARK: - View Model

    @Published var elements: [ElementModel] = [
        ElementModel(id: UUID(), element: .system),
        ElementModel(id: UUID(), element: .light),
        ElementModel(id: UUID(), element: .dark),
        ElementModel(id: UUID(), element: .purple)
    ]

    @Published var selectedIndex: Int = 0

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Actions

    func select(elementIndex: Int) {
        let selectedElement = elements[elementIndex].element
        update(selectedElement: selectedElement)
    }

    func reloadData() {

        let selectedElement: Element

        switch ThemeCoordinator.shared.colorScheme {
        case .system:
            selectedElement = .system
        case .light:
            selectedElement = .light
        case .dark:
            selectedElement = .dark
        case .tariPurple:
            selectedElement = .purple
        }

        selectedIndex = elements.firstIndex { $0.element == selectedElement } ?? 0
    }

    private func update(selectedElement: Element) {
        switch selectedElement {
        case .system:
            ThemeCoordinator.shared.colorScheme = .system
        case .light:
            ThemeCoordinator.shared.colorScheme = .light
        case .dark:
            ThemeCoordinator.shared.colorScheme = .dark
        case .purple:
            ThemeCoordinator.shared.colorScheme = .tariPurple
        }
    }
}
