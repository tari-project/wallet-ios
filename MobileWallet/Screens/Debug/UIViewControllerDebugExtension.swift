//  HomeViewControllerDebugExtension.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/23
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
import MessageUI
import ZIPFoundation

private enum DebugErrors: Error {
    case zipURL
    case createArchive
    case zipArchive
    case zipDBfiles
}

extension UIViewController: MFMailComposeViewControllerDelegate {
    func checkClipboardForBaseNode() {
        let pasteboardString: String? = UIPasteboard.general.string
        guard let clipboardText = pasteboardString else { return }

        do {
            let baseNode = try BaseNode(clipboardText)

            UserFeedback.shared.callToAction(
                title: NSLocalizedString("Set custom base node", comment: "Custom base node in clipboard call to action"),
                description: String(
                    format: NSLocalizedString(
                        "We found a base node peer in your clipboard, would you like to use this instead of the default?\n\n%@",
                        comment: "Custom base node in clipboard call to action"
                    ),
                    clipboardText
                ),
                actionTitle: NSLocalizedString("Set", comment: "Custom base node in clipboard call to action"),
                cancelTitle: NSLocalizedString("Keep default", comment: "Custom base node in clipboard call to action"),
                onAction: {
                    do {
                        try TariLib.shared.tariWallet?.addBaseNodePeer(baseNode)
                        UIPasteboard.general.string = ""
                    } catch {
                        UserFeedback.shared.error(
                            title: NSLocalizedString("Base node error", comment: "Custom base node in clipboard call to action"),
                            description: NSLocalizedString("Failed to set custom base node from clipboard", comment: "Custom base node in clipboard call to action"),
                            error: error
                        )
                    }
                },
                onCancel: {
                    UIPasteboard.general.string = ""
                }
            )
        } catch {
            //No valid peer string found in clipboard
        }
    }

    private func showTariLibLogs() {
        let logsVC = DebugLogsTableViewController()

        self.navigationController?.view.layer.add(Theme.shared.transitions.pullDownOpen, forKey: kCATransition)
        self.navigationController?.pushViewController(logsVC, animated: false)
    }

    private func deleteWallet() {
        let alert = UIAlertController(title: "Delete wallet", message: "This will erase all data and close the app.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Erase", style: .destructive, handler: { (_)in
            wipeApp()

            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(0)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    private func getEmailFooter() -> String {
        var phoneDetails: [(key: String, value: String)] = []

        phoneDetails.append((key: "Network", value: TariSettings.shared.network.rawValue))
        phoneDetails.append((key: "Phone", value: UIDevice.current.model.rawValue))
        phoneDetails.append((key: "iOS", value: UIDevice.current.systemVersion))

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            phoneDetails.append((key: "App version", value: version))
        }

        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            phoneDetails.append((key: "App build", value: build))
        }

        var footer = "<br/><br/><p><i>"
        phoneDetails.forEach { (arg0) in
            let (key, value) = arg0
            footer.append("<br/>\(key): \(value)")
        }
        footer.append("<br/>")
        footer.append(ConnectionMonitor.shared.state.formattedDisplayItems.joined(separator: "<br/>"))
        footer.append("</i></p>")

        return footer
    }

    private func addAttachments(_ mail: MFMailComposeViewController) throws {
        let archiveURL = try zipDebugFiles()
        let data = try NSData(contentsOfFile: archiveURL.path) as Data
        mail.addAttachmentData(data, mimeType: "application/zip", fileName: archiveURL.lastPathComponent)
    }

    private func zipDebugFiles() throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let archiveName = "\(dateString)-bug-report.zip"

        guard let archiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(archiveName) else {
            TariLogger.error("Failed to create archive URL")
            throw DebugErrors.zipURL
        }

        //ZIP db files only if this is testnet
        //An archive needs to be created first before multipl files can be appended.
        //If this is mainnet then just the current log file gets created and the rest will get appeneded below.
        var sourceURL = URL(fileURLWithPath: TariLib.shared.logFilePath)
        //TODO allow the user to check an option for attaching this
        if TariSettings.shared.isDebug {
            sourceURL = URL(fileURLWithPath: TariLib.shared.databasePath)
        }

        do {
            try FileManager().zipItem(at: sourceURL, to: archiveURL)
        } catch {
            TariLogger.error("Creation of ZIP archive failed with error", error: error)
            throw DebugErrors.createArchive
        }

        //Add log file entries
        guard let archive = Archive(url: archiveURL, accessMode: .update) else {
            TariLogger.error("Failed to access archive")
            throw DebugErrors.zipArchive
        }

        var limit = 5
        try TariLib.shared.allLogFiles.forEach { (logFile) in
            guard limit > 0 else {
                return
            }

            try archive.addEntry(with: logFile.lastPathComponent, relativeTo: logFile.deletingLastPathComponent())

            limit = limit - 1
        }

        return archiveURL
    }

    private func onSendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.setSubject("Tari iOS bug report")
            mail.setToRecipients([TariSettings.shared.bugReportEmail])
            mail.mailComposeDelegate = self

            var message = "<p><b>What happened? (Crash/strange behavior)</b></p><br/>"
            message.append("<p><b>What did you expect to happen?</b></p><br/>")
            message.append(getEmailFooter())

            do {
                try addAttachments(mail)
                mail.setMessageBody(message, isHTML: true)
                present(mail, animated: true)
            } catch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    UserFeedback.shared.error(title: "Sending feedback failed", description: "Failed to add attachment", error: error)
                })
            }
        } else {
            UserFeedback.shared.error(title: "Feedback failed", description: "Apple mail app needs to be setup to be able to send bug report mails")
        }

        TariLogger.info("Feedback shared")
    }

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if error != nil {
            self.dismiss(animated: true, completion: nil)
        }

        switch result {
            case .cancelled:
            break
            case .sent:
            break
            case .failed:
                UserFeedback.shared.error(title: "Error", description: "Failed to send feedback", error: error)
            break
            default:
            break
        }

        controller.dismiss(animated: true, completion: nil)
    }

    override open func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "View logs", style: .default, handler: { (_)in
            self.showTariLibLogs()
        }))

        alert.addAction(UIAlertAction(title: "Report a bug", style: .default, handler: { (_)in
            self.onSendFeedback()
        }))

        alert.addAction(UIAlertAction(title: "View connection status", style: .default, handler: { (_)in
            UserFeedback.shared.showDebugConnectionStatus()
        }))

        if TariSettings.shared.isDebug {
            alert.addAction(UIAlertAction(title: "Delete wallet", style: .destructive, handler: { (_)in
                self.deleteWallet()
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }
}
