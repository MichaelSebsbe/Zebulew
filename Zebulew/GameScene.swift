//
//  GameScene.swift
//  Zebulew
//
//  Created by Michael Sebsbe on 10/16/22.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    //Nodes
    var player: SKSpriteNode?
    var playerShadow: SKNode?
    var joystick: SKNode?
    var joystickKnob: SKNode?
    var aButton: SKNode?
    
    var wall: SKNode?
    var uzi: SKNode?
    
    var joystickAction = false
    
    //how far the knob can go
    var knobRadius: CGFloat = 50.0
    let playerScale = 0.331
    
    var knobIsReturning = false
    
    var knobsOGPositon: CGPoint = CGPoint(x: 0, y: 0)
    
    //Sprite Engine
    var previousTimeInterval: TimeInterval = 0
    var playerIsFacingRight = true
    let playerSpeed = 4.0
    
    
    //sound
    var gunPickUpSound = SKAction.playSoundFileNamed("gun_pick_up.mp3", waitForCompletion: false)
    
    //player textures
    let playerEmptyHandsTexture = SKTexture(imageNamed: "player_empty_hands")
    let playerPistolTexture = SKTexture(imageNamed: "player_pistol")
    
    //when the scene is presented by a view
    override func didMove(to view: SKView) {
        
        player = childNode(withName: "player") as? SKSpriteNode
        playerShadow = player?.childNode(withName: "shadow")
        playerShadow?.alpha = 0.7
        
        wall = childNode(withName: "wall")
        uzi = childNode(withName: "uzi")
    
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob")
        
        aButton = childNode(withName: "aButton")
        
        // storing the center of joystick to use for returning when let go
        if let joystickKnob = joystickKnob{
            knobsOGPositon = joystickKnob.position
        }
    }
    
}

// MARK: Touches

extension GameScene{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // for every touch
        for touch in touches {
            if let joystickKnob = joystickKnob {
                // get the location of the touch
                let location = touch.location(in: joystick!)
                // if the location of touch was in the frame of our knob, set joystick action to true
                joystickAction = joystickKnob.frame.contains(location)
            }
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let joystick = joystick,
              let joystickKnob = joystickKnob else {return}
        // if joystick not touched, return
        if !joystickAction {return}
        knobIsReturning = false
        
        for touch in touches{
            print("touch")
            // register postion of touch
            let position = touch.location(in: joystick)
            
            //how far we dragged the konb
            let length = sqrt(pow(position.y, 2) + pow(position.x, 2))
            //the angle of our drag from the center on the knob
            let angle = atan2(position.y, position.x)
            
            //if dragged withtin the radius of how far the knob can go,
            if knobRadius > length {
                joystickKnob.position = position
            } else { // otherwise calculate where in the knob radius to posiont the knob
                joystickKnob.position = CGPoint(x: cos(angle) * knobRadius, y: sin(angle) * knobRadius)
                
            }
        }
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("ended")
        returnJoysickKnobToCenter()
    }
    
}
// MARK: Helper functions
extension GameScene{
    fileprivate func returnJoysickKnobToCenter() {
        knobIsReturning = true
        let moveBackAction = SKAction.move(to: knobsOGPositon, duration: 0.1)
        moveBackAction.timingMode = .linear
        joystickKnob?.run(moveBackAction)
        joystickAction = false
    }
    
    private func startPlayerMovement(_ deltaTime: TimeInterval){
        guard let joystickKnob = joystickKnob,
                !knobIsReturning else {return}
        
        //get position fo joystic
        let xPosition = Double(joystickKnob.position.x)
        let yPostion = Double(joystickKnob.position.y)
        
        let angle = atan2(yPostion, xPosition)
        //create a displacement by multiplying joystick postion by Delta
        let displacment = CGVector(dx: xPosition * deltaTime, dy: yPostion * deltaTime)
        
        let move = SKAction.move(by: displacment, duration: 0)
        let faceMovement = SKAction.rotate(toAngle: angle, duration: 0.0)
        
        let movementAndFaceAction = SKAction.sequence([move, faceMovement])
        
        player?.run(movementAndFaceAction)
    }
}

// MARK: GameLoop

extension GameScene{
    // main event loop of game
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        let gunSpin = SKAction.rotate(byAngle: 0.02, duration: 0)
        
        uzi?.run(gunSpin)
        
        // Player Movement
        startPlayerMovement(deltaTime)
        

        if let uzi = uzi{
            if CGRectIntersectsRect(player!.frame, uzi.frame){
                run(gunPickUpSound)
                uzi.isHidden = true
                player!.texture = playerPistolTexture
                
                //set to nil so sound doesnt play again
                self.uzi = nil
            }
        }
        
    }
}
