//  YatCacheManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 25/10/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class YatCacheManager {

    struct FileData {
        let url: URL
        let identifier: FileIdentifier
    }

    enum FileIdentifier: String {
        case verticalVideo = "vert"
        case normalVideo = ""

        init(identifier: String) {
            self = Self(rawValue: identifier) ?? .normalVideo
        }
    }

    // MARK: - Properties

    private var cacheURL: URL? { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("YatVisualisations", isDirectory: true) }

    // MARK: - Actions

    func fetchFileData(name: String) -> FileData? {

        guard let cacheURL = cacheURL, let requestedFileComponents = name.components,
              let fileURL = try? FileManager.default.contentsOfDirectory(atURL: cacheURL, sortedBy: .created).first(where: { $0.lastPathComponent.hasPrefix(requestedFileComponents.assetName) }),
              let cachedFileComponents = fileURL.absoluteString.components else {
                  return nil
              }

        if requestedFileComponents.hash != cachedFileComponents.hash {
            return nil
        }

        if requestedFileComponents.identifier == .verticalVideo, cachedFileComponents.identifier == .normalVideo {
            return nil
        }

        return FileData(url: fileURL, identifier: cachedFileComponents.identifier)
    }

    func save(data: Data, name: String) -> FileData? {

        guard let cacheURL = cacheURL, let components = name.components else { return nil }
        createDirectoryIfNeeded()

        do {
            try removeObsoleteData(prefix: components.assetName)
            let fileURL = cacheURL.appendingPathComponent(name)
            try data.write(to: fileURL)
            return FileData(url: fileURL, identifier: components.identifier)
        } catch {
            Logger.log(message: "Unable to cache Yat Visualisation: \(error.localizedDescription)", domain: .general, level: .error)
            return nil
        }
    }

    private func createDirectoryIfNeeded() {
        guard let cacheURL = cacheURL, !FileManager.default.fileExists(atPath: cacheURL.path) else { return }
        try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }

    private func removeObsoleteData(prefix: String) throws {
        guard let cacheURL = cacheURL else { return }
        let allFiles = try FileManager.default.contentsOfDirectory(atURL: cacheURL, sortedBy: .modified)
        guard let obsoleteFilePath = allFiles.first(where: { $0.lastPathComponent.hasPrefix(prefix) }) else { return }
        try FileManager.default.removeItem(at: obsoleteFilePath)
    }
}

private extension String {

    struct Components {
        let assetName: String
        let hash: String
        let identifier: YatCacheManager.FileIdentifier
        let fileExtension: String
    }

    var components: Components? {
        var elements = split(separator: "-")
        guard elements.count >= 2 else { return nil }
        let lastElement = elements.removeLast()
        var trailingElements = lastElement.split(separator: ".")
        guard trailingElements.count >= 2 else { return nil }
        let assetName = elements.joined(separator: "-")
        let fileExtension = trailingElements.removeLast()
        var rawIdentifier: String = ""

        if trailingElements.count == 2 {
            rawIdentifier = String(trailingElements.removeLast())
        }

        let hash = trailingElements.joined(separator: ".")
        let identifier = YatCacheManager.FileIdentifier(identifier: rawIdentifier)

        return Components(assetName: assetName, hash: hash, identifier: identifier, fileExtension: String(fileExtension))
    }
}
