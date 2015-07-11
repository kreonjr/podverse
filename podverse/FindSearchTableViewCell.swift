//
//  FindTableViewCell.swift
//  podverse
//
//  Created by Mitchell Downey on 7/10/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class FindSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var pvImage: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var summary: UILabel!
    @IBOutlet weak var totalClips: UILabel!
    @IBOutlet weak var lastPublishedDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
