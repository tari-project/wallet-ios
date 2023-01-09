//  CustomBridgesViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 03.09.2020
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

import UIKit
import Combine

final class CustomBridgesViewController: SettingsParentTableViewController, CustomBridgesHandable {

    private enum Section: Int, CaseIterable {
        case requestBridges
        case QRcode
    }

    private enum CustomBridgesTitle: CaseIterable {
        case requestBridgesFromTorproject
        case scanQRCode
        case uploadQRCode

        var rawValue: String {
            switch self {
            case .requestBridgesFromTorproject: return localized("custom_bridges.item.request_bridges_from_torproject")
            case .scanQRCode: return localized("custom_bridges.item.scan_QR_code")
            case .uploadQRCode: return localized("custom_bridges.item.upload_QR_code")
            }
        }
    }

    private weak var bridgesConfiguration: BridgesConfiguration?
    private let examplePlaceHolderString = """
    Available formates:
    • obfs4 <IP ADDRESS>:<PORT> <FINGERPRINT> cert=<CERTIFICATE> iat-mode=<value>
    example:
    obfs4 192.95.36.142:443 CDF2E852BF539B82BD10E27E9115A31734E378C2 cert=qUVQ0srL1JI/vO6V6m/24anYXiJD3QP2HgzUKQtQ7GRqqUvs7P+tG43RtAqdhLOALP7DJQ iat-mode=1

    • <IP ADDRESS>:<PORT> <FINGERPRINT>
    example:
    78.156.103.189:9301 2BD90810282F8B331FC7D47705167166253E1442
    """
    private lazy var detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

    private let headerView = CustomBridgesHeaderView()

    private let requestBridgesSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: CustomBridgesTitle.requestBridgesFromTorproject.rawValue)
    ]

    private let qrSectionItems: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: CustomBridgesTitle.scanQRCode.rawValue),
        SystemMenuTableViewCellItem(title: CustomBridgesTitle.uploadQRCode.rawValue)
    ]

    private var cancellables = Set<AnyCancellable>()

    init(bridgesConfiguration: BridgesConfiguration) {
        self.bridgesConfiguration = bridgesConfiguration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        setupCustomBridgeProgressHandler()
            .store(in: &cancellables)
    }
}

// MARK: Setup subviews
extension CustomBridgesViewController {
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = localized("custom_bridges.title")
        navigationBar.rightButton.isEnabled = false
        navigationBar.onRightButtonAction = connectAction
        let title = localized("custom_bridges.connect")
        navigationBar.rightButton.setTitle(title, for: .normal)
    }

    private func onTorConnDifficulties(error: Error) {
        applyConnectingStatus() // for returning to previous bridges configuration
        let backupConfiguration = OnionSettings.backupBridgesConfiguration
        let currentBridgesStr = backupConfiguration.customBridges?.joined(separator: "\n")
        bridgesConfiguration?.customBridges = backupConfiguration.customBridges
        bridgesConfiguration?.bridgesType = backupConfiguration.bridgesType
        headerView.text = (currentBridgesStr?.isEmpty ?? true) ? examplePlaceHolderString : currentBridgesStr
        onCustomBridgeFailureAction(error: error)
    }

    private func openScannerVC() {
        let vc = ScanViewController(scanResourceType: .bridges)
        vc.actionDelegate = self
        vc.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .automatic :.popover
        present(vc, animated: true, completion: nil)
    }

    private func openImagePickerVC() {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .automatic :.popover
        present(vc, animated: true, completion: nil)
    }

    private func connectAction() {

        guard let bridgesConfiguration = bridgesConfiguration else { return }
        applyConnectingStatus()

        bridgesConfiguration.customBridges = (headerView.text ?? "")
                .components(separatedBy: "\n")
                .map({ bridge in bridge.trimmingCharacters(in: .whitespacesAndNewlines) })
                .filter({ bridge in !bridge.isEmpty && !bridge.hasPrefix("//") && !bridge.hasPrefix("#") })

        bridgesConfiguration.bridgesType = bridgesConfiguration.customBridges?.isEmpty == true ? .none : .custom

        headerView.resignFirstResponder()

        Task {
            do {
                try await Tari.shared.update(torBridgesConfiguration: bridgesConfiguration)
                onCustomBridgeSuccessAction()
            } catch {
                onTorConnDifficulties(error: error)
            }
        }
    }

    private func applyConnectingStatus() {
        navigationBar.progress = 0.0
        navigationBar.rightButton.isEnabled = false
        view.isUserInteractionEnabled = false
    }
}

extension CustomBridgesViewController: ScanViewControllerDelegate {
    func onAdd(string: String) {
        headerView.text = string
    }
}

extension CustomBridgesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        var raw = ""

        if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage,
            let ciImage = image.ciImage ?? (image.cgImage != nil ? CIImage(cgImage: image.cgImage!) : nil) {

            let features = detector?.features(in: ciImage)

            for feature in features as? [CIQRCodeFeature] ?? [] {
                raw += feature.messageString ?? ""
            }
        }

        if let bridges = raw.findBridges() {
            onAdd(string: bridges)
        } else {
            PopUpPresenter.show(message: MessageModel(title: localized("custom_bridges.error.image_decode.title"), message: localized("custom_bridges.error.image_decode.description"), type: .error))
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension CustomBridgesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .requestBridges:
            return requestBridgesSectionItems.count
        case .QRcode:
            return qrSectionItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SystemMenuTableViewCell.self), for: indexPath) as! SystemMenuTableViewCell
        guard let section = Section(rawValue: indexPath.section) else { return cell }

        switch section {
        case .requestBridges: cell.configure(requestBridgesSectionItems[indexPath.row])
        case .QRcode: cell.configure(qrSectionItems[indexPath.row])
        }

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        65
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section != 0 { return 35 }
        return 210
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section != 0 { return nil }

        let customBridgesText = bridgesConfiguration?.customBridges?.joined(separator: "\n")
        let text = (customBridgesText?.isEmpty ?? true) ? examplePlaceHolderString : customBridgesText

        headerView.text = text
        headerView.textViewDelegate = self

        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .requestBridges:
            WebBrowserPresenter.open(url: OnionSettings.torBridgesLink)
        case .QRcode:
            if CustomBridgesTitle.allCases[indexPath.row + indexPath.section] == .scanQRCode {
                openScannerVC()
                return
            }
            if CustomBridgesTitle.allCases[indexPath.row + indexPath.section] == .uploadQRCode {
                openImagePickerVC()
                return
            }

        }
    }
}

extension CustomBridgesViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.count == 0 {
            return true
        }
        let string = textView.attributedText.string as NSString
        let newString = string.replacingCharacters(in: range, with: text)

        if let currentPosition = textView.selectedTextRange?.start,
           let newPosition = textView.position(from: currentPosition, offset: text.count) {
            headerView.text = newString
            textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
        } else {
            headerView.text = newString
        }
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        navigationBar.rightButton.isEnabled = textView.text.count > 0 && textView.text.trimmingCharacters(in: .whitespacesAndNewlines) != bridgesConfiguration?.customBridges?.joined(separator: "\n") && textView.text != examplePlaceHolderString
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == examplePlaceHolderString && !headerView.isTextViewActive {
            textView.text = ""
        }

        headerView.isTextViewActive = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = examplePlaceHolderString
        }

        headerView.isTextViewActive = false
    }
}
