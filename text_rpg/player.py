from text_rpg.character import Character

class Player(Character):
    def __init__(self, name="Hero", agi=10, str=10, int=10, stam=10):
        super().__init__(name, health=100, attack=15, defense=5, agi=agi, str=str, amour=5, int=int, stam=stam)
        self.level = 1
        self.experience = 0
        self.inventory = []

    def gain_experience(self, amount):
        self.experience += amount
        if self.experience >= self.level * 10:
            self.level_up()

    def level_up(self):
        self.level += 1
        self.experience = 0
        self.health += 10
        self.attack += 2
        self.defense += 2
        print(f"{self.name} leveled up to level {self.level}!")

    def add_to_inventory(self, item):
        self.inventory.append(item)
        print(f"{item} added to inventory.")

    def choose_action(self):
        print("+----------------------+\n"
              "|  [1] Attack          |\n"
              "|  [2] Run             |\n"
              "+----------------------+\n")
        while True:
            choice = input("Choose an action: ").strip()
            if choice in ["1", "2"]:
                return choice
            print("Invalid choice. Try again.")