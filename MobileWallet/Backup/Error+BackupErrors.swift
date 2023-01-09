//  Error+BackupErrors.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 15/11/2022
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

extension DropboxBackupError {

    var message: String? {
        switch self {
        case .unableToCreateTempFolder:
            return localized("error.dropbox_backup.unable_to_create_temp_folder")
        case .uploadFailed:
            return localized("error.dropbox_backup.upload_failed")
        case .downloadFailed:
            return localized("error.dropbox_backup.download_failed")
        case .deleteFailed:
            return localized("error.dropbox_backup.delete_failed")
        case .backupPasswordRequired:
            return nil
        case .authenticationCancelledByUser:
            return nil
        case .authenticationFailed:
            return localized("error.dropbox_backup.auth_failed")
        case .noBackupToRestore:
            return localized("error.dropbox_backup.no_backup")
        case .unknown:
            return localized("error.dropbox_backup.unknown")
        }
    }
}

extension ICloudBackupService.ICloudBackupError {

    var message: String {
        switch self {
        case .noUbiquityContainer:
            return localized("iCloud_backup.error.container_not_found")
        case .unableToCreateBackup:
            return localized("iCloud_backup.error.unable_create_backup_file")
        case .unableToCreateFolderStructure:
            return localized("iCloud_backup.error.unable_create_backup_folder")
        case .unableToDeleteFile:
            return localized("iCloud_backup.error.unable_to_delete_backup")
        case .unableToCopyFile:
            return localized("iCloud_backup.error.unable_to_copy_file")
        case .unableToDownloadBackup, .unableToSaveBackup:
            return localized("iCloud_backup.error.title.restore_wallet")
        }
    }
}
