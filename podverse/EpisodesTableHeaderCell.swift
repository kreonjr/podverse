//
//  EpisodesTableViewCellHeader.swift
//  podverse
//
//  Created by Mitchell Downey on 6/7/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class EpisodesTableHeaderCell: UITableViewCell {

    @IBOutlet weak var pvImage: UIImageView!
    @IBOutlet weak var summary: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
