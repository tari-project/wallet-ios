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
import TariCommon

class SystemMenuTableViewCellItem: NSObject {

    let icon: UIImage?
    
    @objc dynamic var title: String
    @objc dynamic var subtitle: String?
    @objc dynamic var mark: SystemMenuTableViewCell.SystemMenuTableViewCellMark = .none
    @objc dynamic var markDescription: String = ""
    @objc dynamic var percent: Double = 0.0

    @Published @objc dynamic var isSwitchIsOn: Bool = false

    private(set) var disableCellInProgress = true
    private(set) var hasSwitch = false
    private(set) var hasArrow = true
    private(set) var isDestructive = false

    init(icon: UIImage? = nil,
         title: String,
         subtitle: String? = nil,
         mark: SystemMenuTableViewCell.SystemMenuTableViewCellMark = .none,
         hasArrow: Bool = true,
         disableCellInProgress: Bool = true,
         hasSwitch: Bool = false,
         switchIsOn: Bool = false,
         isDestructive: Bool = false) {

        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.mark = mark
        self.hasArrow = hasArrow
        self.disableCellInProgress = disableCellInProgress
        self.hasSwitch = hasSwitch
        self.isSwitchIsOn = switchIsOn
        self.isDestructive = isDestructive
        super.init()
    }
}

class SystemMenuTableViewCell: DynamicThemeCell {

    @objc enum SystemMenuTableViewCellMark: Int {
        case none
        case attention
        case success
        case progress
        case scheduled
    }

    private weak var item: SystemMenuTableViewCellItem?

    @View private var iconImageView = UIImageView()
    @View private var labelsStackView = UIStackView()
    
    private let arrow = UIImageView()
    private var arrowWidthConstraint: NSLayoutConstraint?

    private let markImageView = UIImageView()
    private var markImageViewTrailingConstraint: NSLayoutConstraint?
    private let markDescriptionLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let progressView = CircularProgressView()
    private let switcher = UISwitch()

    private var disableCellInProgress = true

    private var kvoPercentToken: NSKeyValueObservation?
    private var kvoMarkToken: NSKeyValueObservation?
    private var kvoMarkDescriptionToken: NSKeyValueObservation?
    private var kvoTitleToken: NSKeyValueObservation?
    private var kvoSubtitleToken: NSKeyValueObservation?
    private var kvoSwitchValueToken: NSKeyValueObservation?
    
    private var titleWithoutIconConstraint: NSLayoutConstraint?
    private var titleWithIconConstraint: NSLayoutConstraint?
    
    private var normalTintColor: UIColor?
    private var destructiveTintColor: UIColor?
    
    private var isIconVisible: Bool = false {
        didSet { updateIconImageViewElement() }
    }

    private var mark: SystemMenuTableViewCellMark = .none {
        didSet {
            if mark == oldValue { return }
            isUserInteractionEnabled = true
            switcher.isHidden = true
            switch mark {
            case .none:
                markImageView.image = nil
                progressView.isHidden = true
                switcher.isHidden = !(item?.hasSwitch ?? false)
            case .attention:
                markImageView.image = Theme.shared.images.attentionIcon!
                progressView.isHidden = true
            case .success:
                markImageView.image = Theme.shared.images.successIcon!
                progressView.isHidden = true
            case .progress:
                markImageView.image = nil
                progressView.isHidden = false
                isUserInteractionEnabled = disableCellInProgress ? false : true
            case .scheduled:
                markImageView.image = Theme.shared.images.scheduledIcon!
                progressView.isHidden = true
            }
            
            updateMarkDescriptionLabelColor(theme: theme)
        }
    }
    
    private func updateMarkDescriptionLabelColor(theme: ColorTheme) {
        
        let markDescriptionLabelColor: UIColor?
        
        switch mark {
        case .none:
            markDescriptionLabelColor = .clear
        case .attention:
            markDescriptionLabelColor = theme.system.red
        case .success:
            markDescriptionLabelColor = theme.system.green
        case .progress:
            markDescriptionLabelColor = theme.text.body
        case .scheduled:
            markDescriptionLabelColor = theme.system.blue
        }
        
        markDescriptionLabel.textColor = markDescriptionLabelColor
    }

    private var markDescription: String = "" {
        didSet {
            markDescriptionLabel.text = markDescription
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

    @objc private func switchValueDidChange(_ sender: UISwitch) {
        item?.isSwitchIsOn = sender.isOn
    }

    func configure(_ item: SystemMenuTableViewCellItem, isDestructive: Bool = false) {
        self.item = item

        if !item.hasArrow {
            markImageViewTrailingConstraint?.constant = 0
            arrowWidthConstraint?.constant = 0
        }

        iconImageView.image = item.icon
        isIconVisible = item.icon != nil
        
        switcher.isOn = item.isSwitchIsOn
        switcher.isHidden = !item.hasSwitch
        arrow.isHidden = item.hasSwitch
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        arrow.image = Theme.shared.images.forwardArrow
        
        disableCellInProgress = item.disableCellInProgress
        mark = item.mark
        markDescription = item.markDescription
        observe(item: item)
        
        updateTintColor()
    }

    private func observe(item: SystemMenuTableViewCellItem) {
        kvoPercentToken = item.observe(\.percent, options: .new) { [weak self] (item, _) in
            self?.progressView.setProgress(item.percent/100.0)
        }

        kvoMarkToken = item.observe(\.mark, options: .new) { [weak self] (item, _) in
            self?.mark = item.mark
        }

        kvoMarkDescriptionToken = item.observe(\.markDescription, options: .new) { [weak self] (item, _) in
            self?.markDescription = item.markDescription
        }
        
        kvoTitleToken = item.observe(\.title, options: .new) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.titleLabel.text = item.title
            }
        }
        
        kvoSubtitleToken = item.observe(\.subtitle, options: .new) { [weak self] item, _ in
            self?.subtitleLabel.text = item.subtitle
        }

        kvoSwitchValueToken = item.observe(\.isSwitchIsOn, options: .new) { [weak self] (item, change) in
            if change.newValue == change.oldValue { return }
            self?.switcher.setOn(item.isSwitchIsOn, animated: true)
        }
    }
    
    private func updateIconImageViewElement() {
        
        guard isIconVisible else {
            titleWithIconConstraint?.isActive = false
            titleWithoutIconConstraint?.isActive = true
            return
        }
        
        titleWithoutIconConstraint?.isActive = false
        titleWithIconConstraint?.isActive = true
    }
    
    override func update(theme: ColorTheme) {
        
        contentView.backgroundColor = theme.backgrounds.primary
        subtitleLabel.textColor = theme.text.body
        normalTintColor = theme.text.heading
        destructiveTintColor = theme.system.red
        
        updateTintColor()
        updateMarkDescriptionLabelColor(theme: theme)
    }
    
    private func updateTintColor() {
        
        let isDestructive = item?.isDestructive ?? false
        let tintColor = isDestructive ? destructiveTintColor : normalTintColor
        
        iconImageView.tintColor = tintColor
        titleLabel.textColor = tintColor
        subtitleLabel.textColor = tintColor
        arrow.tintColor = tintColor
    }

    deinit {
        kvoPercentToken?.invalidate()
        kvoMarkToken?.invalidate()
        kvoMarkDescriptionToken?.invalidate()
    }
}

// MARK: Setup views
extension SystemMenuTableViewCell {
    private func setupView() {
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 65.0).isActive = true
        
        setupArrow()
        setupSwitch()
        setupMark()
        setupMarkDescription()
        setupProgressView()
        setupLabelsStackView()
        setupTitle()
        setupDescriptionLabel()
        setupIconImageView()
    }

    override func prepareForReuse() {
        mark = .none
        titleLabel.text = nil

        markImageViewTrailingConstraint?.constant = -12
        arrowWidthConstraint?.constant = 8

        kvoPercentToken?.invalidate()
        kvoMarkToken?.invalidate()
    }

    private func setupArrow() {
        contentView.addSubview(arrow)

        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrowWidthConstraint = arrow.widthAnchor.constraint(equalToConstant: 8)
        arrowWidthConstraint?.isActive = true
        arrow.heightAnchor.constraint(equalToConstant: 13).isActive = true
        arrow.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        arrow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25).isActive = true
    }

    private func setupMark() {
        mark = .none
        markImageView.backgroundColor = .clear
        contentView.addSubview(markImageView)

        markImageView.translatesAutoresizingMaskIntoConstraints = false
        markImageView.widthAnchor.constraint(equalToConstant: 21).isActive = true
        markImageView.heightAnchor.constraint(equalToConstant: 21).isActive = true
        markImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        markImageViewTrailingConstraint = markImageView.trailingAnchor.constraint(equalTo: arrow.leadingAnchor, constant: -12)
        markImageViewTrailingConstraint?.isActive = true
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

    private func setupSwitch() {
        addSubview(switcher)
        switcher.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
        switcher.isOn = item?.isSwitchIsOn ?? false

        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        switcher.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25).isActive = true
    }

    private func setupTitle() {
        titleLabel.font = Theme.shared.fonts.systemTableViewCell
        titleLabel.adjustsFontSizeToFitWidth = true
        labelsStackView.addArrangedSubview(titleLabel)
    }
    
    private func setupDescriptionLabel() {
        subtitleLabel.font = Theme.shared.fonts.systemTableViewCell
        subtitleLabel.adjustsFontSizeToFitWidth = true
        labelsStackView.addArrangedSubview(subtitleLabel)
    }
    
    private func setupLabelsStackView() {
        
        labelsStackView.axis = .vertical
        
        contentView.addSubview(labelsStackView)
        
        labelsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        labelsStackView.trailingAnchor.constraint(lessThanOrEqualTo: markDescriptionLabel.leadingAnchor, constant: -8).isActive = true
    }
    
    private func setupIconImageView() {
        contentView.addSubview(iconImageView)
        
        iconImageView.image = Theme.shared.images.handWave
        iconImageView.contentMode = .scaleAspectFit
        
        titleWithoutIconConstraint = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0)
        titleWithIconConstraint = titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16.0)
        
        updateIconImageViewElement()
        
        let constraints = [
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 24.0),
            iconImageView.widthAnchor.constraint(equalToConstant: 24.0),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }

    private func setupMarkDescription() {
        markDescriptionLabel.font = Theme.shared.fonts.systemTableViewCellMarkDescription
        markDescriptionLabel.textAlignment = .right
        contentView.addSubview(markDescriptionLabel)

        markDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        markDescriptionLabel.centerYAnchor.constraint(equalTo: markImageView.centerYAnchor).isActive = true
        markDescriptionLabel.trailingAnchor.constraint(equalTo: switcher.leadingAnchor, constant: -8.0).isActive = true
    }
}
