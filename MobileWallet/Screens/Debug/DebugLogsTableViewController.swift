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

class DebugLogsTableViewController: UITableViewController {
    struct DebugLogColors {
        var backgroundColor: UIColor = .black
        var lineTextColor: UIColor = .green
        var font = UIFont.systemFont(ofSize: 12, weight: .light)
    }

    let theme = DebugLogColors()

    let CELL_IDENTIFIER = "logLineCell"

    var logLines: [String] = []
    var currentLogFile: URL? {
        didSet {
            if currentLogFile != nil {
                loadLogs()
            }
            tableView.reloadData()
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
        view.backgroundColor = theme.backgroundColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none

        navigationController?.navigationBar.barTintColor = theme.backgroundColor
        navigationController?.navigationBar.isTranslucent = false
        if let currentLogFile = currentLogFile {
            title = currentLogFile.lastPathComponent
        } else {
            title = "Debug Logs"
        }
    }

    private func loadLogs() {
        guard let currentLogFile = currentLogFile else {
            return
        }

        do {
            let data = try String(contentsOf: currentLogFile, encoding: .utf8)
            logLines = data.components(separatedBy: .newlines)
        } catch {
            logLines = ["Failed to load log file: \(currentLogFile.path)"]
        }
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

        cell.backgroundColor = theme.backgroundColor
        cell.textLabel?.font = theme.font
        cell.textLabel?.textColor = theme.lineTextColor

        if currentLogFile != nil {
            cell.textLabel?.text = logLines[indexPath.row]
            cell.textLabel?.numberOfLines = 10
        } else {
            cell.textLabel?.text = TariLib.shared.allLogFiles[indexPath.row].lastPathComponent
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
