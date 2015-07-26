//
//  DownloadsTableViewCell.swift
//  podverse
//
//  Created by Mitchell Downey on 6/23/15.
//  Copyright (c) 2015 Mitchell Downey. All rights reserved.
//

import UIKit

class DownloadsTableViewCell: UITableViewCell {

    @IBOutlet weak var pvImage: UIImageView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var progressBytes: UILabel!
    @IBOutlet weak var downloadStatus: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
