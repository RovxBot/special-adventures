from text_rpg.character import Character

class Enemy(Character):
    def __init__(self, name, health, attack, defense):
        super().__init__(name, health, attack, defense, agi=5, str=5, amour=5, int=5, stam=5)