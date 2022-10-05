//  VerifySeedWordsModel.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/02/2022
	Using Swift 5.0
	Running on macOS 12.1

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

import Combine

final class VerifySeedWordsModel {
    
    struct InputData {
        let seedWords: [String]
    }
    
    // MARK: - View Model
    
    @Published var selectedTokenModels: [SeedWordModel] = []
    @Published var availableTokenModels: [SeedWordModel] = []
    @Published var isSelectedTokenTipVisible: Bool = true
    @Published var isErrorVisible: Bool = false
    @Published var isSuccessVisible: Bool = false
    @Published var isContinueButtonEnabled: Bool = false
    @Published var shouldEndFlow: Bool = false
    
    // MARK: - Properties
    
    private let inputData: InputData
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init(inputData: InputData) {
        self.inputData = inputData
        setupCallbacks()
    }
    
    func fetchData() {
        availableTokenModels = inputData.seedWords
            .sorted()
            .map { SeedWordModel(id: UUID(), title: $0, state: .valid, visualTrait: .none) }
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        
        $selectedTokenModels
            .map(\.isEmpty)
            .assign(to: \.isSelectedTokenTipVisible, on: self)
            .store(in: &cancellables)
        
        $selectedTokenModels
            .sink { [weak self] in self?.handle(selectedTokens: $0) }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func selectToken(index: Int) {
        guard index < availableTokenModels.count else { return }
        let model = availableTokenModels[index]
        availableTokenModels[index] = model.update(visualTrait: .hidden)
        selectedTokenModels.append(model.update(visualTrait: .deleteIcon))
    }
    
    func removeSelectedToken(index: Int) {
        guard index < selectedTokenModels.count else { return }
        let model = selectedTokenModels.remove(at: index)
        guard let availableTokenIndex = availableTokenModels.firstIndex(where: { $0.id == model.id }) else { return }
        availableTokenModels[availableTokenIndex] = availableTokenModels[availableTokenIndex].update(visualTrait: .none)
    }
    
    func continueFlowRequest() {
        TariSettings.shared.walletSettings.hasVerifiedSeedPhrase = true
        shouldEndFlow = true
    }
    
    private func handle(selectedTokens: [SeedWordModel]) {
        
        guard selectedTokens.count == inputData.seedWords.count else {
            isErrorVisible = false
            isSuccessVisible = false
            isContinueButtonEnabled = false
            return
        }
        
        let isValidCollection = selectedTokens.map({ $0.title }) == inputData.seedWords
        
        isErrorVisible = !isValidCollection
        isSuccessVisible = isValidCollection
        isContinueButtonEnabled = isValidCollection
    }
}

private extension SeedWordModel {
    
    func update(visualTrait: VisualTrait) -> Self {
        Self(id: id, title: title, state: state, visualTrait: visualTrait)
    }
}
