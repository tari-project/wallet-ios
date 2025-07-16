//  UserManager.swift

/*
	Package MobileWallet
	Created by Konrad Faltyn on 19/03/2025
	Using Swift 6.0
	Running on macOS 15.3

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

struct UserWrapper: Codable {
    let user: UserDetails
}

struct UserDetails: Codable {
    let id: String
    let referralCode: String
    let displayName: String
    let rank: Rank

    struct Rank: Codable {
        let gems: Int
        let shells: Int
        let hammers: Int
        let totalScore: Int
        let rank: String
    }

    // Use CodingKeys if API uses different key names than Swift properties
    enum CodingKeys: String, CodingKey {
        case id
        case referralCode = "referral_code"
        case displayName = "display_name"
        case rank
    }
}

enum UserInfoStatus {
    case Error(String)
    case LoggedOut
    case Ok(UserDetails)
}

class UserManager: NSObject {
    private var cancellables = Set<AnyCancellable>()
    private var retryCount = 0
    private let maxRetries = 3

    // Add token validation
    private func isValidTokenFormat(_ token: String) -> Bool {
        // Basic JWT token validation (you might want to adjust this based on your token format)
        let components = token.components(separatedBy: ".")
        return components.count == 3
    }

    var accessToken: String? {
        get {
            UserDefaults.standard.string(forKey: "AccessToken")
        }
        set {
            if let newToken = newValue {
                if isValidTokenFormat(newToken) {
                    UserDefaults.standard.set(newToken, forKey: "AccessToken")
                    fetchUserDetails(accessToken: newToken)
                } else {
                    user = .Error("Invalid token format")
                }
            } else {
                UserDefaults.standard.set(nil, forKey: "AccessToken")
            }
        }
    }

    var refreshToken: String? {
        get {
            UserDefaults.standard.string(forKey: "RefreshToken")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "RefreshToken")
        }
    }

       var userId: String? {
        get {
            UserDefaults.standard.string(forKey: "UserId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "UserId")
        }
    }

    @Published var user: UserInfoStatus = .LoggedOut

    static let shared = UserManager()

    override init() {
        super.init()
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        user = .LoggedOut
    }

    func getUserInfo() {
        guard let accessToken = self.accessToken else {
            user = .LoggedOut
            return
        }

        fetchUserDetails(accessToken: accessToken)
    }

    func fetchUserDetails(accessToken: String) {
        retryCount = 0
        attemptFetchUserDetails(accessToken: accessToken)
    }

    private func attemptFetchUserDetails(accessToken: String) {
        API.service.request(endpoint: "/user/details")
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleFetchError(error: error, accessToken: accessToken)
                }
            }, receiveValue: { [weak self] (response: UserWrapper) in
                self?.handleFetchSuccess(response: response)
            })
            .store(in: &cancellables)
    }

    private func handleFetchError(error: Error, accessToken: String) {
        if shouldRetry(error) && retryCount < maxRetries {
            retryCount += 1
            print("Retrying user details fetch (attempt \(retryCount))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.attemptFetchUserDetails(accessToken: accessToken)
            }
        } else {
            user = .Error("Error: \(error.localizedDescription)")
            userId = nil
            print("Failed to fetch user details after \(retryCount) retries")
        }
    }

    private func handleFetchSuccess(response: UserWrapper) {
        userId = response.user.id
        user = .Ok(response.user)
        retryCount = 0
    }

    private func shouldRetry(_ error: Error) -> Bool {
        // Add logic to determine if the error is retryable
        // For example, network errors might be retryable while authentication errors are not
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .timedOut:
                return true
            default:
                return false
            }
        }
        return false
    }
}
