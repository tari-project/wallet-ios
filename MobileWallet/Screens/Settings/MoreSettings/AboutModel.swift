//  AboutModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/05/2022
	Using Swift 5.0
	Running on macOS 12.3

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

final class AboutModel {

    struct RowModel {
        let icon: UIImage?
        let title: String
    }

    struct RowData {
        let model: RowModel
        let url: URL?
    }

    @Published private(set) var rowModels: [RowModel] = []
    @Published private(set) var selectedURL: URL?

    private let rowsData: [RowData] = [
        RowData(model: RowModel(icon: Theme.shared.images.settingsWalletBackupsIcon, title: "Locked Lock by BlackActurus from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/locked-lock-3734872/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsAboutIcon, title: "About by Anggara Putra from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/about-4860865/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsReportBugIcon, title: "Speech Bubbles by Design Circle from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/speech-bubbles-4213155/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsContributeIcon, title: "Keyboard by Design Circle from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/keyboard-4213010/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsUserAgreementIcon, title: "Writing by Design Circle from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/writing-4213261/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsPrivacyPolicyIcon, title: "Privacy by Gregor Cresnar from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/privacy-1381695/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsDisclaimerIcon, title: "Bullhorn by Design Circle from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/bullhorn-4213159/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsBlockExplorerIcon, title: "Magnifier by Design Circle from\nNounProject.com (Modified)"), url: URL(string: "https://thenounproject.com/icon/magnifier-4213152/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingColorThemeIcon, title: "Theme by icon 54 from\nNoun Project.com"), url: URL(string: "https://thenounproject.com/icon/theme-396505/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsBridgeConfigIcon, title: "Repair Tools by Design Circle from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/repair-tools-4213156/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsNetworkIcon, title: "Internet Server by Design Circle from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/internet-server-4213144/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsBaseNodeIcon, title: "Networking by Design Circle from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/networking-4213263/")),
        RowData(model: RowModel(icon: Theme.shared.images.settingsDeleteIcon, title: "Delete by Maya Nurhayati from\nNounProject.com"), url: URL(string: "https://thenounproject.com/icon/delete-4727971/")),
        RowData(model: RowModel(icon: .security.onboarding.page1, title: "Write by Mada Creative from NounProject.com"), url: URL(string: "https://thenounproject.com/icon/write-4207866/")),
        RowData(model: RowModel(icon: .security.onboarding.page2, title: "Cloud by Tippawan Sookruay from NounProject.com"), url: URL(string: "https://thenounproject.com/icon/cloud-3384041/")),
        RowData(model: RowModel(icon: .security.onboarding.page3, title: "Password by Tippawan Sookruay from NounProject.com"), url: URL(string: "https://thenounproject.com/icon/password-3384056/")),
        RowData(model: RowModel(icon: .security.onboarding.page4, title: "Key by Tippawan Sookruay from NounProject.com"), url: URL(string: "https://thenounproject.com/icon/key-3384048/"))
    ]

    private let creativeCommonsURL = URL(string: "https://creativecommons.org/licenses/by/3.0/")

    func generateData() {
        rowModels = rowsData.map { $0.model }
    }

    func selectCrativeCommonButton() {
        selectedURL = creativeCommonsURL
    }

    func select(index: Int) {
        selectedURL = rowsData[index].url
    }
}
