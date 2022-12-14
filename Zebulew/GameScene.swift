//
//  GameScene.swift
//  Zebulew
//
//  Created by Michael Sebsbe on 10/16/22.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
//--- nodes -------------------------
    //player
    var player: SKSpriteNode?
    var playerShadow: SKSpriteNode?
    
    //floor
    var floor: SKSpriteNode?
    
    //controls
    var joystick: SKNode?
    var joystickKnob: SKSpriteNode?
    var aButton: SKSpriteNode?
    var bButton: SKSpriteNode?
    var reloadButton: SKSpriteNode?
    
    //misc
    var flash : SKSpriteNode?
    var wall: SKSpriteNode?
    var bullet: SKSpriteNode?
    var gunPoint: SKSpriteNode?
    let gunLocation = CGPoint(x: 237.068, y: -198.964) // guns position in players node
    
    //weapons
    var uzi: SKSpriteNode?
    
    var joystickAction = false
    var aButtonisTapped = false

    var hasAgun: Bool = false
    var startBulletAnimation = false
    var jumping = false
    
    //to detect multiple touches
    var selectedNodes:[UITouch:SKSpriteNode] = [:]

    
    //how far the knob can go
    var knobRadius: CGFloat = 50.0
    let playerScale = 0.331
    var bulletFireAngle = 0.0
    
    var knobIsReturning = false
    
    var knobsOGPositon: CGPoint = CGPoint(x: 0, y: 0)
    
    //Sprite Engine
    var previousTimeInterval: TimeInterval = 0
    var playerIsFacingRight = true
    let playerSpeed = 4.0
    
    
    //sound
    var gunPickUpSound = SKAction.playSoundFileNamed("gun_pick_up.mp3", waitForCompletion: false)
    var pistolFireSound = SKAction.playSoundFileNamed("pistol_sound.mp3", waitForCompletion: true)
    var knifeSound =  SKAction.playSoundFileNamed("slash.mp3", waitForCompletion: true)
    var reloadSound = SKAction.playSoundFileNamed("gun_reload.mp3", waitForCompletion: true)
    var jumpSound = SKAction.playSoundFileNamed("jump_sound.mp3", waitForCompletion: true)
    
    //player textures
    let playerEmptyHandsTexture = SKTexture(imageNamed: "player_empty_hands")
    let playerPistolTexture = SKTexture(imageNamed: "player_pistol")
    
    //to count frames
    var frameCount = 0
    
    //when the scene is presented by a view
    override func didMove(to view: SKView) {
        //iniatilizing nodes
        setupNodes()
        // storing the center of joystick to use for returning when let go
        if let joystickKnob = joystickKnob{
            knobsOGPositon = joystickKnob.position
        }
    }
    
    private func setupNodes(){
        //floor
        floor = childNode(withName: "floor") as? SKSpriteNode
        
        //player
        player = childNode(withName: "player") as? SKSpriteNode
        playerShadow = player?.childNode(withName: "shadow") as? SKSpriteNode
        playerShadow?.alpha = 0.7
        
        playerShadow?.zPosition = 0.0
        player?.zPosition = 0.1
        
        //misc
        wall = childNode(withName: "wall") as? SKSpriteNode
        flash = childNode(withName: "flash") as? SKSpriteNode //to be used to flash screen when gun fired
        flash?.alpha = 0
        gunPoint = player!.childNode(withName: "gunPoint") as? SKSpriteNode
        
        //weapons
        uzi = childNode(withName: "uzi") as? SKSpriteNode
        bullet = childNode(withName: "bullet") as? SKSpriteNode
        //bullet?.isHidden = true
        
        //controls
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob") as? SKSpriteNode
        aButton = childNode(withName: "aButton") as? SKSpriteNode
        bButton = childNode(withName: "bButton") as? SKSpriteNode
        reloadButton = childNode(withName: "reloadButton") as? SKSpriteNode
    }
    
}

// MARK: Touches

extension GameScene{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // for every touch
        for touch in touches {
            
            // get the location of the touch
            let knobLocation = touch.location(in: joystick!)
            let location = touch.location(in: self)
            
            if let joystickKnob = joystickKnob {
                // if the location of touch was in the frame of our knob, set joystick action to true
                if joystickKnob.frame.contains(knobLocation){
                    joystickAction = true
                    selectedNodes[touch] = joystickKnob
                }
            }
            
            if let aButton = aButton{
                if aButton.frame.contains(location) {
                    aButtonisTapped = true
                }
            }
            
            if let reloadButton = reloadButton{
                if reloadButton.frame.contains(location){
                    run(reloadSound)
                }
            }
            
            if let bButton = bButton {
                if bButton.frame.contains(location){
                    run(jumpSound)
                    jumping = true
                }
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
            
            if selectedNodes[touch] == joystickKnob{
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
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if selectedNodes[touch] == joystickKnob{
                selectedNodes[touch] = nil
                returnJoysickKnobToCenter()
            }
        }
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
              joystickAction,
                !knobIsReturning else {return}
        
        //get position fo joystick
        let xPosition = Double(joystickKnob.position.x)
        let yPosition = Double(joystickKnob.position.y)
        
        let angle = atan2(yPosition, xPosition)
        //create a displacement by multiplying joystick postion by Delta
        let displacment = CGVector(dx: xPosition * deltaTime, dy: yPosition * deltaTime)
        
        let move = SKAction.move(by: displacment, duration: 0)
        let faceMovement = SKAction.rotate(toAngle: angle, duration: 0.0)
        
        let movementAndFaceAction = SKAction.sequence([move, faceMovement])
        
        player?.run(movementAndFaceAction)
    }
    
    private func fireGun(){
        guard let bullet = bullet,
              let player = player else { return }
        
        run(pistolFireSound)
        //calculkate offset for bullet location
        let playersRotationAngle = player.zRotation
        bulletFireAngle = playersRotationAngle
      
        bullet.position = player.convert(gunLocation, to: self)
        bullet.run(SKAction.rotate(toAngle: bulletFireAngle, duration: 0))
       
        startBulletAnimation = true
        
    }
    
    private func fireMelee(){
        run(knifeSound)
    }
    
    private func animateBullet(bulletSpeed: Double){
        guard let bullet = bullet else {return}
        
        let rise = sin(bulletFireAngle) * bulletSpeed
        let run = cos(bulletFireAngle) * bulletSpeed
        
        let displacment = CGVector(dx: run , dy: rise )
        
        let move = SKAction.move(by: displacment, duration: 0)
        
        let movementSequence = SKAction.sequence([move])
        
        bullet.run(movementSequence)
    }
    
    private func animateJump(){
        //skactions for player
        
        let scaleUpAction = SKAction.scale(by: 1.3125, duration: 0.5)
        
        //let scaleUpAction = SKAction.scale(to: CGSize(width: 105, height: 105), duration: 0.5)
        scaleUpAction.timingMode = .easeOut
        
        let scaleDownAction = SKAction.scale(by: 0.762, duration: 0.5)
        //let scaleDownAction = SKAction.scale(to: CGSize(width: 80, height: 80 ), duration: 0.5)
        scaleDownAction.timingMode = .easeIn
        
        let jumpAction = SKAction.sequence([scaleUpAction, scaleDownAction])
        
        //skAction for shadow
        
        let shadowScaleUpAction = SKAction.scale(to: CGSize(width: 490, height: 490), duration: 0.5)
        shadowScaleUpAction.timingMode = .easeOut
        
        let shadowScaleDownAction = SKAction.scale(to: CGSize(width: 420, height: 420 ), duration: 0.5)
        shadowScaleDownAction.timingMode = .easeIn
        
        let shadowAction = SKAction.sequence([shadowScaleDownAction, shadowScaleUpAction])
        
        playerShadow?.run(shadowAction)
        player?.run(jumpAction)
    }
    
}

// MARK: Game Loop

extension GameScene{
    // main event loop of game
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        let gunSpin = SKAction.rotate(byAngle: 0.02, duration: 0)
        
        uzi?.run(gunSpin)
        
        // Player Movement
        startPlayerMovement(deltaTime)
        
        if aButtonisTapped{
            aButtonisTapped = false

            //screen flashes if has a gun
            if hasAgun {
                //start counting frames
                frameCount += 1
                fireGun()
            }else{
                fireMelee()
            }
        }
    
        
        if frameCount <= 6 && frameCount > 0{
            if frameCount == 6{
                flash?.alpha = 0
                frameCount = 0
                
            } else {
                flash?.alpha = 0.9
                frameCount += 1
                
            }
        }
        
        if !floor!.frame.contains(bullet!.position){
            startBulletAnimation = false
        }
        
        if startBulletAnimation {
            animateBullet(bulletSpeed: 5)
        }
        
        if jumping{
            animateJump()
            jumping = false
        }
        
        if let uzi = uzi{
            if CGRectIntersectsRect(player!.frame, uzi.frame){
                run(gunPickUpSound)
              
                player!.texture = playerPistolTexture
                
                //scale down layer with pistol image to be approx. the same size as player without pistol
                player!.scale(to: CGSize(width: 65, height: 49.725))
                
                hasAgun = true
                
                self.uzi = nil
                uzi.isHidden = true
            }
        }
        
    }
}
