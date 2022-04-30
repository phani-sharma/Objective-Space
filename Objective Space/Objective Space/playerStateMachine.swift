//
//  playerStateMachine.swift
//  Objective Space
//
//  Created by Padmasri Nishanth on 4/17/20.
//  Copyright © 2020 Final Project. All rights reserved.
//

import Foundation
import GameplayKit

fileprivate let characterAnimationkey = "Sprite Animation"

//MARK:- PlayerState Machine
class PlayerState : GKState
{
    unowned var playerNode : SKNode
    
    init(playerNode:SKNode) {
        self.playerNode = playerNode
        
        super.init()
    }
    
}

//MARK:- Jumping State
class JumpingState : PlayerState
{
    var hasFinishedJumping : Bool = false
    // This function allows us to jump from the existing state to the next state
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        
        if stateClass is StunnedState.Type {return true}
        
    if hasFinishedJumping && stateClass is LandingState.Type {return true}
        return false
    }
    
    let textures : Array<SKTexture> = (0..<2).map({return "Jump\($0)"}).map(SKTexture.init)
    lazy var action = {
        SKAction.animate(with: textures, timePerFrame: 0.1)
    }()
    
    override func didEnter(from previousState: GKState?) {
        
        playerNode.removeAction(forKey: characterAnimationkey)
        playerNode.run(action, withKey: characterAnimationkey)
        hasFinishedJumping = false
        playerNode.run(.applyForce(CGVector(dx: 0, dy: 100), duration: 0.2))
        // using the timer for the accidental jumps
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
            self.hasFinishedJumping = true
            
        }
        
    }
}

//MARK:- Landing State
class LandingState : PlayerState
{
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is LandingState.Type, is JumpingState.Type: return false
        default : return true
        }
    }
    
    override func didEnter(from previousState: GKState?) {
        stateMachine?.enter(IdleState.self)
    }
}

//MARK:- IdleState
class IdleState : PlayerState
{
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass{
        case is  LandingState.Type, is IdleState.Type : return false
        default : return true
        }
    }
    
    let textures = SKTexture(imageNamed: "player0")
    lazy var action = { SKAction.animate(with:[self.textures], timePerFrame: 0.1)}()

    override func didEnter(from previousState: GKState?) {
        playerNode.removeAction(forKey: characterAnimationkey)
        playerNode.run(action, withKey: characterAnimationkey)
    }
}
    
//MARK:- Walking State
class WalkingState : PlayerState
{
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
       
        switch stateClass {
        case is LandingState.Type, is WalkingState.Type : return false
        default : return true
            
        }
    }
    
    let textures : Array<SKTexture> = (0..<6).map({return "player\($0)"}).map(SKTexture.init)
    lazy var action = {
        SKAction.repeatForever(.animate(with: self.textures, timePerFrame: 0.1))
    }()
    
    override func didEnter(from previousState: GKState?) {
        playerNode.removeAction(forKey: characterAnimationkey)
        playerNode.run(action, withKey: characterAnimationkey)
    }
}

//MARK:- Stunned State 
class StunnedState : PlayerState{
    
    var isStunned : Bool = false
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        if isStunned { return false}
       
        switch stateClass {
        case is IdleState.Type : return true
        default : return false
        }
        
    }
    
    let action = SKAction.repeat(.sequence([
        .fadeAlpha(to: 0.5, duration: 0.01),
        .wait(forDuration: 0.25),
        .fadeAlpha(to: 1.0, duration: 0.01),
        .wait(forDuration: 0.25)
         ]), count: 5)
    
    override func didEnter(from previousState: GKState?) {
        
        isStunned = true
        playerNode.run(action)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (Timer) in
            self.isStunned = false
            self.stateMachine?.enter(IdleState.self)
        }
    }
    
}

