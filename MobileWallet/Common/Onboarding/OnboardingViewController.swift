//  OnboardingViewController.swift

/*
	Package MobileWallet
	Created by Browncoat on 24/01/2023
	Using Swift 5.0
	Running on macOS 13.0

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

final class OnboardingViewController: UIViewController {

    // MARK: - Properties

    private let mainView = OnboardingView()
    private let pageViewController = PageViewController()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        setupCallbacks()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        pageViewController.controllers
            .compactMap { $0 as? OnboardingPageViewController }
            .forEach {
                $0.contentHeight = mainView.pagerView.frame.minY
                $0.footerHeight = footerHeight()
            }
    }

    // MARK: - Setups

    private func setupPageViewController() {

        pageViewController.controllers = [
            makePageController(index: 0),
            makePageController(index: 1),
            makePageController(index: 2),
            makePageController(index: 3)
        ]

        add(childController: pageViewController, containerView: mainView.contentView)
        mainView.sendSubviewToBack(pageViewController.view)

    }

    private func setupCallbacks() {

        mainView.onNextButtonPress = { [weak self] in
            guard let self else { return }
            let pageIndex = Int(round(self.pageViewController.pageIndex + 1.0))
            self.pageViewController.move(toIndex: pageIndex)
        }

        pageViewController.$pageIndex
            .sink { [weak self] in
                self?.mainView.progress = $0 + 1.0
                self?.mainView.navigationBar.rightButton.isHidden = $0 > 2.0
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers

    private func makePageController(index: Int) -> OnboardingPageViewController {
        let controller = OnboardingPageViewController()
        controller.viewModel = pageViewModel(index: index)
        return controller
    }

    private func pageViewModel(index: Int) -> OnboardingPageView.ViewModel {
        switch index {
        case 0:
            return OnboardingPageView.ViewModel.page1
        case 1:
            return OnboardingPageView.ViewModel.page2
        case 2:
            return OnboardingPageView.ViewModel.page3
        case 3:
            return OnboardingPageView.ViewModel.page4
        default:
            return OnboardingPageView.ViewModel(image: nil, titleComponents: [], messageComponents: [], footerComponents: [], actionButtonTitle: nil, actionButtonCallback: nil)
        }
    }

    private func footerHeight() -> CGFloat {
        OnboardingPageView.ViewModel.calculateFooterHeight(forView: mainView)
    }
}
