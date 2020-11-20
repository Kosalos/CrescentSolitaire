import UIKit

let help = """
First, one King and one Ace of each suit are removed to form the
bases for the foundations.
The kings are placed on a row, while the aces are placed below the kings.
The ninety-six remaining cards are dealt to the tableau
as 16 piles of six cards each.

The object is to move all the cards from the tableau to the foundations.
The kings are built down by suit up to aces
and the aces are built up, also by suit, to kings.

The top card of each pile is available to play
on the foundations or around the tableau.

Only one card can be moved at a time.

Building on the tableau is either up or down by suit
and can go round-the-corner (placing a king over an ace and vice versa).

Spaces are not filled.

The cards can be shuffled three times.
The bottom card of each pile in the tableau is placed on the top without
disturbing the order of the other cards in the pile.

The game is won when all 104 tableau cards are moved to the foundations.


How to Move Cards

Click/Drag the desired card to the destination pile.

shortcut command: Tap to move card to home pile.

Long press on pile for a list of all cards within.
"""

class HelpViewController: UIViewController {

    @IBOutlet var helptext: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 550,height: 700)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        helptext.text = help
    }
}
