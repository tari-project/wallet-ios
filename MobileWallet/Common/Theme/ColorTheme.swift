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
    let system: System
    let shadows: Shadows
}

extension ColorTheme {

    static var light: Self {
        Self(
            brand: Brand(
                purple: .Light.Brand.purple,
                pink: .Light.Brand.pink,
                darkBlue: .Light.Brand.darkBlue
            ),
            neutral: Neutral(
                primary: .Light.Neutral.primary,
                secondary: .Light.Neutral.secondary,
                tertiary: .Light.Neutral.tertiary,
                inactive: .Light.Neutral.inactive
            ),
            buttons: Buttons(
                primaryStart: .Light.Buttons.primaryStart,
                primaryEnd: .Light.Buttons.primaryEnd,
                disabled: .Light.Buttons.disabled,
                primaryText: .Light.Buttons.primaryText,
                disabledText: .Light.Buttons.disabledText
            ),
            text: Text(
                heading: .Light.Text.heading,
                body: .Light.Text.body,
                lightText: .Light.Text.lightText,
                links: .Light.Text.links
            ),
            icons: Icons(
                default: .Light.Icons.default,
                active: .Light.Icons.active,
                inactive: .Light.Icons.inactive
            ),
            components: Components(
                qrBackground: .Light.Components.qrBackground,
                overlay: .Light.Components.overlay
            ),
            backgrounds: Backgrounds(
                primary: .Light.Backgrounds.primary,
                secondary: .Light.Backgrounds.secondary
            ),
            system: System(
                red: .Light.System.red,
                orange: .Light.System.orange,
                yellow: .Light.System.yellow,
                green: .Light.System.green,
                blue: .Light.System.blue,
                lightRed: .Light.System.lightGreen,
                lightOrange: .Light.System.lightOrange,
                lightYellow: .Light.System.lightYellow,
                lightGreen: .Light.System.lightGreen,
                lightBlue: .Light.System.lightBlue
            ),
            shadows: Shadows(
                box: Shadow(color: .Light.Shadows.box, opacity: 1.0, radius: 13.5, offset: CGSize(width: -1.0, height: 6.5))
            )
        )
    }

    static var dark: Self {
        Self(
            brand: Brand(
                purple: .Dark.Brand.purple,
                pink: .Dark.Brand.pink,
                darkBlue: .Dark.Brand.darkBlue
            ),
            neutral: Neutral(
                primary: .Dark.Neutral.primary,
                secondary: .Dark.Neutral.secondary,
                tertiary: .Dark.Neutral.tertiary,
                inactive: .Dark.Neutral.inactive
            ),
            buttons: Buttons(
                primaryStart: .Dark.Buttons.primaryStart,
                primaryEnd: .Dark.Buttons.primaryEnd,
                disabled: .Dark.Buttons.disabled,
                primaryText: .Dark.Buttons.primaryText,
                disabledText: .Dark.Buttons.disabledText
            ),
            text: Text(
                heading: .Dark.Text.heading,
                body: .Dark.Text.body,
                lightText: .Dark.Text.lightText,
                links: .Dark.Text.links
            ),
            icons: Icons(
                default: .Dark.Icons.default,
                active: .Dark.Icons.active,
                inactive: .Dark.Icons.inactive
            ),
            components: Components(
                qrBackground: .Dark.Components.qrBackground,
                overlay: .Dark.Components.overlay
            ),
            backgrounds: Backgrounds(
                primary: .Dark.Backgrounds.primary,
                secondary: .Dark.Backgrounds.secondary
            ),
            system: System(
                red: .Dark.System.red,
                orange: .Dark.System.orange,
                yellow: .Dark.System.yellow,
                green: .Dark.System.green,
                blue: .Dark.System.blue,
                lightRed: .Dark.System.lightRed,
                lightOrange: .Dark.System.lightOrange,
                lightYellow: .Dark.System.lightYellow,
                lightGreen: .Dark.System.lightGreen,
                lightBlue: .Dark.System.lightBlue
            ),
            shadows: Shadows(
                box: Shadow(color: .Dark.Shadows.box, opacity: 1.0, radius: 18.0, offset: CGSize(width: -1.0, height: 0.0))
            )
        )
    }

    static var tariPurple: Self {
        Self(
            brand: Brand(
                purple: .TariPurple.Brand.purple,
                pink: .TariPurple.Brand.pink,
                darkBlue: .TariPurple.Brand.darkBlue
            ),
            neutral: Neutral(
                primary: .TariPurple.Neutral.primary,
                secondary: .TariPurple.Neutral.secondary,
                tertiary: .TariPurple.Neutral.tertiary,
                inactive: .TariPurple.Neutral.inactive
            ),
            buttons: Buttons(
                primaryStart: .TariPurple.Buttons.primaryStart,
                primaryEnd: .TariPurple.Buttons.primaryEnd,
                disabled: .TariPurple.Buttons.disabled,
                primaryText: .TariPurple.Buttons.primaryText,
                disabledText: .TariPurple.Buttons.disabledText
            ),
            text: Text(
                heading: .TariPurple.Text.heading,
                body: .TariPurple.Text.body,
                lightText: .TariPurple.Text.lightText,
                links: .TariPurple.Text.links
            ),
            icons: Icons(
                default: .TariPurple.Icons.default,
                active: .TariPurple.Icons.active,
                inactive: .TariPurple.Icons.inactive
            ),
            components: Components(
                qrBackground: .TariPurple.Components.qrBackground,
                overlay: .TariPurple.Components.overlay
            ),
            backgrounds: Backgrounds(
                primary: .TariPurple.Backgrounds.primary,
                secondary: .TariPurple.Backgrounds.secondary
            ),
            system: System(
                red: .TariPurple.System.red,
                orange: .TariPurple.System.orange,
                yellow: .TariPurple.System.yellow,
                green: .TariPurple.System.green,
                blue: .TariPurple.System.blue,
                lightRed: .TariPurple.System.lightRed,
                lightOrange: .TariPurple.System.lightOrange,
                lightYellow: .TariPurple.System.lightYellow,
                lightGreen: .TariPurple.System.lightGreen,
                lightBlue: .TariPurple.System.lightBlue
            ),
            shadows: Shadows(
                box: Shadow(color: .TariPurple.Shadows.box, opacity: 1.0, radius: 18.0, offset: CGSize(width: -1.0, height: 0.0))
            )
        )
    }
}
