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

    private static var debugMenuAlert: UIAlertController?

    private func showTariLibLogs() {
        if navigationController?.topViewController is DebugLogsTableViewController {
            return
        }
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

        phoneDetails.append((key: "App environment", value: "\(TariSettings.shared.environment)"))

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

        guard let archiveURL = FileManager.default.documentDirectory()?.appendingPathComponent(archiveName) else {
            TariLogger.error("Failed to create archive URL")
            throw DebugErrors.zipURL
        }

        //ZIP db files only if this is debug
        //An archive needs to be created first before multipl files can be appended.
        //If this is mainnet then just the current log file gets created and the rest will get appeneded below.
        var sourceURL = URL(fileURLWithPath: TariLib.shared.logFilePath)
        //Only allow attaching DB files in debugn and testflight
        if TariSettings.shared.environment != .production {
            sourceURL = TariLib.shared.databaseDirectory
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

    func onSendFeedback() {
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
            shareFeedback()
        }

        TariLogger.info("Feedback shared")
    }

    private func shareFeedback() {
        do {
            let message = "Tari iOS bug report \(TariSettings.shared.bugReportEmail)"
            let archiveURL = try zipDebugFiles()
              let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [message, archiveURL], applicationActivities: nil)

              activityViewController.popoverPresentationController?.sourceView = self.view
              activityViewController.excludedActivityTypes = [
                .postToFacebook,
                .postToTwitter,
                .postToWeibo,
                .print,
                .copyToPasteboard,
                .assignToContact,
                .saveToCameraRoll,
                .addToReadingList,
                .postToFlickr,
                .postToVimeo,
                .postToTencentWeibo,
                .airDrop,
                .openInIBooks,
                .markupAsPDF
              ]

            self.present(activityViewController, animated: true, completion: nil)
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                UserFeedback.shared.error(title: "Sending feedback failed", description: "Failed to add attachment", error: error)
            })
        }
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
        guard
            UIViewController.debugMenuAlert == nil,
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        else { return }

        let title = "\(TariSettings.shared.network.networkDisplayName.uppercased()) v\(version) (\(build))"

        UIViewController.debugMenuAlert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        guard let alert = UIViewController.debugMenuAlert else {
            return
        }

        alert.addAction(
            UIAlertAction(
                title: "View logs",
                style: .default,
                handler: {
                    (_) in
                    UIViewController.debugMenuAlert = nil
                    self.showTariLibLogs()
            }))

        alert.addAction(
            UIAlertAction(
                title: "Report a bug",
                style: .default,
                handler: {
                    (_) in
                    UIViewController.debugMenuAlert = nil
                    self.onSendFeedback()
            }))

        alert.addAction(
            UIAlertAction(
                title: "View connection status",
                style: .default,
                handler: {
                    (_) in
                    UIViewController.debugMenuAlert = nil
                    UserFeedback.shared.showDebugConnectionStatus()
            }))

        if TariSettings.shared.environment == .debug {
            alert.addAction(
                UIAlertAction(
                    title: "Delete wallet",
                    style: .destructive,
                    handler: {
                        (_) in
                        UIViewController.debugMenuAlert = nil
                        self.deleteWallet()
                }))
        }

        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: {
                        (_) in
                        UIViewController.debugMenuAlert = nil
            }))

        present(alert, animated: true, completion: nil)
    }
}
