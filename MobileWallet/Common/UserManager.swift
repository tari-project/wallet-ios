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

    var accessToken: String? {
        get {
            UserDefaults.standard.string(forKey: "AccessToken")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "AccessToken")
            if let newToken = newValue {
                fetchUserDetails(accessToken: newToken)
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

    @Published var user: UserInfoStatus = .LoggedOut

    static let shared = UserManager()

    override init() {
        super.init()
    }

    func getUserInfo() {
        guard let accessToken = self.accessToken else {
            user = .LoggedOut
            return
        }

        fetchUserDetails(accessToken: accessToken)
    }

    func fetchUserDetails(accessToken: String) {
        guard let url = URL(string: "https://airdrop.tari.com/api/user/details") else {
            user = .Error("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.user = .Error("Error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                self.user = .Error("HTTP Error: \(httpResponse.statusCode)")
                return
            }

            if let data = data {
                do {
                    if let string = String(data: data, encoding: .utf8) {
                        print("Response string: \(string)")
                    } else {
                        print("Failed to convert data to string")
                    }
                    let userWrapper = try JSONDecoder().decode(UserWrapper.self, from: data)
                    self.user = .Ok(userWrapper.user)
                } catch {
                    self.user = .Error("JSON Decoding Error: \(error.localizedDescription)")
                }
            }
        }

        task.resume()
    }
}
