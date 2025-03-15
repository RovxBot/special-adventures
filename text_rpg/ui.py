import os

ASCII_TITLE = """
  _____     _     _    ____  ____  
 |_   _| __(_) __| |  |  _ \\|  _ \\ 
   | || '__| |/ _` |  | |_) | |_) |
   | || |  | | (_| |  |  __/|  __/ 
   |_||_|  |_|\\__,_|  |_|   |_|    

      TEXT-BASED RPG

  [ Press Enter to start ]
"""

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def clear_bottom():
    print("\033[H\033[J", end="")

def display_hud():
    print("+--------------------------+\n"
          "|        TEXT RPG          |\n"
          "+--------------------------+\n")

def show_welcome_screen():
    print(ASCII_TITLE)
    input()

def show_main_menu():
    clear_screen()
    display_hud()
    while True:
        print("+--------------------------+\n"
              "|  [1] Start New Game      |\n"
              "|  [2] Quit                |\n"
              "+--------------------------+\n")
        choice = input("Choose an option: ").strip()
        if choice == "1":
            break
        elif choice == "2":
            print("Goodbye!")
            exit()
        else:
            print("Invalid choice. Try again.")

def display_health_bars(player, enemy=None):
    def health_bar(health, max_health):
        bar_length = 20
        health_ratio = health / max_health
        bar = '█' * int(bar_length * health_ratio)
        return f"\033[92m{bar.ljust(bar_length)}\033[0m"

    player_health_bar = f"Player: {player.name} | Health: {health_bar(player.health, 100)}"
    print(player_health_bar)
    if enemy:
        enemy_health_bar = f"Enemy: {enemy.name} | Health: {health_bar(enemy.health, 30)}"
        print(enemy_health_bar)
    print("+--------------------------+\n")

def wait_for_player():
    input("Press Enter to continue...")