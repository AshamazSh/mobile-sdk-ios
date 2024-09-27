//
//
// Created by Ashamaz Shidov on 23/9/24
//
        

import UIKit
import AppNexusSDK

final class CustomAdView: UIView {
    private var response: ANNativeAdResponse?
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private lazy var button = UIButton(type: .system)
    private lazy var stackView: UIStackView = {
        let views: [UIView] = [titleLabel, bodyLabel, imageView, button]
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        stackView.alignment = .center
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ])
        }
        
        return stackView
    }()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    func update(with response: ANNativeAdResponse, in vc: UIViewController) {
        self.response = response
        titleLabel.text = response.title
        bodyLabel.text = response.body
        imageView.image = response.mainImage
        button.setTitle(response.callToAction, for: .normal)
        response.clickThroughAction = .openDeviceBrowser
        try? response.registerView(forTracking: self, withRootViewController: vc, clickableViews: [button])
    }
}

final class NativeAdViewController: UIViewController, ANNativeAdRequestDelegate {
    private lazy var nativeView = CustomAdView()
    private lazy var errorLabel = UILabel()
    private lazy var request: ANNativeAdRequest = createRequest()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        nativeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nativeView)
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Refresh", for: .normal)
        button.addTarget(self, action: #selector(refresh), for: .touchUpInside)
        view.addSubview(button)
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.alpha = 0
        view.addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            nativeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            nativeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nativeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: errorLabel.topAnchor, constant: -32),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            errorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        request.loadAd()
    }

    func adRequest(_ request: ANNativeAdRequest, didReceive response: ANNativeAdResponse) {
        nativeView.update(with: response, in: self)
        errorLabel.alpha = 0
    }
    
    func adRequest(_ request: ANNativeAdRequest, didFailToLoadWithError error: any Error, with adResponseInfo: ANAdResponseInfo?) {
        errorLabel.text = error.localizedDescription
        errorLabel.alpha = 1
    }
    
    private func createRequest() -> ANNativeAdRequest {
        let request = ANNativeAdRequest()
        request.placementId = "17058950"
        request.shouldLoadMainImage = true
        request.delegate = self
        return request
    }
    
    @objc
    private func refresh() {
        errorLabel.alpha = 0
        request = createRequest()
        request.loadAd()
    }
}
