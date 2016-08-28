//
//  PlaylistItemsTableViewCell.swift
//  podverse
//
//  Created by Mitchell Downey on 2/2/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class PlaylistItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var pvImage: UIImageView!
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var podcastTitle: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var startEndTime: UILabel!
    @IBOutlet weak var itemPubDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
