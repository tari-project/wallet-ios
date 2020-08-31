//  YatApi.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/08/21
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

import Foundation
import Alamofire

enum YatAPIError: Error {
    case urlEncoding
    case invalidResponse
    case requiresAuthentication
    case yatUnavailable
}

class YatAPI {

    static let shared = YatAPI()
    static let defaultYatEmojiIdLength: UInt = 4

    private let yatWebAppBaseURL = "https://dev.yat.rocks/"
    private let yatAPIBaseURL = "https://api-dev.yat.rocks/"
    private let activationAPIBaseURL = "https://partner.scratch.emojid.me/"
    private let signingAPIBaseURL = "https://partner-aurora.emojid.me/"

    private let xBypassHeader = HTTPHeader(
        name: "X-Bypass-Token",
        value: "AuroraToken98731234"
    )
    private let appCode = "66b4d2cd-33a8-42f4-9a8d-56931da552bb"
    private let appPublicKey = "9efb70cbc2446604191fbca7d4256b188093e6c3e2d0e0ffc6565395d745d57e"

    var emojiSet: [String]?
    // The emojis in this set will be without the 0xFE0F variation selector.
    var emojiSetWithoutEmojiVariationSelector: [String]?

    private func randomPassword(length: Int) -> String {
      let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_!=?*-.:,;"
      return String((0..<length).map { _ in characters.randomElement()! })
    }

    private func encodedUrl(
        _ basePath: String,
        _ path: String
    ) throws -> String {
        guard let encoded = "\(basePath)\(path)".addingPercentEncoding(
                withAllowedCharacters: .urlFragmentAllowed
        ) else {
            throw YatAPIError.urlEncoding
        }

        return encoded
    }

    private func registerNewUser(
        alternateId: String,
        password: String,
        onComplete: @escaping (Result<YatRegistrationResponse, Error>) -> Void
    ) {
        do {
            AF.request(
                try encodedUrl(yatAPIBaseURL, "users"),
                method: .post,
                parameters: [
                    "alternate_id": alternateId,
                    "password": password,
                    "source": "Aurora"
                ],
                encoder: JSONParameterEncoder.default,
                headers: [xBypassHeader]
            )
                .validate(statusCode: 200..<300)
                .responseObject {
                    (response: DataResponse<YatRegistrationResponse, AFError>) in
                    switch response.result {
                    case .success(let registrationResponse):
                        onComplete(.success(registrationResponse))
                    case .failure(let error):
                        onComplete(.failure(error))
                        return
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    private func activateUser(
        userId: String,
        onComplete: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            AF.request(
                try encodedUrl(activationAPIBaseURL, "activate/\(userId)"),
                method: .post,
                headers: [xBypassHeader]
            )
            .validate(statusCode: 200..<300)
            .response(completionHandler: { (response) in
                if let error = response.error {
                    onComplete(.failure(error))
                } else {
                    onComplete(.success(()))
                }
            })
        } catch {
            onComplete(.failure(error))
        }
    }

    private func authenticate(alternateId: String,
                              password: String,
                              onComplete: @escaping (Result<YatCredentials, Error>) -> Void) {
        do {
            AF.request(
                try encodedUrl(yatAPIBaseURL, "auth/token"),
                method: .post,
                parameters: ["alternate_id": alternateId, "password": password],
                encoder: JSONParameterEncoder.default
            )
                .validate(statusCode: 200..<300)
                .responseObject { (response: DataResponse<YatCredentials, AFError>) in
                    switch response.result {
                    case .success(let credentials):
                        TariKeychainWrapper.shared.yatCredentials = credentials
                        onComplete(.success(credentials))
                    case .failure(let error):
                        onComplete(.failure(error))
                        return
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    private func signMessage(
        alternateId: String,
        onComplete: @escaping (Result<YatSignMessageResponse, Error>) -> Void
    ) {
        guard let credentials = TariKeychainWrapper.shared.yatCredentials else {
            onComplete(.failure(YatAPIError.requiresAuthentication))
            return
        }

        do {
            let url = try encodedUrl(signingAPIBaseURL, "sign")
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = HTTPMethod.post.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let signMessageRequest = YatSignMessageRequest()
            signMessageRequest.alternateId = alternateId
            request.httpBody = (signMessageRequest.toJSONString()!.data(using: .utf8))! as Data

            let authenticator = YatAuthenticator()
            let interceptor = AuthenticationInterceptor(authenticator: authenticator,
                                                        credential: credentials)

            AF.request(request, interceptor: interceptor)
                .validate(statusCode: 200..<300)
                .responseObject { (response: DataResponse<YatSignMessageResponse, AFError>) in
                    switch response.result {
                    case .success(let signMessageResponse):
                        onComplete(.success(signMessageResponse))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    private func search(_ emojiId: String,
                        onComplete: @escaping (Result<YatSearchResponse, Error>) -> Void) {
        do {
            AF.request(try encodedUrl(yatAPIBaseURL, "emoji_id/search?emoji_id=\(emojiId)"))
                .validate(statusCode: 200..<300)
                .responseObject { (response: DataResponse<YatSearchResponse, AFError>) in
                    switch response.result {
                    case .success(let searchResponse):
                        onComplete(.success(searchResponse))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    private func randomYat(
        signMessageResponse: YatSignMessageResponse,
        onComplete: @escaping (Result<YatOrder, Error>) -> Void
    ) {
        guard let credentials = TariKeychainWrapper.shared.yatCredentials else {
            onComplete(.failure(YatAPIError.requiresAuthentication))
            return
        }
        do {
            let url = try encodedUrl(yatAPIBaseURL, "codes/\(appCode)/random_yat")
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = HTTPMethod.post.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let randomYatRequest = YatRandomYatRequest()
            randomYatRequest.nonce = signMessageResponse.nonce
            randomYatRequest.signature = signMessageResponse.signature
            randomYatRequest.publicKey = appPublicKey
            request.httpBody = (randomYatRequest.toJSONString()!.data(using: .utf8))! as Data

            let authenticator = YatAuthenticator()
            let interceptor = AuthenticationInterceptor(authenticator: authenticator,
                                                        credential: credentials)

            AF.request(request, interceptor: interceptor)
                .validate(statusCode: 200..<300)
                .responseObject { (response: DataResponse<YatOrder, AFError>) in
                    switch response.result {
                    case .success(let order):
                        onComplete(.success(order))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    private func checkout(onComplete: @escaping (Result<YatOrder, Error>) -> Void) {
        guard let credentials = TariKeychainWrapper.shared.yatCredentials else {
            onComplete(.failure(YatAPIError.requiresAuthentication))
            return
        }

        do {
            let url = try encodedUrl(yatAPIBaseURL, "cart/checkout")
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = HTTPMethod.post.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let checkoutRequest = YatCartCheckoutRequest()
            request.httpBody = (checkoutRequest.toJSONString()!.data(using: .utf8))! as Data

            let authenticator = YatAuthenticator()
            let interceptor = AuthenticationInterceptor(authenticator: authenticator,
                                                        credential: credentials)

            AF.request(request, interceptor: interceptor)
                .validate(statusCode: 200..<300)
                .responseObject { (response: DataResponse<YatOrder, AFError>) in
                    switch response.result {
                    case .success(let order):
                        onComplete(.success(order))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    private func linkTariPublicKeyToYat(_ yat: String,
                                        tariPublicKey: PublicKey,
                                        onComplete: @escaping (Result<Void, Error>) -> Void) {
        guard let credentials = TariKeychainWrapper.shared.yatCredentials else {
            onComplete(.failure(YatAPIError.requiresAuthentication))
            return
        }
        do {
            let url = try encodedUrl(yatAPIBaseURL, "emoji_id/\(yat)")
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = HTTPMethod.patch.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let updateRequest = YatUpdateRequest()
            let tariPublicKeyRecord = YatRecord()
            tariPublicKeyRecord.type = .TariPublicKey
            tariPublicKeyRecord.value = tariPublicKey.hex.0
            updateRequest.insertRecords = [tariPublicKeyRecord]
            request.httpBody = (updateRequest.toJSONString()!.data(using: .utf8))! as Data

            let authenticator = YatAuthenticator()
            let interceptor = AuthenticationInterceptor(authenticator: authenticator,
                                                        credential: credentials)
            AF.request(request, interceptor: interceptor)
                .validate(statusCode: 200..<300)
                .responseJSON { (response) in
                    if let error = response.error {
                        onComplete(.failure(error))
                    } else {
                        onComplete(.success(()))
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    func registerActivateAndAuthenticate(
        tariPublicKey: PublicKey,
        onComplete: @escaping (Result<YatCredentials, Error>) -> Void
    ) {
        if let yatCredentials = TariKeychainWrapper.shared.yatCredentials {
            onComplete(.success(yatCredentials))
            return
        }
        let (alternateId, password) = (
            tariPublicKey.hex.0.uppercased(),
            randomPassword(length: tariPublicKey.hex.0.count)
        )
        registerNewUser(
            alternateId: alternateId,
            password: password
        ) {
            [weak self]
            (result) in
            guard let self = self else {
                return
            }
            // Make sure we either registered a new user successfully
            // or the user already exists with those details
            switch result {
            case .failure(let error):
                if error.asAFError?.responseCode != 422 {
                    onComplete(.failure(error))
                    return
                }
            case .success(let response):
                self.activateUser(
                    userId: response.user.id
                ) {
                    [weak self]
                    (result) in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .failure(let error):
                        onComplete(.failure(error))
                    case .success:
                        self.authenticate(
                            alternateId: alternateId,
                            password: password
                        ) { (result) in
                            switch result {
                            case .failure(let error):
                                onComplete(.failure(error))
                            case .success(let credentials):
                                onComplete(.success(credentials))
                            }
                        }
                    }
                }
            }
        }
    }

    func refreshAccessToken(onComplete: @escaping (Result<YatCredentials, Error>) -> Void) {
        guard let credentials = TariKeychainWrapper.shared.yatCredentials else {
            onComplete(.failure(YatAPIError.requiresAuthentication))
            return
        }
        do {
            AF.request(
                try encodedUrl(yatAPIBaseURL, "auth/token/refresh"),
                method: .post,
                parameters: ["refresh_token": credentials.refreshToken],
                encoder: JSONParameterEncoder.default
            )
                .validate(statusCode: 200..<300)
                .responseObject { (response: DataResponse<YatCredentials, AFError>) in
                    switch response.result {
                    case .success(let credentials):
                        TariKeychainWrapper.shared.yatCredentials = credentials
                        onComplete(.success(credentials))
                    case .failure(let error):
                        onComplete(.failure(error))
                        return
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    func addRandomYatToCart(
        alternateId: String,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        signMessage(alternateId: alternateId) {
            [weak self]
            (result) in
            switch result {
            case .success(let signMessageResponse):
                self?.randomYat(
                    signMessageResponse: signMessageResponse
                ) {
                    (result) in
                    switch result {
                    case .success(let order):
                        onComplete(.success(order.emojiId!))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }

    func clearCart(onComplete: @escaping (Result<Void, Error>) -> Void) {
        guard let credentials = TariKeychainWrapper.shared.yatCredentials else {
            onComplete(.failure(YatAPIError.requiresAuthentication))
            return
        }
        do {
            let url = try encodedUrl(yatAPIBaseURL, "cart")
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = HTTPMethod.delete.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let authenticator = YatAuthenticator()
            let interceptor = AuthenticationInterceptor(authenticator: authenticator,
                                                        credential: credentials)
            AF.request(request, interceptor: interceptor)
                .validate(statusCode: 200..<300)
                .response(completionHandler: { (response) in
                    if let error = response.error {
                        onComplete(.failure(error))
                    } else {
                        onComplete(.success(()))
                    }
                })
        } catch {
            onComplete(.failure(error))
        }
    }

    func checkoutAndLinkPublicKeyToYat(_ yat: String,
                                       tariPublicKey: PublicKey,
                                       onComplete: @escaping (Result<String, Error>) -> Void) {
        checkout {
            [weak self]
            (result) in
            switch result {
            case .success:
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
                    [weak self] in
                    self?.linkTariPublicKeyToYat(yat, tariPublicKey: tariPublicKey) {
                        (result) in
                        switch result {
                        case .success:
                            UserDefaults.Key.yat.set(yat)
                            onComplete(.success(yat))
                        case .failure(let error):
                            TariLogger.info("Checkout has failed: \(error.localizedDescription)")
                        }
                    }
                }
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }

    func lookupYat(_ yat: String, _ onComplete: @escaping (Result<YatLookupResponse, Error>) -> Void) {
        do {

            AF.request(try encodedUrl(yatAPIBaseURL, "emoji_id/\(yat)"))
                .validate(statusCode: 200..<300)
                .responseObject { (response: DataResponse<YatLookupResponse, AFError>) in
                    switch response.result {
                    case .success(let lookupResponse):
                        onComplete(.success(lookupResponse))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
        } catch {
            onComplete(.failure(error))
        }
    }

    func getAndCacheEmojiSet(_ onComplete: ((Result<[String], Error>) -> Void)? = nil) {
        if let emojiSet = emojiSet {
            onComplete?(.success(emojiSet))
            return
        }
        do {
            AF.request(
                try encodedUrl(yatAPIBaseURL, "emoji"),
                headers: []
            )
                .validate(statusCode: 200..<300)
                .responseJSON { (response) in
                    switch response.result {
                    case .success(let value):
                        if let emojiSet = value as? [String] {
                            self.emojiSet = emojiSet
                            self.emojiSetWithoutEmojiVariationSelector = emojiSet.map { $0.withoutEmojiVariationSelector }
                            onComplete?(.success(emojiSet))
                        } else {
                            onComplete?(.failure(YatAPIError.invalidResponse))
                        }
                    case .failure(let error):
                        onComplete?(.failure(error))
                    }
                }
        } catch {
            onComplete?(.failure(error))
        }
    }

    func textIsPossiblyYat(_ text: String) -> Bool {
        if text.count <= YatAPI.defaultYatEmojiIdLength {
            guard let yatEmojiSet = emojiSetWithoutEmojiVariationSelector else {
                return text.containsOnlyEmoji
            }
            return text.reduce(true) {
                $0 && yatEmojiSet.contains(
                    $1.toStringWithoutEmojiVariationSelector
                )
            }
        }
        return false
    }

}
