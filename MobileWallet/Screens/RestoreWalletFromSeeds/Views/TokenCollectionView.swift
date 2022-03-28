//  TokenCollectionView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/07/2021
	Using Swift 5.0
	Running on macOS 12.0

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

struct SeedWordModel: Identifiable, Hashable {

    enum State {
        case valid
        case invalid
        case editing
    }
    
    enum VisualTrait {
        case none
        case deleteIcon
        case hidden
    }

    let id: UUID
    let title: String
    let state: State
    let visualTrait: VisualTrait
}

final class TokenCollectionView: UIView {

    // MARK: - Subviews

    private let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: TokenViewFlowLayout())
        view.contentInsetAdjustmentBehavior = .always
        view.backgroundColor = .clear
        view.register(type: TokenView.self)
        view.register(type: TokenInputView.self)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private weak var tokensToolbar: TokensToolbar? {
        didSet {
            updateAutocompletionTokens()
            updateAutocompletionMessage()
            updateTokensToolbarVisibility()
        }
    }
    
    private var textField: UITextField? {
        let inputView = collectionView.subviews.first { $0 is TokenInputView }
        return (inputView as? TokenInputView)?.textField
    }

    // MARK: - Properties
    
    var seedWords: [SeedWordModel] = [] {
        didSet { reloadData() }
    }
    
    var isTokenToolbarVisible: Bool = false {
        didSet { updateTokensToolbarVisibility() }
    }
    
    var autocompletionTokens: [TokenViewModel] = [] {
        didSet { updateAutocompletionTokens() }
    }
    
    var autocompletionMessage: String? {
        didSet { updateAutocompletionMessage() }
    }
    
    var updatedInputText: String = "" {
        didSet {
            textField?.text = updatedInputText
            inputText = updatedInputText
        }
    }
    
    var onRemovingCharacterAtFirstPosition: ((String) -> Void)?
    var onSelectSeedWord: ((_ row: Int) -> Void)?
    var onEndEditing: (() -> Void)?
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, SeedWordModel>?
    private var heightConstraint: NSLayoutConstraint?
    
    @Published private(set) var inputText: String = ""
    
    // MARK: - Initializers

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupFeedbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = Theme.shared.colors.tokenCollectionViewBackground
        layer.cornerRadius = 10.0
        collectionView.backgroundView = UIView()
    }

    private func setupConstraints() {

        addSubview(collectionView)
        
        let heightConstraint = heightAnchor.constraint(equalToConstant: 0.0)
        heightConstraint.priority = .defaultLow
        self.heightConstraint = heightConstraint

        let constraints = [
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {

        let dataSource = UICollectionViewDiffableDataSource<Int, SeedWordModel>(collectionView: collectionView) { [weak self] collectionView, indexPath, model in

            guard let self = self else { return UICollectionViewCell() }
            
            switch model.state {
            case .editing:
                let cell = collectionView.dequeueReusableCell(type: TokenInputView.self, indexPath: indexPath)
                cell.onTextChange = { self.handleOnTextChange(text: $0) }
                cell.onRemovingCharacterAtFirstPosition = { self.handleRemovingCharacterAtFirstPosition(text: $0) }
                cell.onEndEditing = { self.handleTapOnReturnButton(text: $0) }
                self.tokensToolbar = cell.toolbar
                return cell
            case .valid, .invalid:
                let cell = collectionView.dequeueReusableCell(type: TokenView.self, indexPath: indexPath)
                cell.text = model.title
                cell.isValid = model.state == .valid
                cell.isDeleteIconVisible = model.visualTrait == .deleteIcon
                cell.isHidden = model.visualTrait == .hidden
                
                return cell
            }
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapOutsideAction))

        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.backgroundView?.addGestureRecognizer(tapGestureRecognizer)
        
        self.dataSource = dataSource
    }
    
    // MARK: - Actions
    
    private func handleOnTextChange(text: String) {
        inputText = text
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func handleRemovingCharacterAtFirstPosition(text: String) {
        onRemovingCharacterAtFirstPosition?(text)
    }

    private func handleTapOnReturnButton(text: String) {
        onEndEditing?()
    }

    private func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, SeedWordModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(seedWords)
        dataSource?.apply(delayedSnapshot: snapshot, animatingDifferences: true) { [weak self] in
            guard let self = self else { return }
            self.collectionView.scrollToBottom(animated: true)
            self.heightConstraint?.constant = self.collectionView.contentSize.height
        }
    }
    
    private func updateAutocompletionTokens() {
        tokensToolbar?.tokenModels = autocompletionTokens
    }
    
    private func updateAutocompletionMessage() {
        tokensToolbar?.text = autocompletionMessage
    }
    
    private func updateTokensToolbarVisibility() {
        tokensToolbar?.isHidden = !isTokenToolbarVisible
    }

    // MARK: - Target Actions

    @objc private func onTapOutsideAction() {
        textField?.becomeFirstResponder()
    }

    // MARK: - First Responder

    override func resignFirstResponder() -> Bool {
        textField?.resignFirstResponder() ?? false
    }
}

extension TokenCollectionView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectSeedWord?(indexPath.row)
    }
}

private final class TokenViewFlowLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        minimumLineSpacing = 5.0
        minimumInteritemSpacing = 5.0
        sectionInset = UIEdgeInsets(top: 15.0, left: 18.0, bottom: 18.0, right: 15.0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0

        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }

        return attributes
    }
}
