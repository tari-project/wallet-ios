//  DebugLogsTableViewController.swift

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
import SwiftEntryKit

class DebugLogsTableViewController: UITableViewController {
    struct DebugLogTheme {
        var backgroundColor: UIColor = .black
        var lineTextColor: UIColor = .green
        var font = UIFont.systemFont(ofSize: 12, weight: .light)
        var popupBackground = UIColor.systemGray6
    }

    private static let theme = DebugLogTheme()

    private let debugLevels: [String] = ["INFO", "WARN", "ERROR", "DEBUG"]
    private var debugLevelsOn: [String] = ["INFO", "WARN", "ERROR"]

    private var filterAttributes: EKAttributes {
        var attributes = EKAttributes.centerFloat
        attributes.screenBackground = .color(color: EKColor(Theme.shared.colors.feedbackPopupBackground!))
        attributes.entryBackground = .clear
        attributes.positionConstraints.size = .init(width: .intrinsic, height: .intrinsic)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .forward
        attributes.displayDuration = .infinity

        return attributes
    }

    public let filterView = UIView()

    let CELL_IDENTIFIER = "logLineCell"

    var logLines: [String] = []
    var currentLogFile: URL? {
        didSet {
            if currentLogFile != nil {
                loadLogs()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        view.backgroundColor = DebugLogsTableViewController.theme.backgroundColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none

        if let navBar = navigationController?.navigationBar {
            navBar.tintColor = DebugLogsTableViewController.theme.lineTextColor

            navBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: DebugLogsTableViewController.theme.lineTextColor,
                NSAttributedString.Key.font: DebugLogsTableViewController.theme.font.withSize(16)
            ]

            navBar.setBackgroundImage(UIImage(color: DebugLogsTableViewController.theme.backgroundColor), for: .default)
            navBar.isTranslucent = true

            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(self.onClose))
        }

        if let currentLogFile = currentLogFile {
            title = currentLogFile.lastPathComponent
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(self.onShowFilterOptions))
            setupFilterDialog()
        } else {
            title = "Debug Logs"
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //If it's a log file scroll to the bottom to view newest lines
        guard logLines.count > 0 else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(row: self.logLines.count-1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    @objc func onClose() {
        navigationController?.view.layer.add(Theme.shared.transitions.pushUpClose, forKey: kCATransition)
        navigationController?.popViewController(animated: false)
    }

    @objc func onShowFilterOptions() {
        SwiftEntryKit.display(entry: filterView, using: filterAttributes)
    }

    @objc func onFilterChange(filterSwitch: UISwitch) {
        let level = debugLevels[filterSwitch.tag]

        if filterSwitch.isOn {
            debugLevelsOn.append(level)
        } else {
            if let index = debugLevelsOn.firstIndex(of: level) {
                debugLevelsOn.remove(at: index)
            }
        }

        loadLogs()
    }

    private func setupFilterDialog() {
        filterView.backgroundColor = DebugLogsTableViewController.theme.popupBackground
        filterView.layer.cornerRadius = 10
        filterView.heightAnchor.constraint(greaterThanOrEqualToConstant: 250).isActive = true
        filterView.widthAnchor.constraint(equalToConstant: 200).isActive = true

        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .equalCentering
        sv.translatesAutoresizingMaskIntoConstraints = false
        filterView.addSubview(sv)
        let padding: CGFloat = 20
        sv.topAnchor.constraint(equalTo: filterView.topAnchor, constant: padding).isActive = true
        sv.bottomAnchor.constraint(equalTo: filterView.bottomAnchor, constant: -padding).isActive = true
        sv.centerXAnchor.constraint(equalTo: filterView.centerXAnchor).isActive = true
        sv.leadingAnchor.constraint(equalTo: filterView.leadingAnchor, constant: padding).isActive = true
        sv.trailingAnchor.constraint(equalTo: filterView.trailingAnchor, constant: -padding).isActive = true

        for level in debugLevels {
            let row = UIStackView()

            row.axis = .horizontal
            row.distribution = .equalCentering

            let logLevelSwitch = UISwitch()
            logLevelSwitch.addTarget(self, action: #selector(onFilterChange(filterSwitch:)), for: .valueChanged)

            logLevelSwitch.translatesAutoresizingMaskIntoConstraints = false
            row.addArrangedSubview(logLevelSwitch)
            logLevelSwitch.tag = debugLevels.firstIndex(of: level) ?? 0
            logLevelSwitch.isOn = debugLevelsOn.firstIndex(of: level) != nil

            let logLable = UILabel()
            logLable.text = level
            logLable.translatesAutoresizingMaskIntoConstraints = false
            row.addArrangedSubview(logLable)

            sv.addArrangedSubview(row)
        }
    }

    private func loadLogs() {
        guard let currentLogFile = currentLogFile else {
            return
        }

        var allLines: [String] = []
        do {
            let data = try String(contentsOf: currentLogFile, encoding: .utf8)
            allLines = data.components(separatedBy: .newlines)
        } catch {
            allLines = ["Failed to load log file: \(currentLogFile.path)"]
        }

        logLines = allLines.filter { debugLevelsOn.contains(where: $0.contains) }
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentLogFile != nil ? logLines.count : TariLib.shared.allLogFiles.count
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return currentLogFile == nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath)

        cell.backgroundColor = DebugLogsTableViewController.theme.backgroundColor
        cell.textLabel?.font = DebugLogsTableViewController.theme.font
        cell.textLabel?.textColor = DebugLogsTableViewController.theme.lineTextColor

        if currentLogFile != nil {
            cell.textLabel?.text = logLines[indexPath.row]
            cell.textLabel?.numberOfLines = 10
        } else {
            let url = TariLib.shared.allLogFiles[indexPath.row]
            let filename = url.lastPathComponent

            var labelText = TariLib.shared.logFilePath.contains(filename) ? "\(filename) (current)" : filename

            do {
                let attr = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attr[FileAttributeKey.size] as! UInt64

                let formattedSize = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)

                labelText = "\(labelText) - \(formattedSize)"
            } catch {
                TariLogger.error("Failed to get log file size", error: error)
            }

            cell.textLabel?.text = labelText
            cell.textLabel?.numberOfLines = 0
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard currentLogFile == nil else {
            return
        }

        let logsVC = DebugLogsTableViewController()
        logsVC.currentLogFile = TariLib.shared.allLogFiles[indexPath.row]
        navigationController?.pushViewController(logsVC, animated: true)
    }
}
