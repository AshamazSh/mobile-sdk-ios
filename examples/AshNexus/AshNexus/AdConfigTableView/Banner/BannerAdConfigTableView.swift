//
//
// Created by Ashamaz Shidov on 24/9/24
//
        

import UIKit
import AppNexusSDK

struct BannerAdConfig {
    enum AdSize: Int, CaseIterable {
        case size1x = 0, size2x
    }

    enum RefreshInterval: Int, CaseIterable {
        case zero = 0, five, fifteen
        
        init(interval: TimeInterval) {
            switch interval {
            case 0:
                self = .zero
            case 5:
                self = .five
            default:
                self = .fifteen
            }
        }
        
        var interval: TimeInterval {
            switch self {
            case .zero:
                0.0
            case .five:
                5.0
            case .fifteen:
                15.0
            }
        }
    }

    var adSize: AdSize
    var refreshInterval: RefreshInterval
    var transitionType: ANBannerViewAdTransitionType
    var transitionDirection: ANBannerViewAdTransitionDirection
    var alignment: ANBannerViewAdAlignment
    var resizeToFit: Bool
    
    static func from(_ banner: ANBannerAdView) -> Self {
        .init(adSize: .size1x,
              refreshInterval: .init(interval: banner.autoRefreshInterval),
              transitionType: banner.transitionType,
              transitionDirection: banner.transitionDirection,
              alignment: banner.alignment,
              resizeToFit: banner.shouldResizeAdToFitContainer)
    }
}

final class BannerAdConfigTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    private(set) var config: BannerAdConfig
    private var refresh: (Bool, BannerAdConfig) -> Void
    init(config: BannerAdConfig, refresh: @escaping (Bool, BannerAdConfig) -> Void) {
        self.config = config
        self.refresh = refresh
        super.init(frame: .zero, style: .plain)
        delegate = self
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        7
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    static let plainCellId = "plainCellId"
    static let segmentedCell = "segmentedCell"

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell: UITableViewCell
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: BannerAdConfigTableView.plainCellId) {
                cell = dequeuedCell
            } else {
                cell = UITableViewCell(style: .default, reuseIdentifier: BannerAdConfigTableView.plainCellId)
            }
            cell.textLabel?.text = "Refresh"
            return cell
        default:
            let cell: SegmentedControlCell
            if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: BannerAdConfigTableView.segmentedCell) as? SegmentedControlCell {
                cell = dequeuedCell
            } else {
                cell = SegmentedControlCell(style: .default, reuseIdentifier: BannerAdConfigTableView.segmentedCell)
            }
            configureSegmentedCell(cell, at: indexPath.section)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            ""
        case 1:
            "Ad Size"
        case 2:
            "Refresh interval"
        case 3:
            "Transition"
        case 4:
            "Transition direction"
        case 5:
            "Alignment"
        case 6:
            "Size to fit"
        default:
            nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else { return }
        refresh(true, config)
    }
    
    private func configureSegmentedCell(_ cell: SegmentedControlCell, at section: Int) {
        switch section {
        case 1:
            cell.update(
                items: ["1x", "2x"],
                selectedItem: config.adSize.rawValue
            ) { [weak self] index in
                guard let self else { return }
                config.adSize = BannerAdConfig.AdSize(rawValue: index) ?? .size1x
                refresh(false, config)
            }

        case 2:
            cell.update(
                items: ["0", "5", "15"],
                selectedItem: config.refreshInterval.rawValue
            ) { [weak self] index in
                guard let self else { return }
                config.refreshInterval = BannerAdConfig.RefreshInterval(rawValue: index) ?? .zero
                refresh(false, config)
            }
        case 3:
            cell.update(
                items: ["none", "fade", "push", "move in", "reveal", "flip"],
                selectedItem: Int(config.transitionType.rawValue)
            ) { [weak self] index in
                guard let self else { return }
                config.transitionType = ANBannerViewAdTransitionType(rawValue: UInt(index)) ?? .none
                refresh(false, config)
            }
        case 4:
            cell.update(
                items: ["up", "down", "left", "right", "random"],
                selectedItem: Int(config.transitionDirection.rawValue)
            ) { [weak self] index in
                guard let self else { return }
                config.transitionDirection = ANBannerViewAdTransitionDirection(rawValue: UInt(index)) ?? .up
                refresh(false, config)
            }
        case 5:
            cell.update(
                items: ["center", "top left", "top center", "top right", "center left", "center right", "bottom left", "bottom center", "bottom right"],
                selectedItem: Int(config.alignment.rawValue)
            ) { [weak self] index in
                guard let self else { return }
                config.alignment = ANBannerViewAdAlignment(rawValue: UInt(index)) ?? .center
                refresh(false, config)
            }
        case 6:
            cell.update(
                items: ["yes", "no"],
                selectedItem: config.resizeToFit ? 0 : 1
            ) { [weak self] index in
                guard let self else { return }
                config.resizeToFit = index == 0
                refresh(false, config)
            }
        default:
            break
        }
    }
}
