//  LogsListModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/10/2022
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

final class LogsListModel {

    enum Action {
        case share(url: URL)
    }

    // MARK: - View Model

    @Published private(set) var logTitles: [String] = []
    @Published private(set) var selectedRowFileURL: URL?
    @Published private(set) var action: Action?
    @Published private(set) var errorMessage: MessageModel?

    // MARK: - Properties

    private var logsURLs: [URL] = []
    private let bugReportService = BugReportService()

    // MARK: - Actions

    func refreshLogsList() {
        do {
            logsURLs = try Tari.shared.logsURLs
            logTitles = try logsURLs.map { [unowned self] in try self.title(fileURL: $0) }
        } catch {
            errorMessage = MessageModel(title: localized("error.generic.title"), message: localized("debug.logs.list.error.message.unable_to_load"), type: .error)
        }
    }

    func select(row: Int) {
        selectedRowFileURL = logsURLs[row]
    }

    func requestLogsFile() {
        Task {
            do {
                let url = try await bugReportService.prepareLogsURL(name: "logs.zip")
                action = .share(url: url)
            } catch {
                errorMessage = ErrorMessageManager.errorModel(forError: error)
            }
        }
    }

    func removeTempFiles() {
        try? bugReportService.clearWorkingDirectory()
    }

    // MARK: - Handlers

    private func title(fileURL: URL) throws -> String {

        let filename = fileURL.lastPathComponent
        let fileAttibutes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        var formattedFileSize: String?

        if let fileSize = fileAttibutes[.size] as? Int64 {
            formattedFileSize = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }

        return [filename, formattedFileSize]
            .compactMap { $0 }
            .joined(separator: " - ")
    }
}
