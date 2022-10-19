//  SendingTariViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 27/02/2020
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
import Combine

final class SendingTariViewController: UIViewController, TransactionViewControllable {
    
    // MARK: - Properties
    
    var onCompletion: ((WalletTransactionsManager.TransactionError?) -> Void)?
    
    private let mainView = SendingTariView()
    private let model: SendingTariModel
    
    private var cancelables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init(model: SendingTariModel, viewInputModel: SendingTariView.InputModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        mainView.setup(model: viewInputModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        runBackgroundAnimation()
        setupBindings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        mainView.playInitialAnimation()
        model.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: - Setups
    
    private func setupBindings() {
        
        model.$stateModel
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateViews(model: $0) }
            .store(in: &cancelables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.runBackgroundAnimation() }
            .store(in: &cancelables)
    }
    
    func updateViews(model: SendingTariModel.StateModel) {
        self.updateLabels { [weak self] in
            self?.runProgressAnimation(stepIndex: model.stepIndex)
        }
    }
    
    // MARK: - Actions
    
    private func runBackgroundAnimation() {
        mainView.videoBackgroundView.startPlayer()
    }
    
    private func runProgressAnimation(stepIndex: Int) {
        
        guard let state = mainView.progressBar.state(forSection: stepIndex) else { return }
        
        switch state {
        case .disabled, .off:
            updateProgressBar(state: .on, stepIndex: stepIndex)
        case .on:
            handleProgressSectionOnState(stepIndex: stepIndex)
        }
    }
        
    private func handleProgressSectionOnState(stepIndex: Int) {
        
        guard !model.isNextStepAvailable else {
            model.moveToNextStep()
            return
        }
        
        guard let onCompletion = model.onCompletion else {
            updateProgressBar(state: .off, stepIndex: stepIndex)
            return
        }

        switch onCompletion {
        case .success:
            endFlowWithSuccess()
        case let .failure(error):
            endFlow(withError: error)
        }
    }
    
    private func updateProgressBar(state: ProgressBar.State, stepIndex: Int) {
        mainView.progressBar.update(state: state, forSection: stepIndex) { [weak self] in
            self?.runProgressAnimation(stepIndex: stepIndex)
        }
    }
    
    private func updateLabels(completion: @escaping () -> Void) {
        mainView.update(firstText: model.stateModel?.firstText, secondText: model.stateModel?.secondText) {
            completion()
        }
    }
    
    private func endFlowWithSuccess() {
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        mainView.playSuccessAnimation { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        mainView.hideAllComponents(delay: 3.7) { dispatchGroup.leave() }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.onCompletion?(nil)
        }
    }
    
    private func endFlow(withError error: WalletTransactionsManager.TransactionError) {
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        mainView.playFailureAnimation { dispatchGroup.leave() }
        
        dispatchGroup.enter()
        mainView.hideAllComponents(delay: 0.0) { dispatchGroup.leave() }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.onCompletion?(error)
        }
    }
}
