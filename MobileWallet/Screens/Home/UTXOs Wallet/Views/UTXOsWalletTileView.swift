//  UTXOsWalletTileView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 08/06/2022
	Using Swift 5.0
	Running on macOS 12.3

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

final class UTXOsWalletTileView: UIView {
    
    // MARK: - Subviews
    
    @View private var scrollView = ContentScrollView()
    
    @View private var contentStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .fillEqually
        view.alignment = .leading
        view.spacing = 12.0
        return view
    }()
    
    // MARK: - Properties
    
    var models: [UTXOTileView.Model] = [] {
        didSet { updateTiles(models: models) }
    }
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        addSubview(scrollView)
        scrollView.contentView.addSubview(contentStackView)
        
        let constraints = [
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor, constant: 12.0),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 30.0),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -30.0),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor, constant: -12.0),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    private func updateTiles(models: [UTXOTileView.Model]) {
        
        removeTiles()
        
        let columnsCount = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        
        let initialData: [(index: Int, height: CGFloat, column: UIStackView)] = (0..<columnsCount)
            .map { ($0, 0.0, makeColumn()) }
        
        models
            .reduce(into: initialData) { result, model in
                
                guard let columnIndex = result.min(by: { $0.height < $1.height })?.index else { return }
                
                let tile = UTXOTileView(model: model)
                result[columnIndex].height += model.height
                result[columnIndex].column.addArrangedSubview(tile)
            }
            .map(\.column)
            .forEach(contentStackView.addArrangedSubview)
    }
    
    private func removeTiles() {
        contentStackView.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .forEach { column in
                column.arrangedSubviews.forEach {
                    column.removeArrangedSubview($0)
                    $0.removeFromSuperview()
                }
                contentStackView.removeArrangedSubview(column)
        }
    }
    
    // MARK: - Factories
    
    private func makeColumn() -> UIStackView {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12.0
        return view
    }
}

