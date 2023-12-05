//  ColorTheme.swift

/*
	Package MobileWallet
	Created by Browncoat on 25/11/2022
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

import UIKit

struct ColorTheme {

    struct Brand {
        let purple: UIColor?
        let pink: UIColor?
        let darkBlue: UIColor?
    }

    struct Neutral {
        var primary: UIColor?
        var secondary: UIColor?
        var tertiary: UIColor?
        var inactive: UIColor?
    }

    struct Buttons {
        var primaryStart: UIColor?
        var primaryEnd: UIColor?
        var disabled: UIColor?
        var primaryText: UIColor?
        var disabledText: UIColor?
    }

    struct Text {
        var heading: UIColor?
        var body: UIColor?
        var lightText: UIColor?
        var links: UIColor?
    }

    struct Icons {
        var `default`: UIColor?
        var active: UIColor?
        var inactive: UIColor?
    }

    struct Components {
        var qrBackground: UIColor?
        var overlay: UIColor?
    }

    struct Backgrounds {
        var primary: UIColor?
        var secondary: UIColor?
    }

    struct Chat {
        var backgrounds: ChatBackgrounds
        var text: ChatText
    }

    struct ChatBackgrounds {
        var sender: UIColor?
        var senderNotification: UIColor?
        var receiver: UIColor?
        var receiverNotification: UIColor?
    }

    struct ChatText {
        var text: UIColor?
        var textNotification: UIColor?
    }

    struct System {
        var red: UIColor?
        var orange: UIColor?
        var yellow: UIColor?
        var green: UIColor?
        var blue: UIColor?
        var lightRed: UIColor?
        var lightOrange: UIColor?
        var lightYellow: UIColor?
        var lightGreen: UIColor?
        var lightBlue: UIColor?
    }

    struct Shadows {
        var box: Shadow
    }

    // MARK: - Properties

    let brand: Brand
    let neutral: Neutral
    let buttons: Buttons
    let text: Text
    let icons: Icons
    let components: Components
    let backgrounds: Backgrounds
    let chat: Chat
    let system: System
    let shadows: Shadows
}

extension ColorTheme {

    static var light: Self {
        Self(
            brand: Brand(
                purple: UIColor(named: "Light/Brand/Purple"),
                pink: UIColor(named: "Light/Brand/Pink"),
                darkBlue: UIColor(named: "Light/Brand/Dark Blue")
            ),
            neutral: Neutral(
                primary: UIColor(named: "Light/Neutral/Primary"),
                secondary: UIColor(named: "Light/Neutral/Secondary"),
                tertiary: UIColor(named: "Light/Neutral/Tertiary"),
                inactive: UIColor(named: "Light/Neutral/Inactive")
            ),
            buttons: Buttons(
                primaryStart: UIColor(named: "Light/Buttons/PrimaryStart"),
                primaryEnd: UIColor(named: "Light/Buttons/PrimaryEnd"),
                disabled: UIColor(named: "Light/Buttons/Disabled"),
                primaryText: UIColor(named: "Light/Buttons/Primary Text"),
                disabledText: UIColor(named: "Light/Buttons/Disabled Text")
            ),
            text: Text(
                heading: UIColor(named: "Light/Text/Heading"),
                body: UIColor(named: "Light/Text/Body"),
                lightText: UIColor(named: "Light/Text/Light Text"),
                links: UIColor(named: "Light/Text/Links")
            ),
            icons: Icons(
                default: UIColor(named: "Light/Icons/Default"),
                active: UIColor(named: "Light/Icons/Active"),
                inactive: UIColor(named: "Light/Icons/Inactive")
            ),
            components: Components(
                qrBackground: UIColor(named: "Light/Components/QR Background"),
                overlay: UIColor(named: "Light/Components/Overlay")
            ),
            backgrounds: Backgrounds(
                primary: UIColor(named: "Light/Backgrounds/Primary"),
                secondary: UIColor(named: "Light/Backgrounds/Secondary")
            ),
            chat: Chat(
                backgrounds: ChatBackgrounds(
                    sender: UIColor(named: "Light/Chat/Backgrounds/Sender"),
                    senderNotification: UIColor(named: "Light/Chat/Backgrounds/Sender Notification"),
                    receiver: UIColor(named: "Light/Chat/Backgrounds/Receiver"),
                    receiverNotification: UIColor(named: "Light/Chat/Backgrounds/Receiver Notification")
                ),
                text: ChatText(
                    text: UIColor(named: "Light/Chat/Text/Text"),
                    textNotification: UIColor(named: "Light/Chat/Text/Text Notification")
                )
            ),
            system: System(
                red: UIColor(named: "Light/System/Red"),
                orange: UIColor(named: "Light/System/Orange"),
                yellow: UIColor(named: "Light/System/Yellow"),
                green: UIColor(named: "Light/System/Green"),
                blue: UIColor(named: "Light/System/Blue"),
                lightRed: UIColor(named: "Light/System/Light Red"),
                lightOrange: UIColor(named: "Light/System/Light Orange"),
                lightYellow: UIColor(named: "Light/System/Light Yellow"),
                lightGreen: UIColor(named: "Light/System/Light Green"),
                lightBlue: UIColor(named: "Light/System/Light Blue")
            ),
            shadows: Shadows(
                box: Shadow(color: UIColor(named: "Light/Shadows/Box"), opacity: 1.0, radius: 13.5, offset: CGSize(width: -1.0, height: 6.5))
            )
        )
    }

    static var dark: Self {
        Self(
            brand: Brand(
                purple: UIColor(named: "Dark/Brand/Purple"),
                pink: UIColor(named: "Dark/Brand/Pink"),
                darkBlue: UIColor(named: "Dark/Brand/Dark Blue")
            ),
            neutral: Neutral(
                primary: UIColor(named: "Dark/Neutral/Primary"),
                secondary: UIColor(named: "Dark/Neutral/Secondary"),
                tertiary: UIColor(named: "Dark/Neutral/Tertiary"),
                inactive: UIColor(named: "Dark/Neutral/Inactive")
            ),
            buttons: Buttons(
                primaryStart: UIColor(named: "Dark/Buttons/PrimaryStart"),
                primaryEnd: UIColor(named: "Dark/Buttons/PrimaryEnd"),
                disabled: UIColor(named: "Dark/Buttons/Disabled"),
                primaryText: UIColor(named: "Dark/Buttons/Primary Text"),
                disabledText: UIColor(named: "Dark/Buttons/Disabled Text")
            ),
            text: Text(
                heading: UIColor(named: "Dark/Text/Heading"),
                body: UIColor(named: "Dark/Text/Body"),
                lightText: UIColor(named: "Dark/Text/Light Text"),
                links: UIColor(named: "Dark/Text/Links")
            ),
            icons: Icons(
                default: UIColor(named: "Dark/Icons/Default"),
                active: UIColor(named: "Dark/Icons/Active"),
                inactive: UIColor(named: "Dark/Icons/Inactive")
            ),
            components: Components(
                qrBackground: UIColor(named: "Dark/Components/QR Background"),
                overlay: UIColor(named: "Dark/Components/Overlay")
            ),
            backgrounds: Backgrounds(
                primary: UIColor(named: "Dark/Backgrounds/Primary"),
                secondary: UIColor(named: "Dark/Backgrounds/Secondary")
            ),
            chat: Chat(
                backgrounds: ChatBackgrounds(
                    sender: UIColor(named: "Dark/Chat/Backgrounds/Sender"),
                    senderNotification: UIColor(named: "Dark/Chat/Backgrounds/Sender Notification"),
                    receiver: UIColor(named: "Dark/Chat/Backgrounds/Receiver"),
                    receiverNotification: UIColor(named: "Dark/Chat/Backgrounds/Receiver Notification")
                ),
                text: ChatText(
                    text: UIColor(named: "Dark/Chat/Text/Text"),
                    textNotification: UIColor(named: "Dark/Chat/Text/Text Notification")
                )
            ),
            system: System(
                red: UIColor(named: "Dark/System/Red"),
                orange: UIColor(named: "Dark/System/Orange"),
                yellow: UIColor(named: "Dark/System/Yellow"),
                green: UIColor(named: "Dark/System/Green"),
                blue: UIColor(named: "Dark/System/Blue"),
                lightRed: UIColor(named: "Dark/System/Light Red"),
                lightOrange: UIColor(named: "Dark/System/Light Orange"),
                lightYellow: UIColor(named: "Dark/System/Light Yellow"),
                lightGreen: UIColor(named: "Dark/System/Light Green"),
                lightBlue: UIColor(named: "Dark/System/Light Blue")
            ),
            shadows: Shadows(
                box: Shadow(color: UIColor(named: "Dark/Shadows/Box"), opacity: 1.0, radius: 18.0, offset: CGSize(width: -1.0, height: 0.0))
            )
        )
    }

    static var tariPurple: Self {
        Self(
            brand: Brand(
                purple: UIColor(named: "Tari Purple/Brand/Purple"),
                pink: UIColor(named: "Tari Purple/Brand/Pink"),
                darkBlue: UIColor(named: "Tari Purple/Brand/Dark Blue")
            ),
            neutral: Neutral(
                primary: UIColor(named: "Tari Purple/Neutral/Primary"),
                secondary: UIColor(named: "Tari Purple/Neutral/Secondary"),
                tertiary: UIColor(named: "Tari Purple/Neutral/Tertiary"),
                inactive: UIColor(named: "Tari Purple/Neutral/Inactive")
            ),
            buttons: Buttons(
                primaryStart: UIColor(named: "Tari Purple/Buttons/PrimaryStart"),
                primaryEnd: UIColor(named: "Tari Purple/Buttons/PrimaryEnd"),
                disabled: UIColor(named: "Tari Purple/Buttons/Disabled"),
                primaryText: UIColor(named: "Tari Purple/Buttons/Primary Text"),
                disabledText: UIColor(named: "Tari Purple/Buttons/Disabled Text")
            ),
            text: Text(
                heading: UIColor(named: "Tari Purple/Text/Heading"),
                body: UIColor(named: "Tari Purple/Text/Body"),
                lightText: UIColor(named: "Tari Purple/Text/Light Text"),
                links: UIColor(named: "Tari Purple/Text/Links")
            ),
            icons: Icons(
                default: UIColor(named: "Tari Purple/Icons/Default"),
                active: UIColor(named: "Tari Purple/Icons/Active"),
                inactive: UIColor(named: "Tari Purple/Icons/Inactive")
            ),
            components: Components(
                qrBackground: UIColor(named: "Tari Purple/Components/QR Background"),
                overlay: UIColor(named: "Tari Purple/Components/Overlay")
            ),
            backgrounds: Backgrounds(
                primary: UIColor(named: "Tari Purple/Backgrounds/Primary"),
                secondary: UIColor(named: "Tari Purple/Backgrounds/Secondary")
            ),
            chat: Chat(
                backgrounds: ChatBackgrounds(
                    sender: UIColor(named: "Tari Purple/Chat/Backgrounds/Sender"),
                    senderNotification: UIColor(named: "Tari Purple/Chat/Backgrounds/Sender Notification"),
                    receiver: UIColor(named: "Tari Purple/Chat/Backgrounds/Receiver"),
                    receiverNotification: UIColor(named: "Tari Purple/Chat/Backgrounds/Receiver Notification")
                ),
                text: ChatText(
                    text: UIColor(named: "Tari Purple/Chat/Text/Text"),
                    textNotification: UIColor(named: "Tari Purple/Chat/Text/Text Notification")
                )
            ),
            system: System(
                red: UIColor(named: "Tari Purple/System/Red"),
                orange: UIColor(named: "Tari Purple/System/Orange"),
                yellow: UIColor(named: "Tari Purple/System/Yellow"),
                green: UIColor(named: "Tari Purple/System/Green"),
                blue: UIColor(named: "Tari Purple/System/Blue"),
                lightRed: UIColor(named: "Tari Purple/System/Light Red"),
                lightOrange: UIColor(named: "Tari Purple/System/Light Orange"),
                lightYellow: UIColor(named: "Tari Purple/System/Light Yellow"),
                lightGreen: UIColor(named: "Tari Purple/System/Light Green"),
                lightBlue: UIColor(named: "Tari Purple/System/Light Blue")
            ),
            shadows: Shadows(
                box: Shadow(color: UIColor(named: "Tari Purple/Shadows/Box"), opacity: 1.0, radius: 18.0, offset: CGSize(width: -1.0, height: 0.0))
            )
        )
    }
}
