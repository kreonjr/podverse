//
//  myPodcastTableCell.swift
//  Podverse
//
//  Created by Mitchell Downey on 5/5/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class myPodcastTableCell: UITableViewCell {
    
    
    @IBOutlet weak var PVtitle: UILabel!
    @IBOutlet weak var PVimage: UIImageView!
    @IBOutlet weak var PVlastPubDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
