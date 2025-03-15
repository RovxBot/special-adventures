from text_rpg.character import Character

class Player(Character):
    def __init__(self, name="Hero"):
        super().__init__(name, health=100, attack=15, defense=5)

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