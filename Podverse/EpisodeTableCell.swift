//
//  EpisodeTableCell.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/7/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class EpisodeTableCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var summary: UILabel!
    @IBOutlet weak var pubDate: UILabel!
    @IBOutlet weak var listenedTime: UILabel!
    @IBOutlet weak var duration: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
