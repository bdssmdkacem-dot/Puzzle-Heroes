# Puzzle Heroes

Original portrait puzzle-adventure game built with Godot 4.

## Level 1 — Puzzle controls the adventure

The game is intentionally more than a Match-3 board: every successful combination changes the adventure scene.

### Current gameplay

- Portrait layout designed around 720 x 1280.
- 7 x 8 Match-3 board.
- Swipe or drag to exchange adjacent tiles.
- Valid matches of 3+ tiles are cleared.
- Tiles collapse and refill.
- Score and 25-move counter.
- Four destructible rocks form the hero's path.
- Each successful Match-3 damages the active rock.
- 3-match = 1 damage.
- 5+ match = 2 damage.
- 7+ match = 3 damage.
- When a rock reaches 0 HP, it breaks and the hero automatically advances to the next path point.
- A simple original hero and snake are drawn directly by Godot, so the prototype does not depend on external artwork.
- The snake reacts visually when the player attacks.
- The level is won when the hero reaches the exit.
- The level is lost if the 25 moves are exhausted before the path is cleared.
- Desktop mouse input is supported for easier testing; Android touch/swipe input is supported for the real mobile game.

## Gameplay loop

1. Choose a tile on the bottom board.
2. Swipe toward an adjacent tile.
3. Make a Match-3 combination.
4. The combination attacks the current obstacle.
5. Break the obstacle.
6. The hero walks forward.
7. Repeat until the exit is reached.

This establishes the core puzzle-adventure loop before adding final character art, richer obstacles, enemies, effects, sound, and multiple levels.

## Android

The project is prepared for Godot Android export. The official Godot documentation covers touch input and Android export setup:
https://docs.godotengine.org/en/4.7/tutorials/inputs/input_examples.html
https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
