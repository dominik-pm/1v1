# Developer Guide

## General Information

### Player
- every Client has a Player.tscn (Scenes/player/Player.tscn) that gets represented on every other client (including the server) as a PuppetPlayer (Scenes/player/PuppetPlayer/PuppetPlayer.tscn)
- Collision Detection is based in the bullet
- server detects collision (as does every client) and tells the hit player that he got hit and the shooter that he hit his target 