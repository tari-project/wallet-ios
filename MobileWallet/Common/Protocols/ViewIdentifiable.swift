//  ViewIdentifiable.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/07/2021
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

protocol ViewIdentifiable {}

extension ViewIdentifiable {
    static var identifier: String { String(describing: Self.self) }
}

extension UITableViewCell: ViewIdentifiable {}
extension UITableViewHeaderFooterView: ViewIdentifiable {}
extension UICollectionViewCell: ViewIdentifiable {}

extension UITableView {

    func register<T: UITableViewCell>(type: T.Type) {
        register(type, forCellReuseIdentifier: type.identifier)
    }

    func register<T: UITableViewHeaderFooterView>(headerFooterType: T.Type) {
        register(headerFooterType, forHeaderFooterViewReuseIdentifier: headerFooterType.identifier)
    }

    func dequeueReusableCell<T: UITableViewCell>(type: T.Type, indexPath: IndexPath) -> T {
        dequeueReusableCell(withIdentifier: type.identifier, for: indexPath) as? T ?? T(style: .default, reuseIdentifier: type.identifier)
    }

    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(type: T.Type) -> T {
        dequeueReusableHeaderFooterView(withIdentifier: type.identifier) as? T ?? T(reuseIdentifier: type.identifier)
    }
}

extension UICollectionView {

    func register<T: UICollectionViewCell>(type: T.Type) {
        register(type, forCellWithReuseIdentifier: type.identifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(type: T.Type, indexPath: IndexPath) -> T {
        dequeueReusableCell(withReuseIdentifier: type.identifier, for: indexPath) as? T ?? T(frame: .zero)
    }
}
