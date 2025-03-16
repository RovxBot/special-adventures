import os
import tkinter as tk
from tkinter import messagebox

ASCII_TITLE = """
  _____     _     _    ____  ____  
 |_   _| __(_) __| |  |  _ \\|  _ \\ 
   | || '__| |/ _` |  | |_) | |_) |
   | || |  | | (_| |  |  __/|  __/ 
   |_||_|  |_|\\__,_|  |_|   |_|    

      TEXT-BASED RPG

  [ Press Enter to start ]
"""

def set_window_size():
    os.system('mode con: cols=80 lines=24' if os.name == 'nt' else 'printf "\e[8;24;80t"')

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def clear_bottom():
    print("\033[H\033[J", end="")

def display_hud():
    print("+--------------------------+\n"
          "|        TEXT RPG          |\n"
          "+--------------------------+\n")

def show_welcome_screen():
    root = tk.Tk()
    root.title("Text RPG")
    label = tk.Label(root, text=ASCII_TITLE, font=("Courier", 12))
    label.pack(pady=20)
    button = tk.Button(root, text="Start", command=root.destroy)
    button.pack(pady=10)
    root.mainloop()

def show_main_menu():
    def start_game():
        root.destroy()
        global game_choice
        game_choice = "start"

    def quit_game():
        root.destroy()
        global game_choice
        game_choice = "quit"

    root = tk.Tk()
    root.title("Main Menu")
    display_hud()
    label = tk.Label(root, text="Main Menu", font=("Courier", 12))
    label.pack(pady=20)
    start_button = tk.Button(root, text="Start New Game", command=start_game)
    start_button.pack(pady=10)
    quit_button = tk.Button(root, text="Quit", command=quit_game)
    quit_button.pack(pady=10)
    root.mainloop()

def display_health_bars(player, enemy=None):
    def health_bar(health, max_health):
        bar_length = 20
        health_ratio = health / max_health
        bar = '█' * int(bar_length * health_ratio)
        return f"\033[92m{bar.ljust(bar_length)}\033[0m"

    player_health_bar = f"Player: {player.name} | Health: {health_bar(player.health, 100)}"
    print(player_health_bar)
    print(f"Agi: {player.agi} | Str: {player.str} | Amour: {player.amour} | Int: {player.int} | Stam: {player.stam}")
    if enemy:
        enemy_health_bar = f"Enemy: {enemy.name} | Health: {health_bar(enemy.health, 30)}"
        print(enemy_health_bar)
    print("+--------------------------+\n")

def wait_for_player():
    messagebox.showinfo("Continue", "Press OK to continue...")