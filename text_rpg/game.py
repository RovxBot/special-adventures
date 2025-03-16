import os
import json
import tkinter as tk
from text_rpg.ui import display_hud, show_welcome_screen, show_main_menu, display_health_bars, wait_for_player, clear_bottom, set_window_size, create_character_screen
from text_rpg.player import Player
from text_rpg.enemy import Enemy
from text_rpg.utils import clear_screen

class Game:
    def __init__(self):
        set_window_size()
        self.root = tk.Tk()
        self.root.title("Text RPG")
        self.frame = tk.Frame(self.root)
        self.frame.pack()
        self.player = self.create_character()

    def create_character(self):
        clear_screen()
        display_hud()
        name, stats = create_character_screen(self.root, self.frame)
        return Player(name, agi=stats["agi"], str=stats["str"], int=stats["int"], stam=stats["stam"])

    def save_game(self):
        game_state = {
            "player": {
                "name": self.player.name,
                "level": self.player.level,
                "experience": self.player.experience,
                "health": self.player.health,
                "attack": self.player.attack,
                "defense": self.player.defense,
                "agi": self.player.agi,
                "str": self.player.str,
                "amour": self.player.amour,
                "int": self.player.int,
                "stam": self.player.stam,
                "inventory": self.player.inventory
            }
        }
        with open("savegame.json", "w") as save_file:
            json.dump(game_state, save_file)
        print("Game saved successfully.")

    def load_game(self):
        try:
            with open("savegame.json", "r") as save_file:
                game_state = json.load(save_file)
                player_state = game_state["player"]
                self.player = Player(
                    name=player_state["name"],
                    agi=player_state["agi"],
                    str=player_state["str"],
                    int=player_state["int"],
                    stam=player_state["stam"]
                )
                self.player.level = player_state["level"]
                self.player.experience = player_state["experience"]
                self.player.health = player_state["health"]
                self.player.attack = player_state["attack"]
                self.player.defense = player_state["defense"]
                self.player.inventory = player_state["inventory"]
                print("Game loaded successfully.")
        except FileNotFoundError:
            print("No saved game found. Starting a new game.")

    def battle(self, enemy):
        print(f"A wild {enemy.name} appears!")
        while self.player.is_alive() and enemy.is_alive():
            clear_screen()
            display_health_bars(self.player, enemy)
            choice = self.player.choose_action()
            clear_bottom()
            if choice == "1":
                self.player.attack_enemy(enemy)
                if enemy.is_alive():
                    enemy.attack_enemy(self.player)
            elif choice == "2":
                print("You run away!")
                wait_for_player()
                break
            wait_for_player()
            clear_bottom()
        if not self.player.is_alive():
            print("You have been defeated...")
        elif not enemy.is_alive():
            print(f"You have defeated {enemy.name}!")
            self.player.gain_experience(10)
            self.player.add_to_inventory("Loot from " + enemy.name)
        wait_for_player()

    def play(self):
        show_welcome_screen(self.root, self.frame)
        while True:
            show_main_menu(self.root, self.frame)
            game_choice = input("Enter your choice: ").strip().lower()
            if game_choice == "start":
                print("Welcome to the Text RPG!")
                while self.player.is_alive():
                    while True:
                        clear_screen()
                        display_health_bars(self.player)
                        print("+----------------------+\n"
                              "|  [yes] Explore       |\n"
                              "|  [no]  Quit          |\n"
                              "+----------------------+\n")
                        action = input("Do you want to explore? ").strip().lower()
                        clear_bottom()
                        if action in ["yes", "no"]:
                            break
                        print("Invalid choice. Enter 'yes' or 'no'.")
                        wait_for_player()
                    if action == "yes":
                        enemy = Enemy("Goblin", health=30, attack=10, defense=3)
                        self.battle(enemy)
                    else:
                        self.save_game()
                        print("Goodbye!")
                        wait_for_player()
                        break
            elif game_choice == "quit":
                print("Goodbye!")
                wait_for_player()
                break
            else:
                print("Invalid choice. Please enter 'start' or 'quit'.")
                wait_for_player()