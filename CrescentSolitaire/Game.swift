import UIKit

let BOARDCOLUMNS = 4
let BOARDROWS = 4
let HOMECOLUMNS = 4
let HOMEROWS = 2
let NUMSPOTS = BOARDCOLUMNS * BOARDROWS + HOMECOLUMNS * HOMEROWS
let EMPTY = -1
let MAX_UNDO = 50

// MARK:-

struct CardStack {
    var position = CGPoint()
    var stack:[Int] = []
}

// MARK:-

struct GameData {
    var board = Array(repeating:CardStack(), count: NUMSPOTS)
    var shuffleCount = Int()
    
    mutating func reset() {
        shuffleCount = 0
        for i in 0 ..< NUMSPOTS { board[i].stack.removeAll() }
    }
    
    func isStackEmpty(_ boardIndex:Int) -> Bool { return board[boardIndex].stack.count == 0 }
}

var gd = GameData()

// MARK:-

class Game {
    var cIndex = Int()  // card index
    var bIndex = Int()  // source board index
    var dIndex = Int()  // destination board index
    var finishedSession:Bool = true
    var score = Int()
    
    let DEAL_DELAY:TimeInterval = 0.01
    var dealDelay:TimeInterval = 0
    
    init() {
        cards.setNumberOfDecks(2)
        
        var index = 0
        
        for r:Int in 0 ..< BOARDROWS {
            for c:Int in 0 ..< BOARDCOLUMNS {
                gd.board[index].position.x = 50 + cardXpos + CGFloat(c) * cardXpos
                gd.board[index].position.y = 20 + CGFloat(r) * cardYpos
                index += 1
            }
        }
        
        for r:Int in 0 ..< HOMEROWS {
            for c:Int in 0 ..< HOMECOLUMNS {
                gd.board[index].position.x = 50 + cardXpos + CGFloat(c) * cardXpos
                gd.board[index].position.y = 50 + cardYpos * 4 + CGFloat(r) * cardYpos
                index += 1
            }
        }
    }
    
    // MARK:-

    func newGame() {
        if !finishedSession { return } // must wait until previous session is finished
        finishedSession = false
        
        gd.reset()
        resetUndo()
        cards.shuffle()
        vc.updateShuffleButton()
        
        dealDelay = 0
        var index = 0
        
        // move All Cards To Deal Pile
        UIView.animate(withDuration: 0.3, delay: dealDelay, options: .curveLinear, animations: {
            for i in 0 ..< NUM_CARDS {
                cards.setPosition(i, dealPosition)
                cards.setZ(i, i)
            }
        }, completion: { (complete: Bool) in
            
            // board cards:  6 cards each
            for _ in 0 ..< 6 {
                for x in 0 ..< BOARDCOLUMNS {
                    for y in 0 ..< BOARDROWS {
                        self.addCardToBoard(index,x,y, false)
                        index += 1
                        self.dealDelay += self.DEAL_DELAY
                    }
                }
            }
            
            // home cards: 1 card each
            var count = HOMEROWS * HOMECOLUMNS
            
            for y in 0 ..< HOMEROWS {
                for x in 0 ..<  HOMECOLUMNS {
                    count -= 1
                    self.addCardToHome(index,x,y, count == 0)
                    index += 1
                    self.dealDelay += self.DEAL_DELAY
                }
            }

            self.updateScore()
        }
        )
    }
    
    func addCard(
        _ index:Int,
        _ cardIndex:Int,
        _ delay:TimeInterval,
        _ setDoneFlag:Bool = false)
    {
        gd.board[index].stack.append(cardIndex)
        cards.setZ(cardIndex, gd.board[index].stack.count)
        
        UIView.animate(withDuration: 0.1, delay: delay, options: .curveLinear, animations: {
            cards.setPosition(cardIndex, gd.board[index].position)
        }, completion: { (complete: Bool) in
            if setDoneFlag { self.finishedSession = true }
        }
        )
    }
    
    func addCardToBoard(_ cardIndex:Int, _ column:Int, _ row:Int, _ setDoneFlag:Bool = false) {
        let index = column + row * BOARDCOLUMNS
        addCard(index,cardIndex,dealDelay,setDoneFlag)
    }
    
    func addCardToHome(_ cardIndex:Int, _ column:Int, _ row:Int, _ setDoneFlag:Bool = false) {
        let index = BOARDCOLUMNS * BOARDROWS + column + row * HOMECOLUMNS
        addCard(index,cardIndex,dealDelay,setDoneFlag)
    }
    
    // MARK:-
    
    func cardIndexOfTopOfStack(_ boardIndex:Int) -> Int {
        if gd.isStackEmpty(boardIndex) { return EMPTY }
        return gd.board[boardIndex].stack.last!
    }
    
    func isLegalToDropCardAtIndex(_ cardIndex:Int, _ boardIndex:Int) -> Bool {
        if boardIndex == EMPTY { return false }
        
        // cannot drop to empty board position
        if gd.isStackEmpty(boardIndex) { return false }
        
        let c1 = cards.cardData[cardIndex] // card we are moving
        let c2 = cards.cardData[cardIndexOfTopOfStack(boardIndex)] // card on top of destination stack
        
        // can only drop on same suit
        if c1.suit != c2.suit { return false }
        
        // home piles only accept in right order
        if boardIndex >= NUMSPOTS-8 && boardIndex < NUMSPOTS-4 { // Kings
            if c1.rank != c2.rank-1 { return false }
        }
        if boardIndex >= NUMSPOTS-4 { // Aces
            if c1.rank != c2.rank+1 { return false }
        }
        
        // must have neighboring rank
        let diff = abs(c1.rank - c2.rank)
        if diff == 1 { return true }
        if diff == 12 && boardIndex < NUMSPOTS-8 { return true } // wrap around from ace -> king, king -> ace except home piles
        
        return false
    }
    
    // MARK:-
    
    func determineBoardIndex(_ pt:CGPoint) -> Int {
        let yMargin = CGFloat(50)
        var rect = CGRect(x:0, y:0, width:cardXS, height:cardYS + yMargin * 2)
        
        for boardIndex in 0 ..< NUMSPOTS {
            if !gd.isStackEmpty(boardIndex) {
                rect.origin = gd.board[boardIndex].position
                rect.origin.y -= yMargin
                
                if rect.contains(pt) { return boardIndex }
            }
        }
        
        return EMPTY
    }
    
    // MARK:-
    
    var touchBeganPoint = CGPoint()
    
    func touchesBegan(_ pt:CGPoint) {
        bIndex = determineBoardIndex(pt)
        
        if bIndex != EMPTY {
            // must leave at least one card in home piles
            if bIndex >= NUMSPOTS - 8 && gd.board[bIndex].stack.count == 1 { bIndex = EMPTY; return  }
            
            cIndex = cardIndexOfTopOfStack(bIndex)
            cards.setZ(cIndex,200) // ontop of all other cards while moving
            touchBeganPoint = pt
        }
    }
    
    func touchesMoved(_ pt:CGPoint) {
        if bIndex == EMPTY { return }
        
        if (abs(pt.x-touchBeganPoint.x) + abs(pt.y-touchBeganPoint.y)) > 10.0 {
            let dx = pt.x - touchBeganPoint.x
            let dy = pt.y - touchBeganPoint.y
            cards.setDeltaPosition(cIndex,dx,dy)
        }
    }
    
    func touchesEnded(_ pt:CGPoint) {
        if bIndex == EMPTY { return }
        dIndex = determineBoardIndex(pt)
        
        performCardMove()
    }
    
    func performCardMove() {
        if !isLegalToDropCardAtIndex(cIndex,dIndex) {
            cards.goBackHome(cIndex)
        }
        else {
            copytoUndo()
            
            gd.board[dIndex].stack.append(cIndex)   // move card to destination stack
            gd.board[bIndex].stack.removeLast()     // remove card from source stack
            
            cards.setPosition(cIndex, gd.board[dIndex].position)
            
            updateUndoButton()
            updateZOrder()
            updateScore()
        }
        
        bIndex = EMPTY
       // debug()
    }
    
    // MARK:-
    
    func hint() {
        var hintCount = 0
        var hintDelay:TimeInterval = 0.1
        
        for i in 0 ..< NUMSPOTS {
            let c1 = cardIndexOfTopOfStack(i)
            if c1 == EMPTY { continue }
            
            for j in i+1 ..< NUMSPOTS {
                let c2 = cardIndexOfTopOfStack(j)
                if c2 == EMPTY { continue }
                if !isLegalToDropCardAtIndex(c1,j) { continue }
                
                func animateMove(_ x:CGFloat, _ y:CGFloat) {
                    UIView.animate(withDuration: 0.05, delay: hintDelay, options: .curveLinear, animations: {
                        cards.setDeltaPosition(c1,x,y)
                        cards.setDeltaPosition(c2,x,y)
                    }, completion: nil )
                }
                
                animateMove(30,30)
                hintDelay += 0.2
                
                animateMove(0,0)
                hintDelay += 0.3
                
                hintCount += 1
            }
        }
        
        if hintCount == 0 { alert("No moves", "\nShuffle if possible")  }
    }
    
    // MARK:- tap to move selected card to home pile
    
    func tapMove(_ pt:CGPoint, _ baseIndex:Int) {
        bIndex = determineBoardIndex(pt)
        if bIndex == EMPTY { return }
        
        let cardIndex = cardIndexOfTopOfStack(bIndex)
        let card = cards.cardData[cardIndex]
        dIndex = baseIndex - card.suit
        
        print("move %d - %d",bIndex,dIndex)
        
        performCardMove()
    }
    
    func tap(_ pt:CGPoint) {
        bIndex = determineBoardIndex(pt)
        if bIndex == EMPTY { return }
        let cardIndex = cardIndexOfTopOfStack(bIndex)
        let card = cards.cardData[cardIndex]

        // drop on Aces pile?
        let d1 = NUMSPOTS - 1 - card.suit
        if isLegalToDropCardAtIndex(cardIndex,d1) {
            dIndex = d1
            performCardMove()
            return
        }

        // drop on Kings pile?
        let d2 = NUMSPOTS - 5 - card.suit
        if isLegalToDropCardAtIndex(cardIndex,d2) {
            dIndex = d2
            performCardMove()
        }
    }
    
    var isShowingAlert:Bool = false
    
    func longPress(_ pt:CGPoint) {   // long press for list of cards in stack
        if isShowingAlert { return }
        isShowingAlert = true
        
        let index = determineBoardIndex(pt)
        if index == EMPTY { return }
        
        // started a move session by mistake as well. put card back to home position
        cIndex =  cardIndexOfTopOfStack(index)
        cards.goBackHome(cIndex)
        
        var str = String()
        
        let count = gd.board[index].stack.count
        for i in 0 ..< count {
            let card = cards.cardData[gd.board[index].stack[count-1-i]]
            str = str + name(card.suit,card.rank) + "\n"
        }
        
        alert("Cards in Pile",str)
    }
    
    func updateZOrder() {
        for i in 0 ..< NUMSPOTS {
            for m in 0 ..< gd.board[i].stack.count {
                cards.setZ(gd.board[i].stack[m],m)
            }
        }
    }
    
    func updateScore() {
        score = 0
        for i in NUMSPOTS-8 ..< NUMSPOTS {
            score += gd.board[i].stack.count
        }

        vc.updateScore()
    }
    
    // MARK:- rotate cards in tableau stacks
    
    func shuffle() {
        var delay:TimeInterval = 0.1
        
        for i in 0 ..< NUMSPOTS - 8 {  // not for home piles
            let count = gd.board[i].stack.count
            if count > 1 {
                let t = gd.board[i].stack[0]
                
                func animateMove(_ x:CGFloat, _ y:CGFloat) {
                    UIView.animate(withDuration: 0.2, delay: delay, options: .curveLinear, animations: {
                        cards.setDeltaPosition(t,x,y)
                    }, completion: nil )
                }
            
                for m in 0 ..< count-1 { gd.board[i].stack[m] = gd.board[i].stack[m+1] }
                gd.board[i].stack[count-1] = t
                
                animateMove(0,300)
                delay += 0.01
                
                animateMove(0,0)
                delay += 0.001
            }
        }
        
        updateZOrder()
        
        gd.shuffleCount += 1
        vc.updateShuffleButton()
        
        //print("shuffle")
        //debug()
    }
    
    // MARK:-
    
    var undoIndex = 0
    var undoCount = 0
    var undoMemory = Array(repeating:GameData(), count: MAX_UNDO)
    
    func resetUndo() {
        undoIndex = 0
        undoCount = 0
        vc.enableUndoButton(false)
    }
    
    func copyGameData(_ src:GameData, _ dest:inout GameData) {
        for i in 0 ..< NUMSPOTS {
            dest.board[i] = src.board[i]
        }
    }
    
    func copytoUndo() {
        copyGameData(gd, &undoMemory[undoIndex])
        undoIndex += 1
        if undoIndex == MAX_UNDO {
            undoIndex = 0
        }
        
        undoCount += 1
        if undoCount == MAX_UNDO {
            undoCount = MAX_UNDO-1
        }
    }
    
    func undo() {
        if undoCount > 0 {
            undoCount -= 1
            
            undoIndex -= 1
            if undoIndex < 0 {
                undoIndex = MAX_UNDO-1
            }
            
            copyGameData(undoMemory[undoIndex], &gd)
            
            // reposition cards
            for i in 0 ..< NUMSPOTS {
                for s in 0 ..< gd.board[i].stack.count {
                    let index = gd.board[i].stack[s]
                    
                    UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveLinear, animations: {
                        cards.setPosition(index, gd.board[i].position)
                        cards.setZ(index,s)
                    }, completion: nil
                    )
                }
            }
        }
        
        updateUndoButton()
        updateZOrder()
    }
    
    func updateUndoButton() {
        vc.enableUndoButton(undoCount > 0)
    }
    
    func alert(_ title:String, _ message:String) {
        var alertController:UIAlertController! = nil
        alertController = UIAlertController(title:title, message:message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction!) in self.isShowingAlert = false }
        alertController.addAction(okAction)

        vc.present(alertController, animated: true, completion:nil)
    }
    
    func debug() {
        print("---------------------------------")
        for i in 0 ..< NUMSPOTS {
            
            var str = String(format:"%d (%d) : ",i,gd.board[i].stack.count)
            
            for s in 0 ..< gd.board[i].stack.count {
                let card = cards.cardData[gd.board[i].stack[s]]
                str = str + name(card.suit,card.rank) + ", "
            }
            
            //str += "\n"
            print(str)
        }
    }
}
