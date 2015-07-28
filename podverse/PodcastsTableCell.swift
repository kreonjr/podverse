//
//  PodcastsTableCell.swift
//  podverse
//
//  Created by Mitchell Downey on 6/7/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastsTableCell: UITableViewCell {


    @IBOutlet weak var pvImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var totalClips: UILabel!
    @IBOutlet weak var lastPublishedDate: UILabel!
    @IBOutlet weak var episodesDownloadedOrStarted: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
