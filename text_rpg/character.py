class Character:
    def __init__(self, name, health, attack, defense):
        self.name = name
        self.health = health
        self.attack = attack
        self.defense = defense

    def is_alive(self):
        return self.health > 0

    def take_damage(self, damage):
        damage_taken = max(0, damage - self.defense)
        self.health = max(0, self.health - damage_taken)
        print(f"{self.name} takes {damage_taken} damage! Health: {self.health}")

    def attack_enemy(self, enemy):
        from random import randint
        damage = randint(1, self.attack)
        print(f"{self.name} attacks {enemy.name} for {damage} damage!")
        enemy.take_damage(damage)