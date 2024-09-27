//
//
// Created by Ashamaz Shidov on 23/9/24
//
        
import UIKit
import AppNexusSDK

final class BannerAdViewController: UIViewController {
    private let adSize = CGSize(width: 300.0, height: 250.0)
    private let adSize2x = CGSize(width: 600.0, height: 500.0)
    private lazy var bannerContainer = UIView()
    private lazy var banner = createBanner()
    private let errorLabel = UILabel()
    private lazy var errorView = createErrorView()
    private lazy var controlTableView = BannerAdConfigTableView(config: .from(banner)) { [weak self] updateBanner, config in
        guard let self else { return }
        errorView.alpha = 0
        if updateBanner {
            banner.removeFromSuperview()
            banner = createBanner()
            banner.loadAd()
        }
        adjustBannerConfig(config: config)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        controlTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlTableView)
        
        bannerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerContainer)
        view.addSubview(errorView)
        
        NSLayoutConstraint.activate([
            bannerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            bannerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerContainer.heightAnchor.constraint(equalToConstant: adSize.height),
            bannerContainer.widthAnchor.constraint(equalToConstant: adSize.width),
            bannerContainer.bottomAnchor.constraint(equalTo: controlTableView.topAnchor, constant: -16),
            
            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.widthAnchor.constraint(equalToConstant: 350),
            errorView.heightAnchor.constraint(equalToConstant: 100),
            errorView.centerYAnchor.constraint(equalTo: bannerContainer.centerYAnchor),
            
            controlTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        adjustBannerConfig(config: controlTableView.config)
    }
    
    
    private func createBanner() -> ANBannerAdView {
        let banner = ANBannerAdView(
            frame: .zero,
            placementId: "17058950",
            adSize: adSize
        )
        banner.delegate = self
        banner.rootViewController = self
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.rootViewController = self
        return banner
    }
    
    private func setupBanner() {
        bannerContainer.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: bannerContainer.topAnchor),
            banner.leadingAnchor.constraint(equalTo: bannerContainer.leadingAnchor),
            banner.bottomAnchor.constraint(equalTo: bannerContainer.bottomAnchor),
            banner.trailingAnchor.constraint(equalTo: bannerContainer.trailingAnchor),
        ])
    }
    
    private func adjustBannerConfig(config: BannerAdConfig) {
        switch config.adSize {
        case .size1x:
            banner.adSize = adSize
        case .size2x:
            banner.adSize = adSize2x
        }
        
        banner.autoRefreshInterval = config.refreshInterval.interval
        banner.transitionType = config.transitionType
        banner.transitionDirection = config.transitionDirection
        banner.alignment = config.alignment
        banner.shouldResizeAdToFitContainer = config.resizeToFit
    }
    
    private func createErrorView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.alpha = 0
        container.backgroundColor = .black.withAlphaComponent(0.7)
        errorLabel.textColor = .white
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.numberOfLines = 0
        container.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            errorLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            errorLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])
        
        return container
    }
}

extension BannerAdViewController: ANBannerAdViewDelegate {
    func ad(_ ad: Any, requestFailedWithError error: any Error) {
        errorLabel.text = error.localizedDescription
        errorView.alpha = 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.errorView.alpha = 0
        }
    }
    
    func adDidReceiveAd(_ ad: Any) {
        setupBanner()
    }
}
