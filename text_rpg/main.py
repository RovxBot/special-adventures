from text_rpg.game import Game

def main():
    try:
        game = Game()
        game.play()
    except OSError:
        print("Input operations are not allowed in this environment. Running in default mode.")
        game = Game("Hero")
        game.play()

if __name__ == "__main__":
    main()