//
//  PodcastHeaderCell.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/6/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class PodcastHeaderCell: UITableViewCell {
    

    @IBOutlet weak var PVimage: UIImageView!
    @IBOutlet weak var PVsummary: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
