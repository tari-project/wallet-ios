//  StorageCleanup.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/23
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

import Foundation

private func totalBytes(files: [URL]) -> UInt64 {
    var total: UInt64 = 0
    files.forEach { (file) in
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: file.path)
            if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                total += fileSize
            }
        } catch {
            Logger.log(message: "Failed to get log file size: \(error.localizedDescription)", domain: .general, level: .error)
        }
    }

    return total
}

private func bugReportZipFilesCleanup() {
    let maximumHours: Double = 24
    let minimumDate = Date().addingTimeInterval(-maximumHours*60*60)
    func meetsRequirement(date: Date) -> Bool { return date < minimumDate }
    func meetsRequirement(name: String) -> Bool { return name.hasSuffix("bug-report.zip") }

    do {
        let manager = FileManager.default
        let documentDirUrl = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        if manager.changeCurrentDirectoryPath(documentDirUrl.path) {
            for file in try manager.contentsOfDirectory(atPath: ".") {
                let creationDate = try manager.attributesOfItem(atPath: file)[FileAttributeKey.creationDate] as! Date
                if meetsRequirement(name: file) && meetsRequirement(date: creationDate) {
                    try manager.removeItem(atPath: file)
                }
            }
        }
    } catch {
        Logger.log(message: "Cannot cleanup the old zip files from bug reports files: \(error.localizedDescription)", domain: .general, level: .error)
    }
}

func backgroundStorageCleanup() {
    DispatchQueue.global().async {
        bugReportZipFilesCleanup()
    }
}
