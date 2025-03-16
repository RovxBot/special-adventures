class Character:
    def __init__(self, name, health, attack, defense, agi, str, amour, int, stam):
        self.name = name
        self.health = health + stam * 2
        self.attack = attack + str
        self.defense = defense + amour
        self.agi = agi
        self.str = str
        self.amour = amour
        self.int = int
        self.stam = stam

    def is_alive(self):
        return self.health > 0

    def take_damage(self, damage):
        from random import randint
        if randint(1, 100) <= self.agi:
            print(f"\033[93m{self.name} dodges the attack!\033[0m")
            return
        damage_taken = max(0, damage - self.defense)
        mitigated_damage = damage - damage_taken
        self.health = max(0, self.health - damage_taken)
        print(f"\033[91m{self.name} takes {damage_taken} damage! Health: {self.health}\033[0m")
        if mitigated_damage > 0:
            print(f"\033[94m{self.name} blocks {mitigated_damage} damage!\033[0m")

    def attack_enemy(self, enemy):
        from random import randint
        damage = randint(1, self.attack)
        print(f"\033[92m{self.name} attacks {enemy.name} for {damage} damage!\033[0m")
        enemy.take_damage(damage)