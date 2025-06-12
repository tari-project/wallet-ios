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

struct Colors {
    struct Action {
        let active: UIColor?
        let disabled: UIColor?
        let disabledBackground: UIColor?
        let focus: UIColor?
        let hover: UIColor?
        let selected: UIColor?
    }
    let action: Action

    struct Background {
        let accent: UIColor?
        let popup: UIColor?
        let primary: UIColor?
        let secondary: UIColor?
    }
    let background: Background

    struct Button {
        let outlined: UIColor?
        let primaryBackground: UIColor?
        let primaryText: UIColor?
    }
    let button: Button

    struct Common {
        let blackMain: UIColor?
        let whiteMain: UIColor?
    }
    let common: Common

    struct Components {
        let chipDefaultBackground: UIColor?
        let chipDefaultText: UIColor?
        let navbarBackground: UIColor?
        let navbarIcons: UIColor?
    }
    let components: Components

    struct Elevation {
        let outlined: UIColor?
    }
    let elevation: Elevation

    struct Error {
        let main: UIColor?
        let light: UIColor?
        let dark: UIColor?
        let contrast: UIColor?
    }
    let error: Error

    struct Info {
        let main: UIColor?
        let light: UIColor?
        let dark: UIColor?
        let contrast: UIColor?
    }
    let info: Info

    struct Primary {
        let contrast: UIColor?
        let dark: UIColor?
        let focus: UIColor?
        let focusVisible: UIColor?
        let hover: UIColor?
        let light: UIColor?
        let main: UIColor?
        let outlinedBorder: UIColor?
        let selected: UIColor?
    }
    let primary: Primary

    struct Secondary {
        let main: UIColor?
        let light: UIColor?
        let dark: UIColor?
        let contrast: UIColor?
    }
    let secondary: Secondary

    struct Success {
        let main: UIColor?
        let light: UIColor?
        let dark: UIColor?
        let contrast: UIColor?
    }
    let success: Success

    struct System {
        let green: UIColor?
        let red: UIColor?
        let yellow: UIColor?
        let secondaryGreen: UIColor?
        let secondaryRed: UIColor?
        let secondaryYellow: UIColor?
    }
    let system: System

    struct Text {
        let disabled: UIColor?
        let primary: UIColor?
        let secondary: UIColor?
    }
    let text: Text

    struct Token {
        let divider: UIColor?
    }
    let token: Token

    struct Warning {
        let main: UIColor?
        let light: UIColor?
        let dark: UIColor?
        let contrast: UIColor?
    }
    let warning: Warning
}

struct AppTheme {

    struct Graphics {
        let splashScreenImage: UIImage?
    }

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
        var secondaryText: UIColor?
        var disabledText: UIColor?
        var primaryBackground: UIColor?
        var secondaryBackground: UIColor?
        var borderPrimary: UIColor?
        var borderSecondary: UIColor?
    }

    struct Text {
        var heading: UIColor?
        var body: UIColor?
        var lightText: UIColor?
        var links: UIColor?
        var primary: UIColor?
        var title: UIColor?
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

    let graphics: Graphics
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

extension AppTheme {
    static var colors: Colors {
        Colors(
            action: Colors.Action(active: .Action.active,
                                  disabled: .Action.disabled,
                                  disabledBackground: .Action.disabledBackground,
                                  focus: .Action.focus,
                                  hover: .Action.hover,
                                  selected: .Action.selected),
            background: Colors.Background(accent: .Background.accent,
                                          popup: .Background.popup,
                                          primary: .Background.primary,
                                          secondary: .Background.secondary),
            button: Colors.Button(outlined: .Button.outlined,
                                  primaryBackground: .Button.primaryBg,
                                  primaryText: .Button.primaryText),
            common: Colors.Common(blackMain: .Common.blackmain, whiteMain: .Common.whitemain),
            components: Colors.Components(chipDefaultBackground: .Components.chipDefaultBackground,
                                          chipDefaultText: .Components.chipDefaultText,
                                          navbarBackground: .Components.navbarBackground,
                                          navbarIcons: .Components.navbarIcons),
            elevation: Colors.Elevation(outlined: .Elevation.outlined),
            error: Colors.Error(main: .Error.main,
                                light: .Error.light,
                                dark: .Error.dark,
                                contrast: .Error.contrast),
            info: Colors.Info(main: .Info.main,
                              light: .Info.light,
                              dark: .Info.dark,
                              contrast: .Info.contrast),
            primary: Colors.Primary(contrast: .Primary.contrast,
                                    dark: .Primary.dark,
                                    focus: .Primary.focus,
                                    focusVisible: .Primary.focusVisible,
                                    hover: .Primary.hover,
                                    light: .Primary.light,
                                    main: .Primary.main,
                                    outlinedBorder: .Primary.outlinedBorder,
                                    selected: .Primary.selected),
            secondary: Colors.Secondary(main: .Secondary.main,
                                        light: .Secondary.light,
                                        dark: .Secondary.dark,
                                        contrast: .Secondary.contrast),
            success: Colors.Success(main: .Success.main,
                                    light: .Success.light,
                                    dark: .Success.dark,
                                    contrast: .Success.contrast),
            system: Colors.System(green: .System.green,
                                  red: .System.red,
                                  yellow: .System.yellow,
                                  secondaryGreen: .System.secondaryGreen,
                                  secondaryRed: .System.secondaryRed,
                                  secondaryYellow: .System.secondaryYellow),
            text: Colors.Text(disabled: .Text.disabled,
                              primary: .Text.primary,
                              secondary: .Text.secondary),
            token: Colors.Token(divider: .Token.divider),
            warning: Colors.Warning(main: .Warning.main,
                                    light: .Warning.light,
                                    dark: .Warning.dark,
                                    contrast: .Warning.contrast)
        )
    }

    static var light: Self {
        Self(
            graphics: Graphics(
                splashScreenImage: UIImage(resource: .staticSplash)
            ),

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
                disabled: .Light.Buttons.disabled,
                primaryText: .Light.Buttons.primaryText,
                secondaryText: .Light.Buttons.secondaryText,
                disabledText: .Light.Buttons.disabledText,
                primaryBackground: .Light.Buttons.primaryBackground,
                secondaryBackground: .Light.Buttons.secondaryBackground,
                borderPrimary: .Light.Buttons.primaryBorder,
                borderSecondary: .Light.Buttons.secondaryBorder
            ),
            text: Text(
                heading: .Light.Text.heading,
                body: .Light.Text.body,
                lightText: .Light.Text.lightText,
                links: .Light.Text.links,
                primary: .Light.Text.primary,
                title: .Light.Text.title

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
            graphics: Graphics(
                splashScreenImage: UIImage(resource: .staticSplash)
            ),

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
                disabled: .Dark.Buttons.disabled,
                primaryText: .Dark.Buttons.primaryText,
                secondaryText: .Dark.Buttons.secondaryText,
                disabledText: .Dark.Buttons.disabledText,
                primaryBackground: .Dark.Buttons.primaryBackground,
                secondaryBackground: .Dark.Buttons.secondaryBackground,
                borderPrimary: .Dark.Buttons.primaryBorder,
                borderSecondary: .Dark.Buttons.secondaryBorder
            ),
            text: Text(
                heading: .Dark.Text.heading,
                body: .Dark.Text.body,
                lightText: .Dark.Text.lightText,
                links: .Dark.Text.links,
                primary: .Dark.Text.primary,
                title: .Dark.Text.title
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
}
