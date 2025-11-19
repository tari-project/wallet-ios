//  ExolixError.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 17.10.2025
	Using Swift 6.0
	Running on macOS 26.0

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

enum ExolixError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed(Error)
    case network(Error)
    case unknown
    case api(String)
    case rate(ExolixRateError)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL."
        case let .requestFailed(code): "Request failed with status code: \(code)"
        case let .decodingFailed(error): "Decoding failed: \(error.localizedDescription)"
        case let .network(error): "Network error: \(error.localizedDescription)"
        case let .api(message): "API error: \(message)"
        case let .rate(error): "\(error.message): min: \(error.minAmount), max: \(error.maxAmount)"
        case .unknown: "Unknown error."
        }
    }
}

struct ExolixRateError: Decodable {
    let message: String
    let minAmount: Double
    let maxAmount: Double
}
