from text_rpg.game import Game

def main():
    try:
        game = Game()
        while True:
            print("1. Load Game")
            print("2. New Game")
            print("3. Exit")
            choice = input("Enter your choice: ").strip()
            if choice == "1":
                game.load_game()
                break
            elif choice == "2":
                break
            elif choice == "3":
                return
            else:
                print("Invalid choice. Please enter 1, 2, or 3.")
        game.play()
    except OSError:
        print("Input operations are not allowed in this environment. Running in default mode.")
        game = Game("Hero")
        game.play()

if __name__ == "__main__":
    main()