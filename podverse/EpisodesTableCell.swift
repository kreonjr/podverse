//
//  EpisodesTableCell.swift
//  podverse
//
//  Created by Mitchell Downey on 6/7/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class EpisodesTableCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var summary: UILabel!
    @IBOutlet weak var totalClips: UILabel!
    @IBOutlet weak var totalTimeLeft: UILabel!
    @IBOutlet weak var pubDate: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
