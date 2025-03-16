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

CHARACTER_CREATION_TITLE = """
  ____ _               _              ____ _                 
 / ___| |__   ___  ___| | _____ _ __ / ___| | ___  __ _ _ __  
| |   | '_ \\ / _ \\/ __| |/ / _ \\ '__| |   | |/ _ \\/ _` | '_ \\ 
| |___| | | |  __/ (__|   <  __/ |  | |___| |  __/ (_| | | | |
 \\____|_| |_|\\___|\\___|_|\\_\\___|_|   \\____|_|\\___|\\__,_|_| |_|
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

def show_welcome_screen(root, frame):
    for widget in frame.winfo_children():
        widget.destroy()
    label = tk.Label(frame, text=ASCII_TITLE, font=("Courier", 12))
    label.pack(pady=20)
    button = tk.Button(frame, text="Start", command=lambda: show_main_menu(root, frame))
    button.pack(pady=10)

def show_main_menu(root, frame):
    for widget in frame.winfo_children():
        widget.destroy()
    display_hud()
    label = tk.Label(frame, text="Main Menu", font=("Courier", 12))
    label.pack(pady=20)
    start_button = tk.Button(frame, text="Start New Game", command=lambda: root.quit())
    start_button.pack(pady=10)
    quit_button = tk.Button(frame, text="Quit", command=root.quit)
    quit_button.pack(pady=10)

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

def create_character_screen(root, frame):
    for widget in frame.winfo_children():
        widget.destroy()
    
    title_label = tk.Label(frame, text=CHARACTER_CREATION_TITLE, font=("Courier", 12))
    title_label.pack(pady=10)
    
    name_label = tk.Label(frame, text="Enter your character's name:", font=("Courier", 12))
    name_label.pack(pady=10)
    name_entry = tk.Entry(frame, font=("Courier", 12))
    name_entry.pack(pady=10)

    stats = {"agi": 0, "str": 0, "int": 0, "stam": 0}
    points = 10
    points_label = tk.Label(frame, text=f"Points left: {points}", font=("Courier", 12))
    points_label.pack(pady=10)

    def update_points():
        nonlocal points
        points = 10 - sum(stats.values())
        points_label.config(text=f"Points left: {points}")

    def create_stat_row(stat):
        frame_stat = tk.Frame(frame)
        frame_stat.pack(pady=5)
        label = tk.Label(frame_stat, text=f"{stat.capitalize()}: ", font=("Courier", 12))
        label.pack(side=tk.LEFT)
        entry = tk.Entry(frame_stat, font=("Courier", 12), width=5)
        entry.pack(side=tk.LEFT)
        entry.insert(0, "0")

        def on_change(*args):
            try:
                value = int(entry.get())
                if value <= points:
                    stats[stat] = value
                    update_points()
                else:
                    entry.delete(0, tk.END)
                    entry.insert(0, str(stats[stat]))
            except ValueError:
                entry.delete(0, tk.END)
                entry.insert(0, str(stats[stat]))

        entry.bind("<KeyRelease>", on_change)

    for stat in stats:
        create_stat_row(stat)

    def on_submit():
        root.quit()

    submit_button = tk.Button(frame, text="Submit", command=on_submit)
    submit_button.pack(pady=20)
    root.mainloop()

    return name_entry.get(), stats
``` 