# TetheredSouls
A minimalist block puzzle game inspired by classic wooden puzzles and modern design aesthetics.

## About
TetheredSouls is a strategic block puzzle game where players arrange various shapes on a 10x10 grid. The game features clean visuals and intuitive touch controls, focusing on engaging gameplay mechanics.

## Core Gameplay
- 10x10 grid board system
- Drag and drop various block shapes:
  - T-shaped blocks
  - L-shaped blocks 
  - J-shaped blocks
  - Square blocks
  - Single blocks
- Clear full rows or columns to score points
- Strategic block holder feature for temporary piece storage
- Game ends when no valid moves remain

## Features
- Clean, minimalist interface with warm wooden aesthetics
- Simple one-handed touch controls
- Offline play supported
- Score tracking and combo system
- Multiple game modes:
  - Classic endless mode
  - Daily challenges
  - Combo mode
- Social features:
  - Friend rankings
  - Global leaderboards
  - Score recording
- Locket integration:
  - Share game moments with friends
  - Daily puzzle snapshots
- Love Letter system:
  - Send and receive in-game messages
  - Share custom puzzle challenges

## Technical Details
- Built with Swift/SwiftUI for iOS
- Local data persistence
- Haptic feedback integration
- Optimized for single-handed gameplay
- Integrated Locket app API
- Secure message handling system

## Installation
1. Clone the repository



Dragged Block Centering:

Before Offset:
    Cursor Position (.)
    +--------+
    |        |
    |  2x2   |
    |  Block |
    +--------+
         .

After Offset:
    Cursor Position (.)
         .
    +--------+
    |        |
    |  2x2   |
    |  Block |
    +--------+


Heart Particle Positioning:

Grid Cell Reference:
    0    1    2    3
  +----+----+----+----+
0 |    |    |    |    |
  +----+----+----+----+
1 |    | B  B    |    |  ♥ <- Heart at Y+50
  +----+----+----+----+
2 |    | B  B    |    |
  +----+----+----+----+
3 |    |    |    |    |
  +----+----+----+----+

Side View of Heart Position:
    ♥  <- Y + 50
    
   +--+
   |  |  <- Block
   |  |
   +--+
    |
    |  <- Grid Cell
    |