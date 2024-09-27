//
//
// Created by Ashamaz Shidov on 24/9/24
//
        

import UIKit

final class SegmentedControlCell: UITableViewCell {
    
    private lazy var segmentedControl = UISegmentedControl(items: [])
    private var onItemSelect: ((Int) -> Void)?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(didSelectSegment), for: .valueChanged)
        contentView.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func update(items: [String], selectedItem: Int, onSelect: @escaping (Int) -> Void) {
        segmentedControl.removeAllSegments()
        items.enumerated().forEach { (index, item) in
            segmentedControl.insertSegment(withTitle: item, at: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = selectedItem
        onItemSelect = onSelect
    }
    
    @objc
    private func didSelectSegment() {
        onItemSelect?(segmentedControl.selectedSegmentIndex)
    }
}
