//  SystemMenuTableViewCell.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 27.05.2020
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

class SystemMenuTableViewCellItem: NSObject {
    let title: String

    @objc dynamic var mark: SystemMenuTableViewCell.SystemMenuTableViewCellMark = .none
    @objc dynamic var percent: Double = 0.0

    init(title: String, mark: SystemMenuTableViewCell.SystemMenuTableViewCellMark = .none) {
        self.title = title
        self.mark = mark
        super.init()
    }
}

class SystemMenuTableViewCell: UITableViewCell {

    @objc enum SystemMenuTableViewCellMark: Int {
        case none
        case attention
        case success
        case progress
    }

    private let arrow = UIImageView()
    private let markImageView = UIImageView()
    private let titleLabel = UILabel()
    private let progressView = CircularProgressView()

    private var kvoPercentToken: NSKeyValueObservation?
    private var kvoMarkToken: NSKeyValueObservation?

    var mark: SystemMenuTableViewCellMark = .none {
        didSet {
            if mark == oldValue { return }
            isUserInteractionEnabled = true
            switch mark {
            case .none: markImageView.image = nil; progressView.isHidden = true
            case .attention: markImageView.image = Theme.shared.images.attentionIcon!; progressView.isHidden = true
            case .success: markImageView.image = Theme.shared.images.successIcon!; progressView.isHidden = true
            case .progress: markImageView.image = nil; progressView.isHidden = false; isUserInteractionEnabled = false
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // should be overridden with empty body for fix blinking
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.contentView.alpha = 0.5
        } else {
            UIView.animate(withDuration: CATransaction.animationDuration(), delay: 0, options: .curveEaseIn, animations: {
                self.contentView.alpha = 1
            })
        }
    }

    func configure(_ item: SystemMenuTableViewCellItem) {
        titleLabel.text = item.title
        mark = item.mark
        observe(item: item)
    }

    private func observe(item: SystemMenuTableViewCellItem) {
        kvoPercentToken = item.observe(\.percent, options: .new) { [weak self] (item, _) in
            self?.progressView.setProgress(item.percent/100.0)
        }

        kvoMarkToken = item.observe(\.mark, options: .new) { [weak self] (item, _) in
            self?.mark = item.mark
        }
    }

    deinit {
        kvoPercentToken?.invalidate()
        kvoMarkToken?.invalidate()
    }
}

// MARK: Setup views
extension SystemMenuTableViewCell {
    private func setupView() {
        contentView.backgroundColor = Theme.shared.colors.systemTableViewCellBackground

        setupArrow()
        setupMark()
        setupProgressView()
        setupTitle()
    }

    override func prepareForReuse() {
        mark = .none
        titleLabel.text = nil

        kvoPercentToken?.invalidate()
        kvoMarkToken?.invalidate()
    }

    private func setupArrow() {
        contentView.addSubview(arrow)
        arrow.image = Theme.shared.images.forwardArrow

        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.widthAnchor.constraint(equalToConstant: 8).isActive = true
        arrow.heightAnchor.constraint(equalToConstant: 13).isActive = true
        arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        arrow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24).isActive = true
    }

    private func setupMark() {
        mark = .none
        markImageView.backgroundColor = .clear
        contentView.addSubview(markImageView)

        markImageView.translatesAutoresizingMaskIntoConstraints = false
        markImageView.widthAnchor.constraint(equalToConstant: 21).isActive = true
        markImageView.heightAnchor.constraint(equalToConstant: 21).isActive = true
        markImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        markImageView.trailingAnchor.constraint(equalTo: arrow.leadingAnchor, constant: -12).isActive = true
    }

    private func setupProgressView() {
        progressView.backgroundColor = .clear
        progressView.isHidden = true
        addSubview(progressView)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.widthAnchor.constraint(equalToConstant: 25).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        progressView.centerYAnchor.constraint(equalTo: markImageView.centerYAnchor).isActive = true
        progressView.centerXAnchor.constraint(equalTo: markImageView.centerXAnchor).isActive = true
    }

    private func setupTitle() {
        titleLabel.font = Theme.shared.fonts.systemableViewCell
        contentView.addSubview(titleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: markImageView.leadingAnchor, constant: -20).isActive = true
    }
}
