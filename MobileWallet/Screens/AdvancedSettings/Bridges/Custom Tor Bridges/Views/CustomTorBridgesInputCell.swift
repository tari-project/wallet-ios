//  CustomTorBridgesInputCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 05/09/2023
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

final class CustomTorBridgesInputCell: UITableViewCell {

    // MARK: - Constants

    private static let placeholderText = """
    Available formates:
    • obfs4 <IP ADDRESS>:<PORT> <FINGERPRINT> cert=<CERTIFICATE> iat-mode=<value>
    example:
    obfs4 192.95.36.142:443 CDF2E852BF539B82BD10E27E9115A31734E378C2 cert=qUVQ0srL1JI/vO6V6m/24anYXiJD3QP2HgzUKQtQ7GRqqUvs7P+tG43RtAqdhLOALP7DJQ iat-mode=1

    • <IP ADDRESS>:<PORT> <FINGERPRINT>
    example:
    78.156.103.189:9301 2BD90810282F8B331FC7D47705167166253E1442
    """

    // MARK: - Subviews

    @View private var textView: UITextView = {
        let view = UITextView()
        view.font = .Avenir.medium.withSize(12.0)
        return view
    }()

    @View private var placeholderLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.text = CustomTorBridgesInputCell.placeholderText
        view.font = .Avenir.medium.withSize(11.0)
        return view
    }()

    // MARK: - Properties

    var text: String? {
        get { textView.text }
        set {
            textView.text = newValue
            updatePlaceholder()
        }
    }

    var onTextUpdate: ((String) -> Void)?

    // MARK: - Initilisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        setupCallbacks()
        updatePlaceholder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupConstraints() {

        [textView, placeholderLabel].forEach(contentView.addSubview)

        let constraints = [
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15.0),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15.0),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: textView.bottomAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 250.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        textView.delegate = self
    }

    // MARK: - Updates

    private func updatePlaceholder() {
        placeholderLabel.alpha = (!textView.isFirstResponder && textView.text.isEmpty) ? 1.0 : 0.0
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        updatePlaceholder()
    }
}

extension CustomTorBridgesInputCell: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        onTextUpdate?(textView.text ?? "")
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.3) {
            self.updatePlaceholder()
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.3) {
            self.updatePlaceholder()
        }
    }
}
