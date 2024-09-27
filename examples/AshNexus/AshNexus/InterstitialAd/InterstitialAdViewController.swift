//
//
// Created by Ashamaz Shidov on 23/9/24
//
        

import UIKit
import AppNexusSDK

final class InterstitialAdViewController: UIViewController, ANInterstitialAdDelegate {
    private lazy var interstitialAd: ANInterstitialAd = createAd()
    private lazy var errorLabel = UILabel()
    private lazy var showAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Present ad", for: .normal)
        button.addTarget(self, action: #selector(showAd), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    private lazy var loadAdButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Refresh", for: .normal)
        button.addTarget(self, action: #selector(loadAd), for: .touchUpInside)
        return button
    }()
    
    private func createAd() -> ANInterstitialAd {
        let interstitialAd = ANInterstitialAd(placementId: "17058950")
        interstitialAd.delegate = self
        interstitialAd.clickThroughAction = ANClickThroughAction.openSDKBrowser
        return interstitialAd
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [loadAdButton, showAdButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 64
        stackView.alignment = .center
        view.addSubview(stackView)
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.alpha = 0
        view.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            errorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        interstitialAd.load()
    }
    
    func adDidReceiveAd(_ ad: Any) {
        showAdButton.isEnabled  = true
        errorLabel.alpha = 0
    }
    
    func ad(_ ad: Any, requestFailedWithError error: Error) {
        showAdButton.isEnabled = false
        errorLabel.text = error.localizedDescription
        errorLabel.alpha = 1
    }
    
    @objc
    private func showAd() {
        interstitialAd.display(from: self)
        showAdButton.isEnabled = false
    }
    
    @objc
    private func loadAd() {
        errorLabel.alpha = 0
        showAdButton.isEnabled = false
        interstitialAd = createAd()
        interstitialAd.load()
    }
}
