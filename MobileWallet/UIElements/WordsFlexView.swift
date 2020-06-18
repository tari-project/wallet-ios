//  WordsFlexView.swift

/*
 Package MobileWallet
 Created by S.Shovkoplyas on 01.06.2020
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

import UIKit

protocol WordsFlexViewDelegate: class {
    func didSelectWord(word: String, intId: Int, phraseView: WordsFlexView)
}

class WordsFlexView: UIView {

    enum WordsFlexViewType {
        case selectable
        case fillable
    }

    weak var delegate: WordsFlexViewDelegate?
    let type: WordsFlexViewType

    private(set) var words = [String]()

    private var stackView = UIStackView()
    private var subStackViews = [UIStackView]()
    private var buttons = [UIButton]()

    private var minimumHeight: CGFloat
    private var maxCountInRaw: Int
    private var horizontalSpacing: CGFloat
    private var verticalSpacing: CGFloat
    private var minimumInsets: UIEdgeInsets
    private var cornerRadius: CGFloat
    private var showBorder: Bool

    private let font = Theme.shared.fonts.settingsRecoveryPhraseWorld!
    private let textColor = Theme.shared.colors.settingsRecoveryPhraseWorldText!
    private let textBackgroundColor = UIColor.clear
    private let buttonBorderColor = Theme.shared.colors.settingsRecoveryPhraseWorldBorder!

    private var heightConstraint: NSLayoutConstraint?

    init(type: WordsFlexViewType,
         words: [String],
         width: CGFloat,
         minimumHeight: CGFloat = 27,
         maxCountInRaw: Int = 4,
         horizontalSpacing: CGFloat = 12,
         verticalSpacing: CGFloat = 14,
         minimumInsets: UIEdgeInsets = UIEdgeInsets(top: 6.0, left: 12.0, bottom: 6.0, right: 12),
         cornerRadius: CGFloat = 5.0,
         showBorder: Bool = true) {

        self.type = type
        self.minimumHeight = minimumHeight
        self.maxCountInRaw = maxCountInRaw
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.minimumInsets = minimumInsets
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder

        self.words = words

        super.init(frame: .zero)
        setup(words: words, width: width)
    }

    init(type: WordsFlexViewType,
         minimumHeight: CGFloat,
         maxCountInRaw: Int = 4,
         horizontalSpacing: CGFloat = 12,
         verticalSpacing: CGFloat = 14,
         minimumInsets: UIEdgeInsets = UIEdgeInsets(top: 6.0, left: 12.0, bottom: 6.0, right: 12),
         cornerRadius: CGFloat = 5.0,
         showBorder: Bool = true) {

        self.type = type
        self.minimumHeight = minimumHeight
        self.maxCountInRaw = maxCountInRaw
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.minimumInsets = minimumInsets
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder

        super.init(frame: .zero)
        self.minimumHeight = minimumHeight
        setupStackView(horizontalStackViews: [UIStackView]())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addWord(_ word: String, intId: Int) {
        let newButton = createButton(word: word, intId: intId)

        buttons.append(newButton)
        words.append(word)

        if let lastStackView = findLastFreeSubStackView(for: newButton) {
            var existingButtons = lastStackView.subviews.filter({ $0 is UIButton })
            existingButtons.append(newButton)
            stackView.removeArrangedSubview(lastStackView)
            subStackViews.removeAll(where: { $0 == lastStackView })

            let newStack = horizontalStackView(with: existingButtons, intrinsicWidth: bounds.width)
            subStackViews.append(newStack)
            stackView.addArrangedSubview(newStack)
        } else {
            let newStackView = horizontalStackView(with: [newButton], intrinsicWidth: bounds.width)
            subStackViews.append(newStackView)
            stackView.addArrangedSubview(newStackView)
        }

        heightConstraint?.constant = heightForStackView()
    }

    func restore(word: String, intId: Int) {
        if type != .selectable { return }
        if let button = buttons.first(where: {$0.tag == intId}) {
            if button.titleLabel?.text == word {
                UIView.animate(withDuration: CATransaction.animationDuration()) {
                    button.alpha = 1.0
                }
            }
        }
    }

    @objc private func buttonAction(_ sender: UIButton) {
        guard let word = sender.titleLabel?.text, let index = buttons.firstIndex(of: sender) else { return }

        if type == .fillable {
            words.remove(at: index)
            buttons.remove(at: index)
        }

        delegate?.didSelectWord(word: word, intId: sender.tag, phraseView: self)

        UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
            sender.alpha = 0.0
        }) { [weak self] (_) in
            guard let self = self else { return }
            switch self.type {
            case .fillable: do {
                self.stackView.removeFromSuperview()
                self.stackView = UIStackView()
                self.subStackViews = self.createSubStackViews(intrinsicWidth: self.bounds.width)
                self.setupStackView(horizontalStackViews: self.subStackViews)
                }
            default: break
            }
        }
    }
}

// MARK: Private Methods
extension WordsFlexView {
    private func setup(words: [String], width: CGFloat) {
        buttons = createButtons(words: words)
        subStackViews = createSubStackViews(intrinsicWidth: width)
        setupStackView(horizontalStackViews: subStackViews)
    }

    private func findLastFreeSubStackView(for button: UIButton) -> UIStackView? {
        var buttonsCount = 0
        var width: CGFloat = 0

        subStackViews.last?.subviews.forEach({
            if let button = $0 as? UIButton {
                buttonsCount += 1
                width += (button.titleLabel?.intrinsicContentSize.width ?? 0.0) + minimumInsets.left + minimumInsets.right
            }
        })

        width += CGFloat(buttonsCount - 1) * horizontalSpacing

        let buttonWidth = (button.titleLabel?.intrinsicContentSize.width ?? 0.0) + minimumInsets.left + minimumInsets.right

        if buttonsCount < maxCountInRaw && bounds.width > (width + buttonWidth + horizontalSpacing) {
            return subStackViews.last
        } else {
            return nil
        }
    }
    private func createButtons(words: [String]) -> [UIButton] {
        var buttons = [UIButton]()
        words.forEach({
            buttons.append(createButton(word: $0, intId: UUID().hashValue))
        })
        return buttons
    }

    private func createButton(word: String, intId: Int) -> UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        button.setTitle(word, for: .normal)
        button.titleLabel?.font = font
        button.tag = intId
        button.backgroundColor = textBackgroundColor
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(textColor.withAlphaComponent(0.5), for: .highlighted)

        button.layer.cornerRadius = cornerRadius
        button.layer.borderColor = showBorder ? buttonBorderColor.cgColor : UIColor.clear.cgColor
        button.layer.borderWidth = 1.0
        button.layer.masksToBounds = true
        let widthConstraint =  button.widthAnchor.constraint(equalToConstant: ((button.titleLabel?.intrinsicContentSize.width ?? 0.0) + minimumInsets.left + minimumInsets.right))
        widthConstraint.isActive = true
        widthConstraint.priority = .defaultHigh

        return button
    }

    private func createSubStackViews(intrinsicWidth: CGFloat) -> [UIStackView] {
        var width: CGFloat = 0.0
        var stackViews = [UIStackView]()
        var currentStack = [UIView]()

        buttons.forEach({
            let buttonWidth = ($0.titleLabel?.intrinsicContentSize.width ?? 0.0) + minimumInsets.left + minimumInsets.right

            let newWidth = width + buttonWidth

            if newWidth <= intrinsicWidth {
                currentStack.append($0)
            }

            if currentStack.count == maxCountInRaw {
                stackViews.append(horizontalStackView(with: currentStack, intrinsicWidth: intrinsicWidth))
                currentStack.removeAll()
                width = 0.0
                return
            }

            if newWidth > intrinsicWidth {
                stackViews.append(horizontalStackView(with: currentStack, intrinsicWidth: intrinsicWidth))
                currentStack.removeAll()
                currentStack.append($0)

                width = 0.0
            }

            if $0 == buttons.last {
                stackViews.append(horizontalStackView(with: currentStack, intrinsicWidth: intrinsicWidth))
                currentStack.removeAll()

                width = 0.0

            }

            width += (buttonWidth + horizontalSpacing)
        })

        return stackViews
    }

    private func horizontalStackView(with views: [UIView], intrinsicWidth: CGFloat) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = horizontalSpacing

        views.forEach {
            stackView.addArrangedSubview($0)
        }
        return stackView
    }

    private func setupStackView(horizontalStackViews: [UIStackView]) {
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = verticalSpacing
        stackView.alignment = .leading

        horizontalStackViews.forEach {
            stackView.addArrangedSubview($0)
        }

        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        heightConstraint = stackView.heightAnchor.constraint(equalToConstant: heightForStackView())
        heightConstraint?.isActive = true
    }

    private func heightForStackView() -> CGFloat {
        let labelHeight = (buttons.first?.titleLabel?.font.pointSize ?? 0.0) + minimumInsets.top + minimumInsets.bottom
        let height: CGFloat = CGFloat(subStackViews.count) * labelHeight + CGFloat(subStackViews.count - 1) * stackView.spacing
        return height < minimumHeight ? minimumHeight : height
    }
}
