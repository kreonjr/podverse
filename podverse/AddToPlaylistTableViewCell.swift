//
//  AddToPlaylistTableViewCell.swift
//  podverse
//
//  Created by Mitchell Downey on 2/5/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class AddToPlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var totalItems: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
