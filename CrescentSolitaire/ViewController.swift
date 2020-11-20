import UIKit

var cards = Cards()
var game = Game()

var screenYS = CGFloat()
var cardXS = CGFloat()
var cardYS = CGFloat()
var cardXpos = CGFloat()
var cardYpos = CGFloat()
var dealPosition = CGPoint()
var vc:ViewController! = nil

class ViewController: UIViewController {
    
    @IBOutlet var undoButton: UIButton!
    @IBOutlet var newGameButton: UIButton!
    @IBOutlet var shuffleButton: UIButton!
    @IBOutlet var scoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        
        let xs = view.bounds.width
        screenYS = view.bounds.height
        
        cardXS = xs/7
        cardYS = cardXS * 4 / 3
        cardXpos = cardXS + 10
        cardYpos = cardYS + 10
        
        cards.initialize(self.view)
        dealPosition = CGPoint(x: xs + 50, y: screenYS + 50)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap1(_:)))
        tap1.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap1)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        view.addGestureRecognizer(longPress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        newGame(newGameButton)
    }
    
    func enableUndoButton(_ onoff:Bool) {
        undoButton.isEnabled = onoff
        undoButton.isHidden = !onoff
    }
    
    func updateShuffleButton() {
        let onoff:Bool = gd.shuffleCount < 3
        shuffleButton.isEnabled = onoff
        shuffleButton.isHidden = !onoff
        
        if onoff {
            let s = String(format: "Shuffle (%d)", 3 - gd.shuffleCount)
            shuffleButton.setTitle(s, for: .normal)
        }
    }
    
    func updateScore() { scoreLabel.text = String(format:"Score: %d",game.score) }
    
    @objc func handleTap1(_ sender: UITapGestureRecognizer) { game.tap(sender.location(ofTouch:0, in: self.view)) }
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) { game.longPress(sender.location(ofTouch:0, in: self.view)) }
    
    @IBAction func newGame(_ sender:UIButton) { game.newGame() }
    @IBAction func undo(_ sender: UIButton) { game.undo() }
    @IBAction func performShuffle(_ sender: UIButton) { game.shuffle(); updateShuffleButton() }
    @IBAction func performHint(_ sender: UIButton) { game.hint() }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchesBegan(touch.location(in: self.view))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchesMoved(touch.location(in: self.view))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            game.touchesEnded(touch.location(in: self.view))
        }
    }

    override var prefersStatusBarHidden : Bool { return true  }
}
