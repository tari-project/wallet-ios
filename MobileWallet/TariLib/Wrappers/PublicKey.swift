//  PublicKey.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/16
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

enum PublicKeyError: Error {
    case generic(_ errorCode: Int32)
    case invalidEmojis
    case invalidHex
    case invalidDeepLink
    case invalidDeepLinkNetwork //When a deep link is valid but for wring network
    case invalidDeepLinkType //If it doesn't contain "/eid/" or "/pubkey/"
    case cantDerivePublicKeyFromString
    case invalidEmojiSet
}

class PublicKey {
    private var ptr: OpaquePointer
    private var cachedEmojiId: String?
    private static let emojiCount = 33 //Used for some pre validation before hitting the FFI

    var pointer: OpaquePointer {
        return ptr
    }

    var bytes: (ByteVector?, Error?) {
       var errorCode: Int32 = -1
       let result = withUnsafeMutablePointer(to: &errorCode, { error in
            ByteVector(pointer: public_key_get_bytes(ptr, error))
        })
       guard errorCode == 0 else {
           return (nil, PublicKeyError.generic(errorCode))
       }

       return (result, nil)
    }

    var hex: (String, Error?) {
        let (bytes, bytesError) = self.bytes
        if bytesError != nil {
            return ("", bytesError)
        }

        return bytes!.hexString
    }

    var emojis: (String, Error?) {
        var errorCode: Int32 = -1
        let emojiPtr = withUnsafeMutablePointer(to: &errorCode, { error in
            public_key_to_emoji_id(ptr, error)
        })
        let result = String(cString: emojiPtr!)

        let mutable = UnsafeMutablePointer<Int8>(mutating: emojiPtr!)
        string_destroy(mutable)

        return (result, errorCode != 0 ? PublicKeyError.generic(errorCode) : nil)
    }

    var emojiDeeplink: (String, Error?) {
        let (emojisPubkey, emojisError) = emojis
        guard emojisError == nil else {
            return ("", emojisError)
        }

        return ("\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/eid/\(emojisPubkey)", nil)
    }

    var hexDeeplink: (String, Error?) {
        let (hexPubkey, hexError) = hex
        guard hexError == nil else {
            return ("", hexError)
        }

        return ("\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)/pubkey/\(hexPubkey)", nil)
    }

    //TODO setup attributed string version with dots in the middle for shortened version in Common dir.
    //https://stackoverflow.com/questions/19318421/how-to-embed-small-icon-in-uilabel

    init(privateKey: PrivateKey) throws {
        var errorCode: Int32 = -1
        ptr = withUnsafeMutablePointer(to: &errorCode, { error in
            public_key_from_private_key(privateKey.pointer, error)
        })
        guard errorCode == 0 else {
            throw PublicKeyError.generic(errorCode)
        }
    }

    init(emojis: String) throws {
        let cleanEmojis = emojis
            .replacingOccurrences(of: "|", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: " ", with: "")

        if cleanEmojis.count < PublicKey.emojiCount {
            throw PublicKeyError.invalidEmojis
        }

        let count = cleanEmojis.utf8.count + 1
        let emojiPtr = UnsafeMutablePointer<Int8>.allocate(capacity: count)
        cleanEmojis.withCString { (baseAddress) in
            emojiPtr.initialize(from: baseAddress, count: count)
        }

        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            emoji_id_to_public_key(emojiPtr, error)})

        emojiPtr.deinitialize(count: count)

        guard errorCode == 0 else {
            throw PublicKeyError.generic(errorCode)
        }

        ptr = result!
    }

    init(hex: String) throws {
        let chars = CharacterSet(charactersIn: "0123456789abcdef")
        guard hex.count == 64 && hex.rangeOfCharacter(from: chars) != nil else {
            throw PublicKeyError.invalidHex
        }
        var errorCode: Int32 = -1
        let result = hex.withCString({ chars in
            withUnsafeMutablePointer(to: &errorCode, { error in
            public_key_from_hex(chars, error)})
        })
        guard errorCode == 0 else {
            throw PublicKeyError.generic(errorCode)
        }
        ptr = result!
    }

    //Accepts deep links using either emoji ID or hex. i.e:
    //tari://rincewind/eid/🐒🐑🍔🔧❌👂🦒💇🔋💥🍷🍺👔😷🐶🧢🤩💥🎾🎲🏀🤠💪👮🤯🎁💉🌞🍉🤷🍦
    //tari://rincewind/pubkey/70350e09c474809209824c6e6888707b7dd09959aa227343b5106382b856f73a?amount=2.3note=hi%20there
    convenience init(deeplink: String) throws {
        guard deeplink.hasPrefix("\(TariSettings.shared.deeplinkURI)://") else {
            throw PublicKeyError.invalidDeepLink
        }

        let deeplinkPrefix = "\(TariSettings.shared.deeplinkURI)://\(TariSettings.shared.network)"

        //Link is for a different network
        guard deeplink.hasPrefix(deeplinkPrefix) else {
            throw PublicKeyError.invalidDeepLinkNetwork
        }

        guard let strippedParamsLink = PublicKey.removeDeepURLParams(deeplink).removingPercentEncoding else {
            throw PublicKeyError.invalidDeepLink
        }

        if strippedParamsLink.hasPrefix("\(deeplinkPrefix)/eid/") {
            let emojis = strippedParamsLink.replacingOccurrences(of: "\(deeplinkPrefix)/eid/", with: "")
            try self.init(emojis: emojis)
            return
        } else if strippedParamsLink.hasPrefix("\(deeplinkPrefix)/pubkey/") {
            let hex = strippedParamsLink.replacingOccurrences(of: "\(deeplinkPrefix)/pubkey/", with: "")
            try self.init(hex: hex)
            return
        }

        throw PublicKeyError.invalidDeepLinkType
    }

    //Attempts to derive a pubkey from a emoji deeplink, or hex string (In order of most likely)
    convenience init(any: String) throws {
        do {
            try self.init(emojis: any)
            return
        } catch {}

        do {
            try self.init(deeplink: any)
            return
        } catch {}

        do {
            try self.init(hex: any)
            return
        } catch {}

        let filteredEmojis = PublicKey.filterEmojis(any)
        //Attempt to strip out a valid emoji ID from the string and init again
        if filteredEmojis.count >= PublicKey.emojiCount {
            do {
                try self.init(emojis: filteredEmojis)
                return
            } catch {}
        }

        //User might have an emoji ID from an outdated set
        if PublicKey.isOldEmojiSet(any) {
            throw PublicKeyError.invalidEmojiSet
        }

        throw PublicKeyError.cantDerivePublicKeyFromString
    }

    init(pointer: OpaquePointer) {
        ptr = pointer
    }

    private static func removeDeepURLParams(_ link: String) -> String {
        guard let startIndex = link.lastIndex(of: "?") else {
            return link
        }

        let endIndex = link.index(link.endIndex, offsetBy: -1)

        var strippedLink = link
        strippedLink.removeSubrange(startIndex...endIndex)

        return strippedLink
    }

    private static func filterEmojis(_ text: String) -> String {
        var emojis = ""

        let fullEmojiSet = EmojiSet().list.0

        for scalar in text.unicodeScalars {
            if fullEmojiSet.contains(String(scalar)) {
                emojis.append(Character(scalar))
            }
        }

        return emojis
    }

    private static func isOldEmojiSet(_ text: String) -> Bool {
        let oldEmojiSet = [
            "😀", "😂", "🤣", "😉", "😊", "😎", "😍", "😘", "🤗", "🤩", "🤔", "🙄", "😮", "🤐", "😴", "😛", "🤤", "🙃", "🤑",
            "😤", "😨", "🤯", "😬", "😱", "🤪", "😵", "😷", "🤢", "🤮", "🤠", "🤡", "🤫", "🤭", "🤓", "😈", "👻", "👽", "🤖",
            "💩", "😺", "👶", "👩", "👨", "👮", "🤴", "👸", "🧜", "🙅", "🙋", "🤦", "🤷", "💇", "🏃", "💃", "🧗", "🛀", "🛌",
            "👤", "🏄", "🚴", "🤹", "💏", "👪", "💪", "👈", "👍", "✋", "👊", "👐", "🙏", "🤝", "💅", "👂", "👀", "🧠", "👄",
            "💔", "💖", "💙", "💌", "💤", "💣", "💥", "💦", "💨", "💫", "👔", "👕", "👖", "🧣", "🧤", "🧦", "👗", "👙", "👜",
            "🎒", "👑", "🧢", "💍", "💎", "🐒", "🐶", "🦁", "🐴", "🦄", "🐮", "🐷", "🐑", "🐫", "🦒", "🐘", "🐭", "🐇", "🐔",
            "🦆", "🐸", "🐍", "🐳", "🐚", "🦀", "🐌", "🦋", "🌸", "🌲", "🌵", "🍇", "🍉", "🍌", "🍎", "🍒", "🍓", "🥑", "🥕",
            "🌽", "🍄", "🥜", "🍞", "🧀", "🍖", "🍔", "🍟", "🍕", "🍿", "🍦", "🍪", "🍰", "🍫", "🍬", "🍷", "🍺", "🍴", "🌍",
            "🌋", "🏠", "⛺", "🎡", "🎢", "🎨", "🚂", "🚌", "🚑", "🚒", "🚔", "🚕", "🚜", "🚲", "⛽", "🚦", "🚧", "⛵", "🚢",
            "🛫", "💺", "🚁", "🚀", "🛸", "🚪", "🚽", "🚿", "⌛", "⏰", "🕙", "🌛", "🌞", "⛅", "🌀", "🌈", "🌂", "🔥", "✨",
            "🎈", "🎉", "🎀", "🎁", "🏆", "🏅", "⚽", "🏀", "🏈", "🎾", "🥊", "🎯", "⛳", "🎣", "🎮", "🎲", "🔈", "🔔", "🎶",
            "🎤", "🎧", "📻", "🎸", "🎹", "🎺", "🎻", "🥁", "📱", "🔋", "💻", "📷", "🔍", "🔭", "📡", "💡", "🔦", "📖", "📚",
            "📝", "📅", "📌", "📎", "🔒", "🔑", "🔨", "🏹", "🔧", "💉", "💊", "🏧", "⛔", "🚫", "✅", "❌", "❓", "❕", "💯",
            "🆗", "🆘", "⬛", "🔶", "🔵", "🏁", "🚩", "🎌", "🏴"
        ]

        var cleanEmojis = ""

        //Extract old emojis from string
        for scalar in text.unicodeScalars {
            if oldEmojiSet.contains(String(scalar)) {
                cleanEmojis.append(Character(scalar))
            }
        }
        print("cleanEmojis: ", cleanEmojis.count)

        if cleanEmojis.count == PublicKey.emojiCount {
            return true
        }

        return false
    }

    deinit {
        public_key_destroy(ptr)
    }
}

extension PublicKey: Equatable {
    static func == (lhs: PublicKey, rhs: PublicKey) -> Bool {
        return lhs.hex.0 == rhs.hex.0
    }
}

extension PublicKey: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(hex.0)
    }
}
