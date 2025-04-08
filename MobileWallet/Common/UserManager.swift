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

struct UserDetails: Codable {
    let isBot: Bool
    let twitterFollowers: Int
    let id: String
    let referralCode: String
    let yatUserId: String
    let name: String
    let role: String
    let profileImageUrl: String
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
        case isBot = "is_bot"
        case twitterFollowers = "twitter_followers"
        case id
        case referralCode = "referral_code"
        case yatUserId = "yat_user_id"
        case name
        case role
        case profileImageUrl = "profileimageurl"
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
        set {
            UserDefaults.standard.set(newValue, forKey: "AccessToken")
        }
        get {
            UserDefaults.standard.string(forKey: "AccessToken")
        }
    }

    static let shared = UserManager()

    override init() {
        super.init()
    }

    func getUserInfo(completion: @escaping (UserInfoStatus) -> Void) {
        guard let accessToken = self.accessToken else {
            return completion(.LoggedOut)
        }

        fetchUserDetails(accessToken: accessToken, completion: completion)
    }

    func fetchUserDetails(accessToken: String, completion: @escaping (UserInfoStatus) -> Void) {
        guard let url = URL(string: "https://airdrop.tari.com/api/user/details") else {
            completion(.Error("Invalid URL"))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.Error("Error: \(error.localizedDescription)"))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.Error("HTTP Error: \(httpResponse.statusCode)"))
                return
            }

            if let data = data {
                do {
                    let userDetails = try JSONDecoder().decode(UserDetails.self, from: data)
                    completion(.Ok(userDetails))
                } catch {
                    completion(.Error("JSON Decoding Error: \(error.localizedDescription)"))
                }
            }
        }

        task.resume()
    }
}
