# special-adventures

## Structure
text_rpg/
│── main.py          # Entry point of the game
│── game.py          # Game logic (handles flow, menu, and battles)
│── player.py        # Player class and character creation
│── enemy.py         # Enemy class and logic
│── character.py     # Base Character class
│── ui.py            # Handles UI elements (ASCII art, menus, HUD)
│── utils.py         # Utility functions like clearing the screen

## Design Choices
- The game is text-based and uses ASCII art for visual representation. (Potential to add static images for better visual representation?)
- The game is structured in a way that allows for easy expansion (adding new enemies, items, etc.)
- The game uses a simple menu system for player interaction. (Possibility to add actual clickable menus?)
- The game uses a simple battle system where the player and enemy take turns attacking each other.
- The game uses a simple leveling system where the player gains experience points by defeating enemies, and completing quests.
- The game uses a simple inventory and equipment system where the player can collect items and equip them.
- The game uses a simple stats system where the player has attributes like stamina, strength, agility, and intelligence.
- The game will use a reputation system where the player's actions will affect how NPCs react to them.
- Ability to save and load the game state.

## Stats system
- Stamina: Determines the player's health points (HP) and how much damage they can take.
- Strength: Determines the player's melee attack damage, as well as ability to use some weapons and aumors.
- Agility: Determines the player's ranged attack damage, as well as ability to dodge attacks. Also allows the player to equip some ranged weapons.
- Intelligence: Determines the player's magic attack damage, as well as ability to use some spells and items. Also affects the player's mana points (MP).
- Armor: Reduces the amount of damage taken from enemy attacks.
- Resistance: Reduces the amount of damage taken from enemy spells.

