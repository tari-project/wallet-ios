//  LogModel.swift

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

import Foundation

struct LogLineModel: Identifiable, Hashable {
    let id: UUID
    let text: String
}

struct LogFilterModel: Identifiable, Hashable {
    let id: UUID
    let title: String
    let isSelected: Bool
    let filterKey: String
}

final class LogModel {

    // MARK: - View Model

    @Published private(set) var filename: String = ""
    @Published private(set) var logLineModels: [LogLineModel] = []
    @Published private(set) var filterModels: [LogFilterModel]?
    @Published private(set) var isUpdateInProgress: Bool = false
    @Published private(set) var errorMessage: MessageModel?

    // MARK: - Properties

    private let fileURL: URL

    private lazy var updatedFilterModels = [
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.info"), isSelected: true, filterKey: "INFO"),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.warning"), isSelected: true, filterKey: "WARN"),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.error"), isSelected: true, filterKey: "ERROR"),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.debug"), isSelected: true, filterKey: "DEBUG"),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.aurora_general"), isSelected: true, filterKey: filterKey(domain: .general)),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.aurora_connection"), isSelected: true, filterKey: filterKey(domain: .connection)),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.aurora_navigation"), isSelected: true, filterKey: filterKey(domain: .navigation)),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.aurora_ui"), isSelected: true, filterKey: filterKey(domain: .userInterface)),
        LogFilterModel(id: UUID(), title: localized("debug.logs.details.filters.label.aurora_debug"), isSelected: true, filterKey: filterKey(domain: .debug))
    ]

    private var selectedUUIDs: [UUID] = []

    // MARK: - Initialisers

    init(fileURL: URL) {
        self.fileURL = fileURL
        filename = fileURL.lastPathComponent
    }

    // MARK: - Actions

    func refreshData() {
        isUpdateInProgress = true
        DispatchQueue.global().async {
            self.updateVisibleLogLines()
        }
    }

    private func updateVisibleLogLines() {
        do {
            let selectedKeywords = updatedFilterModels
                .filter(\.isSelected)
                .map(\.filterKey)

            logLineModels = try String(contentsOf: fileURL)
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .filter { selectedKeywords.contains(where: $0.contains) }
                .map { LogLineModel(id: UUID(), text: $0) }
        } catch {
            errorMessage = MessageModel(title: localized("error.generic.title"), message: localized("debug.logs.details.error.message.cant_open_file"), type: .error)
        }

        isUpdateInProgress = false
    }

    func generateFilterModels() {
        filterModels = updatedFilterModels
    }

    func applyFilters(selectedUUIDs: Set<UUID>) {
        updatedFilterModels = updatedFilterModels
            .map { LogFilterModel(id: $0.id, title: $0.title, isSelected: selectedUUIDs.contains($0.id), filterKey: $0.filterKey) }
        refreshData()
    }

    // MARK: - Helpers

    private func filterKey(domain: Logger.Domain) -> String {
        LogFormatter.formattedDomainName(domain: domain, includePrefix: true)
    }
}
