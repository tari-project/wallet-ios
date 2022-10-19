//  RestoreWalletFromSeedsModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 12/07/2021
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

import Combine

struct TokenViewModel: Identifiable, Hashable {
    let id: UUID
    let title: String
}

final class RestoreWalletFromSeedsModel {

    final class ViewModel {
        @Published var seedWordModels: [SeedWordModel] = []
        @Published var updatedInputText: String = ""
        @Published var error: MessageModel?
        @Published var isConfimationEnabled: Bool = false
        @Published var isEmptyWalletCreated: Bool = false
        @Published var isAutocompletionAvailable: Bool = false
        @Published var autocompletionTokens: [TokenViewModel] = []
        @Published var autocompletionMessage: String?
    }

    // MARK: - Properties

    @Published var inputText: String = ""
    
    let viewModel: ViewModel = ViewModel()
    
    private let editingModel = SeedWordModel(id: UUID(), title: "", state: .editing, visualTrait: .none)
    
    private var availableAutocompletionTokens: [TokenViewModel] = [] {
        didSet { viewModel.isAutocompletionAvailable = !availableAutocompletionTokens.isEmpty }
    }
    private var cancelables = Set<AnyCancellable>()
    
    // MARK: - Initalizers

    init() {
        setupFeedbacks()
        fetchAvailableSeedWords()
    }

    // MARK: - Setups

    private func setupFeedbacks() {
        
        viewModel.$seedWordModels
            .map { $0.contains { $0.state != .editing } }
            .assign(to: \.isConfimationEnabled, on: viewModel)
            .store(in: &cancelables)
        
        $inputText
            .map { [unowned self] inputText in self.availableAutocompletionTokens.filter { $0.title.lowercased().hasPrefix(inputText.lowercased()) }}
            .map { [unowned self] in $0 != self.availableAutocompletionTokens ? $0 : [] }
            .assign(to: \.autocompletionTokens, on: viewModel)
            .store(in: &cancelables)
        
        $inputText
            .sink { [unowned self] in self.handle(inputText: $0) }
            .store(in: &cancelables)
        
        Publishers.CombineLatest($inputText, viewModel.$autocompletionTokens)
            .map {
                switch ($0.isEmpty, $1.isEmpty) {
                case (true, true):
                    return localized("restore_from_seed_words.autocompletion_toolbar.label.start_typing")
                case (false, true):
                    return localized("restore_from_seed_words.autocompletion_toolbar.label.no_suggestions")
                default:
                    return nil
                }
            }
            .assign(to: \.autocompletionMessage, on: viewModel)
            .store(in: &cancelables)
    }

    // MARK: - Actions
    
    func start() {
        guard viewModel.seedWordModels.isEmpty else { return }
        viewModel.seedWordModels = [editingModel]
    }

    func startRestoringWallet() {
        
        let seedWords = viewModel.seedWordModels
            .filter { $0.state != .editing }
            .map { $0.title }
        
        do {
            try Tari.shared.restoreWallet(seedWords: seedWords)
            viewModel.isEmptyWalletCreated = true
        } catch let error as SeedWords.InternalError {
            handle(seedWordsError: error)
        } catch let error as WalletError {
            handle(walletError: error)
        } catch {
            handleUnknownError()
        }
    }
    
    func removeSeedWord(row: Int) {
        guard viewModel.seedWordModels.count > row else { return }
        viewModel.seedWordModels.remove(at: row)
    }
    
    func handleRemovingFirstCharacter(existingText: String) {
        guard viewModel.seedWordModels.contains(where: { $0.state != .editing }) else { return }
        let lastTokenIndex = viewModel.seedWordModels.count - 2
        let lastToken = viewModel.seedWordModels.remove(at: lastTokenIndex)
        viewModel.updatedInputText = lastToken.title + existingText
    }
    
    func handleEndEditing() {
        guard !inputText.isEmpty else { return }
        let state = state(seedWord: inputText)
        appendModelsBeforeEditingModel(models: [SeedWordModel(id: UUID(), title: inputText, state: state, visualTrait: .deleteIcon)])
        viewModel.updatedInputText = ""
    }
    
    private func fetchAvailableSeedWords() {
        let seedWords = (try? Tari.shared.recovery.allSeedWords(forLanguage: .english)) ?? []
        availableAutocompletionTokens = seedWords.map { TokenViewModel(id: UUID(), title: $0) }
    }
    
    private func appendModelsBeforeEditingModel(models: [SeedWordModel]) {
        let index = viewModel.seedWordModels.count - 1
        viewModel.seedWordModels.insert(contentsOf: models, at: index)
    }

    // MARK: - Handlers
    
    private func handle(inputText: String) {
        
        var tokens = inputText.tokenize()
        guard tokens.count > 1 else { return }
        let lastToken = tokens.removeLast()
        let models = tokens
            .map { $0.lowercased() }
            .map { SeedWordModel(id: UUID(), title: $0, state: state(seedWord: $0), visualTrait: .deleteIcon) }
        
        appendModelsBeforeEditingModel(models: models)
        viewModel.updatedInputText = lastToken
    }

    private func handle(seedWordsError: SeedWords.InternalError) {
        viewModel.error = ErrorMessageManager.errorModel(forError: seedWordsError)
    }

    private func handle(walletError: WalletError) {
        
        let message = ErrorMessageManager.errorMessage(forError: walletError)
        
        viewModel.error = MessageModel(
            title: localized("restore_from_seed_words.error.title"),
            message: message,
            type: .error
        )
    }

    private func handleUnknownError() {
        viewModel.error = MessageModel(
            title: localized("restore_from_seed_words.error.title"),
            message: localized("restore_from_seed_words.error.description.unknown_error"),
            type: .error
        )
    }
    
    // MARK: - Helpers
    
    private func state(seedWord: String) -> SeedWordModel.State {
        availableAutocompletionTokens.contains { $0.title == seedWord } ? .valid : .invalid
    }
}
