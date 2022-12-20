//  WebBrowserViewController.swift

/*
    Package MobileWallet
    Created by S.Shovkoplyas on 20.05.2020
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

import WebKit
import TariCommon

class WebBrowserViewController: DynamicThemeViewController {
    private enum UniversalLinkAppPrefix: String, CaseIterable {
        case telegram = "https://t.me"
    }

    private let webView = WKWebView()
    
    @View private var navigationBar: NavigationBar = {
        let view = NavigationBar()
        return view
    }()
    
    private let navigationPanel = UIView()
    private let backButton = UIButton()
    private let forwardButton = UIButton()
    
    @View private var grabber: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        return view
    }()

    private var lastContentOffset: CGFloat = 0
    private var navigationPanelHeightConstraint: NSLayoutConstraint?
    private var scrollDirection: ScrollDirection = .none

    var url: URL? {
        didSet { openURL() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateButtons()
        hideNavigationPanel()
    }

    private func openURL() {
        guard let url = url else { return }
        webView.load(URLRequest(url: url))
    }

    private func showNavigationPanel() {
        navigationPanelHeightConstraint?.constant = 56.0
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    private func hideNavigationPanel() {
        navigationPanelHeightConstraint?.constant = 0
        UIView.animate(withDuration: CATransaction.animationDuration()) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        
        view.backgroundColor = theme.backgrounds.primary
        webView.backgroundColor = theme.backgrounds.secondary
        backButton.tintColor = theme.icons.default
        forwardButton.tintColor = theme.icons.default
        grabber.backgroundColor = theme.icons.inactive
    }
    
    // MARK: - Actions
    
    private func showShareDialog() {
        guard let currentUrl = webView.url else { return }
        let activityViewController = UIActivityViewController(activityItems: [currentUrl], applicationActivities: nil)

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popoverController.sourceView = self.view
            popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }

        present(activityViewController, animated: true)
    }
}

// MARK: - Actions
extension WebBrowserViewController {

    @objc private func backAction() {
        webView.goBack()
    }

    @objc private func forwardAction() {
        webView.goForward()
    }
}

extension WebBrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationBar.title = webView.title
        updateButtons()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if UniversalLinkAppPrefix.allCases.first(where: { prefix -> Bool in
                return url.absoluteString.hasPrefix(prefix.rawValue)
            }) != nil {
                openCustomApp(url: url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    private func openCustomApp(url: URL) {
        let application = UIApplication.shared
        if application.canOpenURL(url) {
            application.open(url, options: [:], completionHandler: nil)
        }
    }

    private func updateButtons() {
        forwardButton.isEnabled = webView.canGoForward
        backButton.isEnabled = webView.canGoBack
    }
}

// MARK: - Setup views
extension WebBrowserViewController {

    private func setupViews() {
        setupGrabber()
        setupNavigationBar()
        setupBottomNavigationPanel()
        setupWebView()
    }
    
    private func setupNavigationBar() {
        
        view.addSubview(navigationBar)
        
        navigationBar.backButtonType = modalPresentationStyle == .popover ? .close : .none
        navigationBar.rightButton.setImage(Theme.shared.images.share, for: .normal)
        navigationBar.onRightButtonAction = { [weak self] in self?.showShareDialog() }
        
        let constraints = [
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 32.0),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }

    private func setupBottomNavigationPanel() {
        navigationPanel.backgroundColor = .clear
        navigationPanel.clipsToBounds = true

        view.addSubview(navigationPanel)
        navigationPanel.translatesAutoresizingMaskIntoConstraints = false
        navigationPanel.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        navigationPanelHeightConstraint = navigationPanel.heightAnchor.constraint(equalToConstant: 56.0)
        navigationPanelHeightConstraint?.isActive = true
        navigationPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        navigationPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        backButton.setImage(Theme.shared.images.backArrow, for: .normal)
        navigationPanel.addSubview(backButton)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.centerYAnchor.constraint(equalTo: navigationPanel.centerYAnchor).isActive = true
        backButton.trailingAnchor.constraint(equalTo: navigationBar.centerXAnchor, constant: -25.0).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 35).isActive = true

        forwardButton.addTarget(self, action: #selector(forwardAction), for: .touchUpInside)
        forwardButton.setImage(Theme.shared.images.forwardArrow, for: .normal)
        navigationPanel.addSubview(forwardButton)

        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.centerYAnchor.constraint(equalTo: navigationPanel.centerYAnchor).isActive = true
        forwardButton.leadingAnchor.constraint(equalTo: navigationBar.centerXAnchor, constant: 25.0).isActive = true
        forwardButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        forwardButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
    }

    private func setupWebView() {
        webView.navigationDelegate = self
        webView.scrollView.delegate = self

        view.addSubview(webView)
        view.bringSubviewToFront(navigationBar)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        webView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: navigationPanel.topAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
    }

    private func setupGrabber() {
        if modalPresentationStyle != .popover { return }
        
        view.addSubview(grabber)

        grabber.heightAnchor.constraint(equalToConstant: 5).isActive = true
        grabber.widthAnchor.constraint(equalToConstant: 44).isActive = true
        grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 23.0).isActive = true
        grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
}

extension WebBrowserViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isModalInPresentation = true // Disabling dismiss controller with swipe down on webview
        lastContentOffset = scrollView.contentOffset.y
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isModalInPresentation = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.lastContentOffset < scrollView.contentOffset.y && scrollDirection != .down {
            scrollDirection = .down
            hideNavigationPanel()
        } else if self.lastContentOffset > scrollView.contentOffset.y && scrollDirection != .up {
            scrollDirection = .up
            showNavigationPanel()
        }
    }
}
