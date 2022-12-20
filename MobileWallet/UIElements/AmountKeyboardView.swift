//  AmountKeyboardView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 19/01/2022
	Using Swift 5.0
	Running on macOS 12.1

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
import TariCommon

final class AmountKeyboardView: DynamicThemeView {
    
    enum Key {
        case key(_ character: String)
        case delete
    }
    
    // MARK: - Constants
    
    private let numberOfButtonsInRow = 3
    
    // MARK: - Subviews
    
    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .equalSpacing
        return view
    }()
    
    // MARK: - Properties
    
    var onKeyTap: ((Key) -> Void)?
    
    var keypadSpacing: CGFloat {
        get { stackView.spacing }
        set { stackView.spacing = newValue }
    }
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    func setup(keys: [Key]) {
        
        keys
            .enumerated()
            .reduce(into: [UIStackView]()) { [weak self] result, element in
                
                guard let self = self else { return }
                
                let isNewLine = element.offset % self.numberOfButtonsInRow == 0
                let stackView: UIStackView
                
                if isNewLine {
                    stackView = self.makeRow()
                    result.append(stackView)
                } else {
                    stackView = result.last ?? UIStackView()
                }
                
                let button = self.makeButton(key: element.element)
                
                stackView.addArrangedSubview(button)
            }
            .forEach(stackView.addArrangedSubview)
        
        update(theme: theme)
    }
    
    private func setupConstraints() {
        
        addSubview(stackView)
        
        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Updates
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        
        stackView.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .compactMap { $0 as? BaseButton }
            .forEach {
                $0.setTitleColor(theme.text.heading, for: .normal)
                $0.tintColor = theme.text.heading
            }
    }
    
    // MARK: - Factories
    
    private func makeRow() -> UIStackView {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }
    
    private func makeButton(key: AmountKeyboardView.Key) -> BaseButton {
        let button = BaseButton(type: .system)
        
        button.titleLabel?.font = Theme.shared.fonts.keypadButton
        button.onTap = { [weak self] in self?.onKeyTap?(key) }
        
        switch key {
        case let .key(character):
            button.setTitle(character, for: .normal)
        case .delete:
            button.setImage(Theme.shared.images.delete, for: .normal)
        }
        
        return button
    }
}

extension Array where Element == AmountKeyboardView.Key {
    static var amountKeyboard: Self { [.key("1"), .key("2"), .key("3"), .key("4"), .key("5"), .key("6"), .key("7"), .key("8"), .key("9"), .key(MicroTari.decimalSeparator), .key("0"), .delete] }
}
