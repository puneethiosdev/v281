//
//  CourseFilterCell.swift
//  edX
//
//  Created by Puneet JR on 10/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseFilterCell: UITableViewCell {
    
    
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var countlbl: UILabel!
    
    var isSelected: Bool?
    var isCellTag: NSIndexPath?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
