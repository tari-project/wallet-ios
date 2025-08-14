//  ICloudDocsUploadService.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 09/11/2022
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
import Combine

final class ICloudDocsUploadService {

    enum Status {
        case idle
        case inProgress(progress: Double)
        case finished
    }

    // MARK: - Properties

    @Published private(set) var status: Status = .idle

    private let metadataQuery: ICloudBackupMetadataQuery
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(filenamePrefix: String) {
        metadataQuery = ICloudBackupMetadataQuery(filenamePrefix: filenamePrefix)
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        Publishers.Merge(
            NotificationCenter.default.publisher(for: .NSMetadataQueryDidStartGathering, object: metadataQuery),
            NotificationCenter.default.publisher(for: .NSMetadataQueryDidUpdate, object: metadataQuery)
        )
        .compactMap { $0.object as? NSMetadataQuery }
        .sink { [weak self] in self?.handle(query: $0) }
        .store(in: &cancellables)
    }

    // MARK: - Actions

    func uploadBackup() {
        listenToUpdates()
    }

    private func listenToUpdates() {
        metadataQuery.operationQueue?.addOperation { [weak self] in
            self?.metadataQuery.start()
            self?.metadataQuery.enableUpdates()
        }
    }

    private func stopListeningToUpdates() {
        metadataQuery.operationQueue?.addOperation { [weak self] in
            self?.metadataQuery.stop()
            self?.metadataQuery.disableUpdates()
        }
    }

    // MARK: - Handlers

    private func handle(query: NSMetadataQuery) {

        guard !query.results.isEmpty else { return }

        let item = query.results
            .compactMap { $0 as? NSMetadataItem }
            .filter {
                guard let url = $0.value(forAttribute: NSMetadataItemURLKey) as? URL else { return false }
                return url.lastPathComponent.hasPrefix(BackupFilesManager.encryptedFileName)
            }
            .last

        guard let item, let progress = item.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as? Int, let isUploaded = item.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? Bool else { return }

        if progress > 0 {
            status = .inProgress(progress: Double(progress) / 100.0)
        }

        if isUploaded {
            status = .finished
            stopListeningToUpdates()
        }
    }
}
