//  ExternalContactsManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 02/03/2023
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

import Contacts
import UIKit

final class ExternalContactsManager {

    private static let auroraServiceName = "Aurora"
    private static let yatServiceName = "Yat"

    struct ContactModel: Equatable {
        let firstName: String
        let lastName: String
        let contact: CNContact
        let yat: String?

        var avatar: UIImage? {
            guard let data = contact.thumbnailImageData, let image = UIImage(data: data) else { return nil }
            return image
        }

        var emojiID: String? { contact.socialProfiles.first { $0.value.service == auroraServiceName }?.value.username }
        var fullname: String { [firstName, lastName].joined(separator: " ") }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.contact.identifier == rhs.contact.identifier
        }
    }

    // MARK: - Properties

    var isPermissionGranted: Bool {
        CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }

    private let store = CNContactStore()

    // MARK: - Actions

    func fetchAllModels() async throws -> [ContactModel] {

        do {
            try await store.requestAccess(for: .contacts)
        } catch {
            return []
        }

        let keysToFetch: [CNKeyDescriptor] = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactInstantMessageAddressesKey, CNContactSocialProfilesKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)

        return try await withCheckedThrowingContinuation { continuation in

            var models: [ContactModel] = []

            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let yat = contact.socialProfiles.first { $0.value.service == Self.yatServiceName }?.value.username
                    models.append(ContactModel(firstName: contact.givenName, lastName: contact.familyName, contact: contact, yat: yat))
                }
                continuation.resume(with: .success(models))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func update(firstName: String, lastName: String, yat: String, contact: ContactModel) throws {

        guard let mutableContact = contact.contact.mutableCopy() as? CNMutableContact else { return }

        mutableContact.givenName = firstName
        mutableContact.familyName = lastName

        let urlString = "https://www.y.at"

        var socialProfiles = mutableContact.socialProfiles.filter { $0.value.service != Self.yatServiceName }

        if !yat.isEmpty {
            socialProfiles.append(CNLabeledValue<CNSocialProfile>(label: nil, value: CNSocialProfile(urlString: urlString, username: yat, userIdentifier: nil, service: Self.yatServiceName)))
        }

        mutableContact.socialProfiles = socialProfiles

        let request = CNSaveRequest()
        request.update(mutableContact)

        try store.execute(request)
    }

    func remove(contact: ContactModel) throws {

        guard let mutableContact = contact.contact.mutableCopy() as? CNMutableContact else { return }

        let request = CNSaveRequest()
        request.delete(mutableContact)

        try store.execute(request)
    }

    func link(hex: String, emojiID: String, contact: ContactModel) throws {

        guard let mutableContact = contact.contact.mutableCopy() as? CNMutableContact else { return }

        let urlString = "tari://\(NetworkManager.shared.selectedNetwork.name)/transactions/send?publicKey=\(hex)"

        var socialProfiles = mutableContact.socialProfiles.filter { $0.value.service != Self.auroraServiceName }
        socialProfiles.append(CNLabeledValue<CNSocialProfile>(label: nil, value: CNSocialProfile(urlString: urlString, username: emojiID, userIdentifier: nil, service: Self.auroraServiceName)))

        mutableContact.socialProfiles = socialProfiles

        let request = CNSaveRequest()
        request.update(mutableContact)

        try store.execute(request)
    }

    func unlink(contact: ContactModel) throws {

        guard let mutableContact = contact.contact.mutableCopy() as? CNMutableContact else { return }

        mutableContact.socialProfiles = mutableContact.socialProfiles.filter { $0.value.service != Self.auroraServiceName }

        let request = CNSaveRequest()
        request.update(mutableContact)

        try store.execute(request)
    }
}
