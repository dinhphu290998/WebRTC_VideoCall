
import UIKit
import DropDown

class BrushCell: DropDownCell {

  @IBOutlet weak var brushView: UIView!
  @IBOutlet weak var widthBrushConstraint: NSLayoutConstraint!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  public func setBrush(color: UIColor, width: Float) {
    brushView.backgroundColor = color
    widthBrushConstraint.constant = CGFloat(width/2)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

}
