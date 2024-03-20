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
                purple: UIColor.Light.Brand.purple,
                pink: UIColor.Light.Brand.pink,
                darkBlue: UIColor.Light.Brand.darkBlue
            ),
            neutral: Neutral(
                primary: UIColor.Light.Neutral.primary,
                secondary: UIColor.Light.Neutral.secondary,
                tertiary: UIColor.Light.Neutral.tertiary,
                inactive: UIColor.Light.Neutral.inactive
            ),
            buttons: Buttons(
                primaryStart: UIColor.Light.Buttons.primaryStart,
                primaryEnd: UIColor.Light.Buttons.primaryEnd,
                disabled: UIColor.Light.Buttons.disabled,
                primaryText: UIColor.Light.Buttons.primaryText,
                disabledText: UIColor.Light.Buttons.disabledText
            ),
            text: Text(
                heading: UIColor.Light.Text.heading,
                body: UIColor.Light.Text.body,
                lightText: UIColor.Light.Text.lightText,
                links: UIColor.Light.Text.links
            ),
            icons: Icons(
                default: UIColor.Light.Icons.default,
                active: UIColor.Light.Icons.active,
                inactive: UIColor.Light.Icons.inactive
            ),
            components: Components(
                qrBackground: UIColor.Light.Components.qrBackground,
                overlay: UIColor.Light.Components.overlay
            ),
            backgrounds: Backgrounds(
                primary: UIColor.Light.Backgrounds.primary,
                secondary: UIColor.Light.Backgrounds.secondary
            ),
            system: System(
                red: UIColor.Light.System.red,
                orange: UIColor.Light.System.orange,
                yellow: UIColor.Light.System.yellow,
                green: UIColor.Light.System.green,
                blue: UIColor.Light.System.blue,
                lightRed: UIColor.Light.System.lightGreen,
                lightOrange: UIColor.Light.System.lightOrange,
                lightYellow: UIColor.Light.System.lightYellow,
                lightGreen: UIColor.Light.System.lightGreen,
                lightBlue: UIColor.Light.System.lightBlue
            ),
            shadows: Shadows(
                box: Shadow(color: UIColor.Light.Shadows.box, opacity: 1.0, radius: 13.5, offset: CGSize(width: -1.0, height: 6.5))
            )
        )
    }

    static var dark: Self {
        Self(
            brand: Brand(
                purple: UIColor.Dark.Brand.purple,
                pink: UIColor.Dark.Brand.pink,
                darkBlue: UIColor.Dark.Brand.darkBlue
            ),
            neutral: Neutral(
                primary: UIColor.Dark.Neutral.primary,
                secondary: UIColor.Dark.Neutral.secondary,
                tertiary: UIColor.Dark.Neutral.tertiary,
                inactive: UIColor.Dark.Neutral.inactive
            ),
            buttons: Buttons(
                primaryStart: UIColor.Dark.Buttons.primaryStart,
                primaryEnd: UIColor.Dark.Buttons.primaryEnd,
                disabled: UIColor.Dark.Buttons.disabled,
                primaryText: UIColor.Dark.Buttons.primaryText,
                disabledText: UIColor.Dark.Buttons.disabledText
            ),
            text: Text(
                heading: UIColor.Dark.Text.heading,
                body: UIColor.Dark.Text.body,
                lightText: UIColor.Dark.Text.lightText,
                links: UIColor.Dark.Text.links
            ),
            icons: Icons(
                default: UIColor.Dark.Icons.default,
                active: UIColor.Dark.Icons.active,
                inactive: UIColor.Dark.Icons.inactive
            ),
            components: Components(
                qrBackground: UIColor.Dark.Components.qrBackground,
                overlay: UIColor.Dark.Components.overlay
            ),
            backgrounds: Backgrounds(
                primary: UIColor.Dark.Backgrounds.primary,
                secondary: UIColor.Dark.Backgrounds.secondary
            ),
            system: System(
                red: UIColor.Dark.System.red,
                orange: UIColor.Dark.System.orange,
                yellow: UIColor.Dark.System.yellow,
                green: UIColor.Dark.System.green,
                blue: UIColor.Dark.System.blue,
                lightRed: UIColor.Dark.System.lightRed,
                lightOrange: UIColor.Dark.System.lightOrange,
                lightYellow: UIColor.Dark.System.lightYellow,
                lightGreen: UIColor.Dark.System.lightGreen,
                lightBlue: UIColor.Dark.System.lightBlue
            ),
            shadows: Shadows(
                box: Shadow(color: UIColor.Dark.Shadows.box, opacity: 1.0, radius: 18.0, offset: CGSize(width: -1.0, height: 0.0))
            )
        )
    }

    static var tariPurple: Self {
        Self(
            brand: Brand(
                purple: UIColor.TariPurple.Brand.purple,
                pink: UIColor.TariPurple.Brand.pink,
                darkBlue: UIColor.TariPurple.Brand.darkBlue
            ),
            neutral: Neutral(
                primary: UIColor.TariPurple.Neutral.primary,
                secondary: UIColor.TariPurple.Neutral.secondary,
                tertiary: UIColor.TariPurple.Neutral.tertiary,
                inactive: UIColor.TariPurple.Neutral.inactive
            ),
            buttons: Buttons(
                primaryStart: UIColor.TariPurple.Buttons.primaryStart,
                primaryEnd: UIColor.TariPurple.Buttons.primaryEnd,
                disabled: UIColor.TariPurple.Buttons.disabled,
                primaryText: UIColor.TariPurple.Buttons.primaryText,
                disabledText: UIColor.TariPurple.Buttons.disabledText
            ),
            text: Text(
                heading: UIColor.TariPurple.Text.heading,
                body: UIColor.TariPurple.Text.body,
                lightText: UIColor.TariPurple.Text.lightText,
                links: UIColor.TariPurple.Text.links
            ),
            icons: Icons(
                default: UIColor.TariPurple.Icons.default,
                active: UIColor.TariPurple.Icons.active,
                inactive: UIColor.TariPurple.Icons.inactive
            ),
            components: Components(
                qrBackground: UIColor.TariPurple.Components.qrBackground,
                overlay: UIColor.TariPurple.Components.overlay
            ),
            backgrounds: Backgrounds(
                primary: UIColor.TariPurple.Backgrounds.primary,
                secondary: UIColor.TariPurple.Backgrounds.secondary
            ),
            system: System(
                red: UIColor.TariPurple.System.red,
                orange: UIColor.TariPurple.System.orange,
                yellow: UIColor.TariPurple.System.yellow,
                green: UIColor.TariPurple.System.green,
                blue: UIColor.TariPurple.System.blue,
                lightRed: UIColor.TariPurple.System.lightRed,
                lightOrange: UIColor.TariPurple.System.lightOrange,
                lightYellow: UIColor.TariPurple.System.lightYellow,
                lightGreen: UIColor.TariPurple.System.lightGreen,
                lightBlue: UIColor.TariPurple.System.lightBlue
            ),
            shadows: Shadows(
                box: Shadow(color: UIColor.TariPurple.Shadows.box, opacity: 1.0, radius: 18.0, offset: CGSize(width: -1.0, height: 0.0))
            )
        )
    }
}
