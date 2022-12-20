//  DynamicThemeView.swift
	
/*
	Package MobileWallet
	Created by Browncoat on 25/11/2022
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

import UIKit
import Combine

class DynamicThemeView: UIView, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeTabBar: UITabBar, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeTableView: UITableView, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeCollectionCell: UICollectionViewCell, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeCell: UITableViewCell, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeHeaderFooterView: UITableViewHeaderFooterView, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeBaseButton: BaseButton, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeToolbar: UIToolbar, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeTextField: UITextField, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeTextView: UITextView, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero, textContainer: nil)
        setupThemeCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

class DynamicThemeViewController: UIViewController, ThemeViewProtocol {
    
    // MARK: - Properties
    
    var themeManager: ThemeViewManager = ThemeViewManager()
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupThemeCallbacks()
    }
    
    // MARK: - Actions
    
    func update(theme: ColorTheme) {}
}

// MARK: - Misc

final class ThemeViewManager {
    
    var onThemeUpdate: ((_ theme: ColorTheme, _ isInitialUpdate: Bool) -> Void)?
    
    private var isInitialUpdate = true
    private var cancellables = Set<AnyCancellable>()
    
    func start() {
        
        guard isInitialUpdate else { return }
        
        ThemeCoordinator.shared.$theme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(theme: $0) }
            .store(in: &cancellables)
    }
    
    private func handle(theme: ColorTheme) {
        onThemeUpdate?(theme, isInitialUpdate)
        isInitialUpdate = false
    }
}

protocol ThemeViewProtocol: AnyObject {
    var themeManager: ThemeViewManager { get }
    func update(theme: ColorTheme)
}

extension ThemeViewProtocol {
    
    var theme: ColorTheme { ThemeCoordinator.shared.theme }
    
    fileprivate func setupThemeCallbacks() {
        
        themeManager.onThemeUpdate = { [weak self] in
            self?.update(theme: $0, isInitialUpdate: $1)
        }
        
        themeManager.start()
    }
    
    fileprivate func update(theme: ColorTheme, isInitialUpdate: Bool) {
        
        guard !isInitialUpdate else {
            update(theme: theme)
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.update(theme: theme)
        }
    }
}
