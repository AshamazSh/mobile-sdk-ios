//
//
// Created by Ashamaz Shidov on 23/9/24
//
        

import UIKit

final class RootViewController: UITableViewController {
    
    enum AdType: String, CaseIterable {
        case banner = "Banner"
        case interstitial = "Interstitial"
        case native = "Native"
        case video = "Video"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        AdType.allCases.count
    }
    
    private static let cellId = "cellId"
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: RootViewController.cellId) {
            cell = dequeuedCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: RootViewController.cellId)
        }
        
        cell.textLabel?.text = AdType.allCases[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetViewController: UIViewController
        switch AdType.allCases[indexPath.row] {
        case .banner:
            targetViewController = BannerAdViewController()
        case .interstitial:
            targetViewController = InterstitialAdViewController()
        case .native:
            targetViewController = NativeAdViewController()
        case .video:
            targetViewController = VideoAdViewController()
        }
        
        navigationController?.pushViewController(targetViewController, animated: true)
    }
}

