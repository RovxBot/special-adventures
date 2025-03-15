import os
from text_rpg.ui import display_hud, show_welcome_screen, show_main_menu, display_health_bars, wait_for_player, clear_bottom
from text_rpg.player import Player
from text_rpg.enemy import Enemy
from text_rpg.utils import clear_screen

class Game:
    def __init__(self):
        self.player = self.create_character()

    def create_character(self):
        clear_screen()
        display_hud()
        name = input("Enter your character's name: ").strip()
        return Player(name)

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
        wait_for_player()

    def play(self):
        show_welcome_screen()
        show_main_menu()
        print("Welcome to the Text RPG!")
        while self.player.is_alive():
            while True:
                clear_screen()
                display_health_bars(self.player)
                print("+----------------------+\n"
                      "|  [yes] Explore      |\n"
                      "|  [no]  Quit        |\n"
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
                print("Goodbye!")
                wait_for_player()
                break