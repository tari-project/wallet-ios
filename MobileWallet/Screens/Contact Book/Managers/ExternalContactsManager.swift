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

    struct ContactModel: Equatable {

        let uuid: String
        let firstName: String
        let lastName: String
        let emojiID: String?
        let yat: String?
        let avatar: UIImage?

        var fullname: String { [firstName, lastName].joined(separator: " ") }
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.uuid == rhs.uuid }
    }

    // MARK: - Constants

    private static let auroraServiceName = "Aurora"
    private static let yatServiceName = "Yat"
    private let keysToFetch: [CNKeyDescriptor] = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactInstantMessageAddressesKey, CNContactSocialProfilesKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]

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

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)

        return try await withCheckedThrowingContinuation { continuation in

            var models: [ContactModel] = []

            do {
                try store.enumerateContacts(with: request) { contact, _ in
                    let emojiID = contact.socialProfiles.first { $0.value.service == Self.auroraServiceName }?.value.username
                    let yat = contact.socialProfiles.first { $0.value.service == Self.yatServiceName }?.value.username
                    var avatar: UIImage?
                    if let avatarData = contact.thumbnailImageData {
                        avatar = UIImage(data: avatarData)
                    }
                    models.append(ContactModel(uuid: contact.identifier, firstName: contact.givenName, lastName: contact.familyName, emojiID: emojiID, yat: yat, avatar: avatar))
                }
                continuation.resume(with: .success(models))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func update(firstName: String, lastName: String, yat: String, contactID: String) throws {

        guard let contact = try fetchContact(uuid: contactID) else { return }

        contact.givenName = firstName
        contact.familyName = lastName

        let urlString = "https://www.y.at"

        var socialProfiles = contact.socialProfiles.filter { $0.value.service != Self.yatServiceName }

        if !yat.isEmpty {
            socialProfiles.append(CNLabeledValue<CNSocialProfile>(label: nil, value: CNSocialProfile(urlString: urlString, username: yat, userIdentifier: nil, service: Self.yatServiceName)))
        }

        contact.socialProfiles = socialProfiles

        let request = CNSaveRequest()
        request.update(contact)

        try store.execute(request)
    }

    func remove(contactID: String) throws {

        guard let contact = try fetchContact(uuid: contactID) else { return }

        let request = CNSaveRequest()
        request.delete(contact)

        try store.execute(request)
    }

    func link(hex: String, emojiID: String, contactID: String) throws {

        guard let contact = try fetchContact(uuid: contactID) else { return }

        let urlString = "tari://\(NetworkManager.shared.selectedNetwork.name)/transactions/send?publicKey=\(hex)"

        var socialProfiles = contact.socialProfiles.filter { $0.value.service != Self.auroraServiceName }
        socialProfiles.append(CNLabeledValue<CNSocialProfile>(label: nil, value: CNSocialProfile(urlString: urlString, username: emojiID, userIdentifier: nil, service: Self.auroraServiceName)))

        contact.socialProfiles = socialProfiles

        let request = CNSaveRequest()
        request.update(contact)

        try store.execute(request)
    }

    func unlink(contactID: String) throws {

        guard let contact = try fetchContact(uuid: contactID) else { return }

        contact.socialProfiles = contact.socialProfiles.filter { $0.value.service != Self.auroraServiceName }

        let request = CNSaveRequest()
        request.update(contact)

        try store.execute(request)
    }

    // MARK: - Helpers

    private func fetchContact(uuid: String) throws -> CNMutableContact? {
        let contact = try store.unifiedContact(withIdentifier: uuid, keysToFetch: keysToFetch)
        return contact.mutableCopy() as? CNMutableContact
    }
}
