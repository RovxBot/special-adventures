from text_rpg.character import Character

class Player(Character):
    def __init__(self, name="Hero", agi=10, str=10, amour=10, int=10, stam=10):
        super().__init__(name, health=100, attack=15, defense=5, agi=agi, str=str, amour=amour, int=int, stam=stam)

    def choose_action(self):
        print("+----------------------+\n"
              "|  [1] Attack        |\n"
              "|  [2] Run           |\n"
              "+----------------------+\n")
        while True:
            choice = input("Choose an action: ").strip()
            if choice in ["1", "2"]:
                return choice
            print("Invalid choice. Try again.")