//  EmailFeedbackHandler.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 19/10/2022
	Using Swift 5.0
	Running on macOS 12.6

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

import MessageUI
import ZIPFoundation

final class EmailFeedbackHandler: NSObject {
    
    private enum DebugErrors: Error {
        case zipURL
        case createArchive
        case zipArchive
        case zipDBfiles
    }
    
    static let shared = EmailFeedbackHandler()
    
    private override init() {}
    
    func show(presenter: UIViewController) {
        
        guard MFMailComposeViewController.canSendMail() else {
            shareFeedback(presenter: presenter)
            return
        }
        
        let composerController = MFMailComposeViewController()
        composerController.setSubject("Tari iOS bug report")
        composerController.setToRecipients([TariSettings.shared.bugReportEmail])
        composerController.mailComposeDelegate = self
        
        var message = """
            <p><b>What happened? (Crash/strange behavior)</b></p><br/>
            <p><b>What did you expect to happen?</b></p><br/>
        """
        
        message.append(getEmailFooter())
        
        do {
            try addAttachments(composerController)
            composerController.setMessageBody(message, isHTML: true)
            presenter.present(composerController, animated: true)
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                PopUpPresenter.show(message: MessageModel(title: "Sending feedback failed", message: "Failed to add attachment", type: .error))
            }
        }
    }
    
    private func shareFeedback(presenter: UIViewController) {
        do {
            let message = "Tari iOS bug report \(TariSettings.shared.bugReportEmail)"
            let archiveURL = try zipDebugFiles()
              let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [message, archiveURL], applicationActivities: nil)

              activityViewController.popoverPresentationController?.sourceView = presenter.view
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

            presenter.present(activityViewController, animated: true, completion: nil)
        } catch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                PopUpPresenter.show(message: MessageModel(title: "Sending feedback failed", message: "Failed to add attachment", type: .error))
            })
        }
    }
    
    private func zipDebugFiles() throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let archiveName = "\(dateString)-bug-report.zip"

        guard let archiveURL = FileManager.default.documentDirectory()?.appendingPathComponent(archiveName) else {
            Logger.log(message: "Failed to create archive URL", domain: .general, level: .error)
            throw DebugErrors.zipURL
        }

        // ZIP db files only if this is debug
        // An archive needs to be created first before multipl files can be appended.
        // If this is mainnet then just the current log file gets created and the rest will get appended below.
        var sourceURL = URL(fileURLWithPath: Tari.shared.logFilePath)
        // Only allow attaching DB files in debug and testflight
        if TariSettings.shared.environment != .production {
            sourceURL = Tari.shared.connectedDatabaseDirectory
        }

        do {
            try FileManager().zipItem(at: sourceURL, to: archiveURL)
        } catch {
            Logger.log(message: "Creation of ZIP archive failed with error: \(error.localizedDescription)", domain: .general, level: .error)
            throw DebugErrors.createArchive
        }

        // Add log file entries
        guard let archive = Archive(url: archiveURL, accessMode: .update) else {
            Logger.log(message: "Failed to access archive", domain: .general, level: .error)
            throw DebugErrors.zipArchive
        }

        var limit = 5
        try Tari.shared.logsURLs.forEach { (logFile) in
            guard limit > 0 else {
                return
            }

            try archive.addEntry(with: logFile.lastPathComponent, relativeTo: logFile.deletingLastPathComponent())

            limit = limit - 1
        }

        return archiveURL
    }
    
    private func getEmailFooter() -> String {
        var phoneDetails: [(key: String, value: String)] = []

        phoneDetails.append((key: "Network", value: NetworkManager.shared.selectedNetwork.name))
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
        footer.append(Tari.shared.connectionMonitor.formattedDisplayItems.joined(separator: "<br/>"))
        footer.append("</i></p>")

        return footer
    }
    
    private func addAttachments(_ mail: MFMailComposeViewController) throws {
        let archiveURL = try zipDebugFiles()
        let data = try NSData(contentsOfFile: archiveURL.path) as Data
        mail.addAttachmentData(data, mimeType: "application/zip", fileName: archiveURL.lastPathComponent)
    }
}

extension EmailFeedbackHandler: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if error == nil, result == .failed {
            PopUpPresenter.show(message: MessageModel(title: "Error", message: "Failed to send feedback", type: .error))
        }
        controller.dismiss(animated: true, completion: nil)
    }
}

