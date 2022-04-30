//
//  GameScene.swift
//  Objective Space
//
//  Created by Padmasri Nishanth on 3/25/20.
//  Copyright © 2020 Final Project. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    // declaring the nodes
    var player : SKNode?
    var joystick : SKNode?
    var joystickKnob : SKNode?
    var cameraNode : SKCameraNode?
    var mountains1 : SKNode?
    var mountains2 : SKNode?
    var mountains3 : SKNode?
    var moon : SKNode?
    var stars : SKNode?
    
    // creating a boolean for the Joystick action
    var joystickAction = false
    var rewardIsNotTouched = true
    var isHit = false

    // Measuring Declaring the radius for the Knob
    var knobRadius : CGFloat = 50.0
    
    // Score label Declaraion
    var scoreLabel = SKLabelNode()
    var score = 0
    
    // Declaration of the life hearts in a array
    var heartsArray = [SKSpriteNode]()
    let heartContainer = SKSpriteNode()
    
    
    // Sprite Engine
    var previousTimeInterval : TimeInterval = 0
    var playerIsfacingRight = true
    let playerSpeed = 4.0
    
    // PlayerstateMachine
    var playerStateMachine : GKStateMachine!
    
    
    // DidMove Function Declaration
    override func didMove(to view: SKView) {
    
        // Confirming the delegate to to the gameScene
        physicsWorld.contactDelegate = self
    
        // Getting the player and the child from the Gamescenes.sks
        player = childNode(withName: "player")
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob")
        cameraNode = childNode(withName: "cameraNode") as? SKCameraNode
        mountains1 = childNode(withName: "mountains1")
        mountains2 = childNode(withName: "mountains2")
        mountains3 = childNode(withName: "mountains3")
        moon = childNode(withName: "moon")
        stars = childNode(withName: "stars")

        // getting the StateMachine States
        playerStateMachine = GKStateMachine(states:[
            JumpingState(playerNode: player!),
            WalkingState(playerNode: player!),
            IdleState(playerNode: player!),
            LandingState(playerNode:player!),
            StunnedState(playerNode:player!)
            
        ])
        
        playerStateMachine.enter(IdleState.self)
        
        // Initilaisation of the hearts i.e. life system
        heartContainer.position = CGPoint(x: -300, y: 140)
        heartContainer.zPosition = 5
        cameraNode?.addChild(heartContainer)
        fillHearts(count: 3)
        
        
        // MARK:- using the meteor  function with the timer
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true){(timer) in
            
            self.spawnMeteor()
        }
        // The scorelabel implementation position
        scoreLabel.position = CGPoint(x: (cameraNode?.position.x)! + 310, y: 140)
        scoreLabel.fontColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        scoreLabel.fontSize = 25
        scoreLabel.fontName = "Rockwell-BoldItalic"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.text = String(score)
        cameraNode?.addChild(scoreLabel)
    }
}

// MARK:- Touches Extension of the class gameScene
extension GameScene{
    //MARK:- touches Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch in touches{
            if let joystickKnob = joystickKnob{
                let location = touch.location(in: joystick!)
                joystickAction = joystickKnob.frame.contains(location)
            }
            // To get the statemachine code from the playerStateMachine file and using the JumpState once the touch begins on the Screen
            let location = touch.location(in: self)
            if !(joystick?.contains(location))!{
                playerStateMachine.enter(JumpingState.self)
            }
            
        }
    }
    
    // MARK:- Touches Moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let joystick = joystick else {return}
        guard let joystickKnob = joystickKnob else {return}
        
        if !joystickAction { return }
        
        // Distance Calculation
        for touch in touches{
            let position = touch.location(in: joystick)
            
            // using the Pythagorean theorem
            let length = sqrt(pow(position.y, 2) + pow(position.x, 2))
            let angle = atan2(position.y, position.x)
            
            if knobRadius > length
            {
                joystickKnob.position = position
            }
            else
            {
                joystickKnob.position = CGPoint(x: cos(angle) * knobRadius, y: sin(angle) * knobRadius)
            }
        }
        
    }
    
    //MARK:- Touches Ended
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches{
            
            let xJoystickCoordinate = touch.location(in: joystick!).x
            let xLimit : CGFloat = 200.0
            if xJoystickCoordinate > -xLimit && xJoystickCoordinate < xLimit{
            resetKnobPosition()
            }
        }
    }
}

   //MARK:- Action
   extension GameScene{
    func resetKnobPosition(){
        let initialPoint = CGPoint(x: 0, y: 0)
        let moveBack = SKAction.move(to: initialPoint, duration: 0.1)
        moveBack.timingMode = .linear
        joystickKnob?.run(moveBack)
        joystickAction = false
    }
    // The incrementation of the scores and scoreLabel
    func rewardtouch()
    {
        score += 1
        scoreLabel.text = String(score)
    }

    // creating a function for the initialisation of the code
    func fillHearts(count: Int){
        for index in 1...count{
            let heart = SKSpriteNode(imageNamed: "heart")
            let xPosition = heart.size.width * CGFloat(index - 1)
            heart.position = CGPoint(x: xPosition, y: 0)
            heartsArray.append(heart)
            heartContainer.addChild(heart)
        }
    }
   
    // creating a function for the losing of hearts when the player gets hit
    func loseHearts(){
        if isHit == true{
            let lastElementIndex = heartsArray.count - 1
            if heartsArray.indices.contains(lastElementIndex - 1){
                let lastHeart = heartsArray[lastElementIndex]
                lastHeart.removeFromParent()
                heartsArray.remove(at: lastElementIndex)
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (Timer) in
                    self.isHit = false
                }
            }
            else{
                death()
            }
            invincible()
        }
    }
    
    func invincible(){
        player?.physicsBody?.categoryBitMask = 0
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (Timer) in
            self.player?.physicsBody?.categoryBitMask = 2
        }
    }
    
    func death(){
        let dieAction = SKAction.move(to: CGPoint(x: -300, y: 0), duration: 0.1)
        player?.run(dieAction)
        self.removeAllActions()
        fillHearts(count: 3)
    }
}

//MARK:- GameLoop for the charecter movement
extension GameScene{
    
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        // Using the rewardIsNotTouched
        rewardIsNotTouched = true
        
        // Camera implemenation
        cameraNode?.position.x = player!.position.x
        joystick?.position.y = (cameraNode?.position.y)! - 100
        joystick?.position.x = (cameraNode?.position.x)! - 300
        
        //Player Movement
        guard let joyStickKnob = joystickKnob else {return}
        let xPosition = Double(joyStickKnob.position.x)
        let positivePosition = xPosition < 0 ? -xPosition : xPosition
        if floor(positivePosition) != 0 {
            playerStateMachine.enter(WalkingState.self)
        }
        else
        {
            playerStateMachine.enter(IdleState.self)
        }
        let displacement = CGVector(dx: deltaTime * xPosition * playerSpeed, dy: 0)
        let move = SKAction.move(by: displacement, duration: 0)
        let faceAction:SKAction!
        let movingRight = xPosition > 0
        let movingLeft = xPosition < 0
        if movingLeft && playerIsfacingRight {
            playerIsfacingRight = false
            let faceMovement = SKAction.scaleX(to: -1, duration: 0.0)
            faceAction = SKAction.sequence([move,faceMovement])
            
        } else if movingRight && !playerIsfacingRight{
            playerIsfacingRight = true
            let faceMovement = SKAction.scaleX(to: 1, duration: 0.0)
            faceAction = SKAction.sequence([move,faceMovement])
        }else{
            faceAction = move
        }
        player?.run(faceAction)
        
        //MARK:- Background Parallax Animation
        let parallax1 = SKAction.moveTo(x:(player?.position.x)!/(-10), duration: 0.0)
        mountains1?.run(parallax1)
        
        let parallax2 = SKAction.moveTo(x:(player?.position.x)!/(-20), duration: 0.0)
        mountains2?.run(parallax2)
        
        let parallax3 = SKAction.moveTo(x:(player?.position.x)!/(-40), duration: 0.0)
        mountains3?.run(parallax3)
        
        let parallax4 = SKAction.moveTo(x: (cameraNode?.position.x)!, duration: 0.0)
        moon?.run(parallax4)
        
        let parallax5 = SKAction.moveTo(x: (cameraNode?.position.x)!, duration: 0.0)
        stars?.run(parallax5)
               
    }
}

//MARK:- Collision Implementation
extension GameScene : SKPhysicsContactDelegate{

    struct Collision{
        
        enum Masks : Int{
            case killing,player,reward,ground
            var bitMask : UInt32 {return 1 << self.rawValue}
        }
    
        let masks:(first :UInt32,second :UInt32)
        
        func matches(_first: Masks,_second: Masks) -> Bool{
            return(_first.bitMask == masks.first && _second.bitMask == masks.second) ||
                (_first.bitMask == masks.second && _second.bitMask == masks.first)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let collision = Collision(masks: (first:contact.bodyA.categoryBitMask,second:contact.bodyB.categoryBitMask))
        
        if collision.matches(_first: .player,_second: .killing){
         // func calling
            loseHearts()
            isHit = true
            
            // Using the stunned state
            playerStateMachine.enter(StunnedState.self)
        }
        
        if collision.matches(_first: .player, _second: .ground)
        {
            playerStateMachine.enter(LandingState.self)
        }
        
        // Using the collision for the jewel and the player
        // Disappearing the jewel after the collision 
        if collision.matches(_first: .player, _second: .reward){
            
            if contact.bodyA.node?.name == "jewel"{
                contact.bodyA.node?.physicsBody?.categoryBitMask = 0
                contact.bodyA.node?.removeFromParent()
            }
            else if contact.bodyB.node?.name == "jewel"{
               contact.bodyB.node?.physicsBody?.categoryBitMask = 0
               contact.bodyB.node?.removeFromParent()
            }
            
            if rewardIsNotTouched{
                rewardtouch()
                rewardIsNotTouched = false
            }
        }
        
        if collision.matches(_first: .ground, _second: .killing){
            if contact.bodyA.node?.name == "Meteor",let meteor = contact.bodyA.node{
                crateMolten(at: meteor.position)
                meteor.removeFromParent()
            }
            
            if contact.bodyB.node?.name == "Meteor",let meteor = contact.bodyB.node{
                           crateMolten(at: meteor.position)
                           meteor.removeFromParent()
                       }
        }
    }
}

// MARK:- Meteors Implementation
extension GameScene{
    // function to spawn the meteors
    func spawnMeteor(){

        let node = SKSpriteNode(imageNamed: "meteor")
        node.name = "Meteor"
        // Using the randomisation func for the spawning meteors
        let randomXPosition = Int(arc4random_uniform(UInt32(self.size.width)))
        node.position = CGPoint(x: randomXPosition, y: 270)
        node.anchorPoint = CGPoint(x: 0.5, y: 1)
        // Note : The anchorpoint is the center the meteor or the node
        node.zPosition = 5

        let physicsBody = SKPhysicsBody(circleOfRadius: 30)
        node.physicsBody = physicsBody
        
        physicsBody.categoryBitMask = Collision.Masks.killing.bitMask
        physicsBody.collisionBitMask = Collision.Masks.player.bitMask | Collision.Masks.ground.bitMask
         physicsBody.contactTestBitMask = Collision.Masks.player.bitMask | Collision.Masks.ground.bitMask
         physicsBody.fieldBitMask = Collision.Masks.player.bitMask | Collision.Masks.ground.bitMask
        
        physicsBody.affectedByGravity = true
        physicsBody.allowsRotation = false
        physicsBody.restitution = 0.2
        physicsBody.friction = 10
        
        addChild(node)
    }

    // function to create the molten form of the meteor
    func crateMolten(at position : CGPoint){
        
        let node = SKSpriteNode(imageNamed: "molten")
        node.position.x = position.x
        node.position.y = position.y - 60
        node.zPosition = 4
        
        addChild(node)
        
        // for the fadeIn and fadeOut animation
        let action = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()])
        
        node.run(action)
        
    }
}
