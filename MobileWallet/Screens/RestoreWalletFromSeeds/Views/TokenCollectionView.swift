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

final class TokenCollectionView: UIView {

    private final class TokenModel: Hashable {

        static func == (lhs: TokenModel, rhs: TokenModel) -> Bool { lhs === rhs }

        var text: String
        var isEditable: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(text)
            hasher.combine(isEditable)
        }

        init(text: String, isEditable: Bool) {
            self.text = text
            self.isEditable = isEditable
        }
    }

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

    // MARK: - Properties

    var tokens: AnyPublisher<[String], Never> {
        $tokenModels
            .map { $0.map(\.text).filter { !$0.isEmpty } }
            .eraseToAnyPublisher()
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
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, TokenModel>?
    
    @Published private(set) var inputText: String = ""
    @Published private var tokenModels: [TokenModel] = []
    
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

        let constraints = [
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {

        let dataSource = UICollectionViewDiffableDataSource<Int, TokenModel>(collectionView: collectionView) { [weak self] collectionView, indexPath, model in

            guard let self = self else { return UICollectionViewCell() }

            if model.isEditable {
                let cell = collectionView.dequeueReusableCell(type: TokenInputView.self, indexPath: indexPath)
                cell.onTextChange = { self.handleOnTextChange(text: $0) }
                cell.onRemovingCharacterAtFirstPosition = { self.handleRemovingCharacterAtFirstPosition(text: $0) }
                cell.onEndEditing = { self.handleTapOnReturnButton(text: $0) }
                self.tokensToolbar = cell.toolbar
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(type: TokenView.self, indexPath: indexPath)
                cell.text = model.text
                return cell
            }
        }

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapOutsideAction))

        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.backgroundView?.addGestureRecognizer(tapGestureRecognizer)

        self.dataSource = dataSource
    }

    func prepareView() {
        tokenModels = [TokenModel(text: "", isEditable: true)]
        dataReload()
    }

    // MARK: - Actions

    private func handleOnTextChange(text: String) -> String {

        defer { collectionView.scrollToBottom(animated: false) }

        var tokens = text.tokenize()

        guard tokens.count > 1 else {
            inputText = text
            collectionView.collectionViewLayout.invalidateLayout()
            return text
        }

        let lastToken = tokens.removeLast()
        let models = tokens.map { TokenModel(text: $0, isEditable: false) }
        let index = tokenModels.count - 1

        tokenModels.insert(contentsOf: models, at: index)
        dataReload()
        
        inputText = lastToken

        return lastToken
    }

    private func handleRemovingCharacterAtFirstPosition(text: String) -> String {

        defer { collectionView.collectionViewLayout.invalidateLayout() }

        guard tokenModels.count > 1 else { return text }

        let lastSubmittedTokenIndex = tokenModels.count - 2
        let lastSubmittedToken = tokenModels[lastSubmittedTokenIndex].text

        tokenModels.remove(at: lastSubmittedTokenIndex)
        dataReload()

        return lastSubmittedToken + text
    }

    private func handleTapOnReturnButton(text: String) -> String {
        guard !text.isEmpty else { return text }

        let model = TokenModel(text: text, isEditable: false)
        let index = tokenModels.count - 1
        tokenModels.insert(model, at: index)
        endEditing(true)
        dataReload()
        return ""
    }

    private func dataReload() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, TokenModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(tokenModels)
        dataSource?.apply(snapshot, animatingDifferences: true)
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
        let indexPath = IndexPath(item: tokenModels.count - 1, section: 0)
        collectionView.cellForItem(at: indexPath)?.becomeFirstResponder()
    }

    // MARK: - First Responder

    override func resignFirstResponder() -> Bool {
        let indexPath = IndexPath(item: tokenModels.count - 1, section: 0)
        return collectionView.cellForItem(at: indexPath)?.resignFirstResponder() ?? false

    }
}

extension TokenCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < tokenModels.count - 1 else { return }
        tokenModels.remove(at: indexPath.row)
        dataReload()
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
