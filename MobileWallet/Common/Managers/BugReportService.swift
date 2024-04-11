//  BugReportService.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 28/10/2022
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

import Zip
import Sentry

final class BugReportService {

    private let workingDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("BugReport")
    private let filename = "BugReport.zip"

    // MARK: - Actions

    func send(name: String, email: String, message: String) async throws {
        try clearWorkingDirectory()
        try createWoringDirectory()
        let attachementURL = try await prepareAttachement(zipName: filename)
        sendBugReport(name: name, email: email, message: message, attachementURL: attachementURL)
        try clearWorkingDirectory()
    }

    func prepareLogsURL(name: String) async throws -> URL {
        try clearWorkingDirectory()
        try createWoringDirectory()
        return try await prepareAttachement(zipName: name)
    }

    private func prepareAttachement(zipName: String) async throws -> URL {

        let logsURLs = try Tari.shared.logsURLs.prefix(5)
        let localFileURL = workingDirectory.appendingPathComponent(zipName)

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try Zip.zipFiles(paths: Array(logsURLs), zipFilePath: localFileURL, password: nil, compression: .BestCompression) { progress in
                    guard progress >= 1.0 else { return }
                    continuation.resume(returning: localFileURL)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func clearWorkingDirectory() throws {
        guard FileManager.default.fileExists(atPath: workingDirectory.path) else { return }
        try FileManager.default.removeItem(at: workingDirectory)
    }

    private func createWoringDirectory() throws {
        try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
    }

    private func sendBugReport(name: String, email: String, message: String, attachementURL: URL) {

        let uuid = UUID().uuidString
        let attachement = Attachment(path: attachementURL.path, filename: "\(uuid).zip")

        let eventID = SentrySDK.capture(message: uuid) { scope in
            scope.addAttachment(attachement)
        }

        let userFeedback = UserFeedback(eventId: eventID)
        userFeedback.name = name
        userFeedback.email = email
        userFeedback.comments = message

        SentrySDK.capture(userFeedback: userFeedback)
    }
}
