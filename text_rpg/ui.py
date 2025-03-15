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

def display_hud():
    print("+----------------------+\n"
          "|       TEXT RPG       |\n"
          "+----------------------+\n")

def show_welcome_screen():
    print(ASCII_TITLE)
    input()

def show_main_menu():
    clear_screen()
    display_hud()
    while True:
        print("+----------------------+\n"
              "|  [1] Start New Game |\n"
              "|  [2] Quit           |\n"
              "+----------------------+\n")
        choice = input("Choose an option: ").strip()
        if choice == "1":
            break
        elif choice == "2":
            print("Goodbye!")
            exit()
        else:
            print("Invalid choice. Try again.")

def display_health_bars(player, enemy=None):
    player_health_bar = f"Player: {player.name} | Health: {'█' * (player.health // 10)}"
    print(player_health_bar)
    if enemy:
        enemy_health_bar = f"Enemy: {enemy.name} | Health: {'█' * (enemy.health // 10)}"
        print(enemy_health_bar)
    print("+----------------------+\n")