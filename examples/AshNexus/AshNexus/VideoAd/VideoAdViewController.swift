//
//
// Created by Ashamaz Shidov on 23/9/24
//
        

import UIKit
import AppNexusSDK

final class VideoAdViewController: UIViewController, ANInstreamVideoAdLoadDelegate, ANInstreamVideoAdPlayDelegate {
    private lazy var videoContainer = UIView()
    private lazy var videoAd = ANInstreamVideoAd(placementId: "17058950")
    private lazy var errorLabel = UILabel()
    private lazy var playButton = UIButton(type: .system)
    private var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoContainer)
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setTitle("Play", for: .normal)
        playButton.isEnabled = false
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        view.addSubview(playButton)
        
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
            videoContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoContainer.heightAnchor.constraint(equalToConstant: 300),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.topAnchor.constraint(equalTo: videoContainer.bottomAnchor, constant: 32),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: errorLabel.topAnchor, constant: -32),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            errorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        videoAd.load(with: self)
    }
    
    @objc
    private func refresh() {
        errorLabel.alpha = 0
        videoAd.load(with: self)
    }
    
    @objc
    private func play() {
        if isPlaying {
            playButton.setTitle("Play", for: .normal)
            videoAd.pause()
        } else {
            playButton.setTitle("Pause", for: .normal)
            videoAd.play(withContainer: videoContainer, with: self)
        }
        isPlaying.toggle()
        videoAd.load(with: self)
    }
    
    func adDidReceiveAd(_ ad: Any) {
        errorLabel.alpha = 0
        playButton.isEnabled = true
    }
    
    func ad(_ ad: Any, requestFailedWithError error: any Error) {
        errorLabel.text = error.localizedDescription
        errorLabel.alpha = 1
        playButton.isEnabled = false
    }
    
    func adDidComplete(_ ad: any ANAdProtocol, with state: ANInstreamVideoPlaybackStateType) {
        isPlaying = false
        playButton.setTitle("Play", for: .normal)
    }
}
