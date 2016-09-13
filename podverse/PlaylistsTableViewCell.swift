//
//  PlaylistTableViewCell.swift
//  podverse
//

import UIKit

class PlaylistsTableViewCell: UITableViewCell {

    @IBOutlet weak var pvImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var totalItems: UILabel!
    @IBOutlet weak var lastUpdatedDate: UILabel!
    @IBOutlet weak var ownerName: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
