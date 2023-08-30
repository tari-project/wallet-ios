//  TransactionHistoryCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 05/07/2023
	Using Swift 5.0
	Running on macOS 13.4

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
import GiphyUISDK
import Combine

final class TransactionHistoryCell: DynamicThemeCell {

    struct ViewModel: Hashable, Identifiable {

        let id: UInt64
        let avatar: RoundedAvatarView.Avatar
        let title: [StylizedLabel.StylizedText]
        let timestamp: TimeInterval
        let info: String?
        let note: String?
        let giphyID: String?
        let amount: AmountBadge.ViewModel

        static func == (lhs: TransactionHistoryCell.ViewModel, rhs: TransactionHistoryCell.ViewModel) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    // MARK: - Subviews

    @View private var avatarView = RoundedAvatarView()

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4.0
        view.alignment = .leading
        return view
    }()

    @View private var titleLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.normalFont = .Avenir.medium.withSize(14.0)
        view.boldFont = .Avenir.heavy.withSize(14.0)
        view.separator = " "
        return view
    }()

    @View private var timestampLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(11.0)
        return view
    }()

    @View private var infoLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(12.0)
        return view
    }()

    @View private var noteLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(15.0)
        view.numberOfLines = 0
        return view
    }()

    @View private var amountView = AmountBadge()
    @View private var loadingGifButton = LoadingGIFButton()

    private var gifView: GPHMediaView?

    // MARK: - Properties

    var onContentChange: (() -> Void)?

    private var dynamicModel: TransactionDynamicModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        selectionStyle = .none
    }

    private func setupConstraints() {

        [titleLabel, timestampLabel, infoLabel, noteLabel, loadingGifButton].forEach(stackView.addArrangedSubview)
        [avatarView, stackView, amountView].forEach(contentView.addSubview)

        let constraints = [
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20.0),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22.0),
            avatarView.widthAnchor.constraint(equalToConstant: 42.0),
            avatarView.heightAnchor.constraint(equalToConstant: 42.0),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20.0),
            stackView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 24.0),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20.0),
            amountView.topAnchor.constraint(equalTo: stackView.topAnchor),
            amountView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountView.leadingAnchor, constant: -4.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        loadingGifButton.onTap = { [weak self] in
            self?.dynamicModel?.fetchGif()
        }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        titleLabel.textColor = theme.text.body
        timestampLabel.textColor = theme.text.lightText
        infoLabel.textColor = theme.system.yellow
        noteLabel.textColor = theme.text.heading
    }

    func update(viewModel: ViewModel) {
        avatarView.avatar = viewModel.avatar
        titleLabel.textComponents = viewModel.title
        infoLabel.text = viewModel.info
        noteLabel.text = viewModel.note
        amountView.update(viewModel: viewModel.amount)

        dynamicModel = TransactionDynamicModel(timestamp: viewModel.timestamp, giphyID: viewModel.giphyID)

        dynamicModel?.$formattedTimestamp
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.timestampLabel.text = $0 }
            .store(in: &cancellables)

        dynamicModel?.$gif
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.update(gifState: $0) }
            .store(in: &cancellables)
    }

    private func update(gifState: TransactionDynamicModel.GifDataState) {

        switch gifState {
        case .none:
            loadingGifButton.isHidden = true
            gifView = nil
        case .loading:
            loadingGifButton.isHidden = false
            loadingGifButton.variation = .loading
        case let .loaded(gifMedia):
            loadingGifButton.isHidden = true
            update(gifMedia: gifMedia)
        case .failed:
            loadingGifButton.isHidden = false
            loadingGifButton.variation = .retry
        }

        onContentChange?()
    }

    private func update(gifMedia: GPHMedia) {

        let gifView = GPHMediaView()
        gifView.translatesAutoresizingMaskIntoConstraints = false
        gifView.media = gifMedia

        stackView.addArrangedSubview(gifView)

        let constraints = [
            gifView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            gifView.heightAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 1.0 / gifMedia.aspectRatio)
        ]

        NSLayoutConstraint.activate(constraints)

        self.gifView = gifView
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()

        dynamicModel = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        if let gifView {
            gifView.removeFromSuperview()
            stackView.removeArrangedSubview(gifView)
        }
    }
}
