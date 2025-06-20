//  SwitchMenuCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 25/09/2023
	Using Swift 5.0
	Running on macOS 13.5

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

import TariCommon
import Combine

final class SwitchMenuCell: MenuCell {

    final class DynamicModel {
        @Published var switchValue: Bool = false
    }

    // MARK: - Subviews

    @TariView private var switchView = UISwitch()

    // MARK: - Properties

    weak var dynamicModel: DynamicModel? {
        didSet { setupDynamicModel() }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        replace(accessoryItem: switchView)
    }

    private func setupCallbacks() {
        switchView.addTarget(self, action: #selector(onSwitchValueChangeAction), for: .valueChanged)
    }

    private func setupDynamicModel() {

        cancellables.forEach { $0.cancel() }

        guard let dynamicModel else { return }

        dynamicModel.$switchValue
            .removeDuplicates()
            .sink { [weak self] in self?.switchView.isOn = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Targets

    @objc private func onSwitchValueChangeAction(switchView: UISwitch) {
        dynamicModel?.switchValue = switchView.isOn
    }
}
