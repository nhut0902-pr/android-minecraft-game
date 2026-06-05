extends Node

class_name GameManager

signal game_state_changed(new_state)
signal player_spawned(player_node)

enum GameState { LOADING, MAIN_MENU, IN_GAME, PAUSED, GAME_OVER }

var current_game_state = GameState.LOADING
var player_instance = null

func _ready():
    # Ensure this is a singleton (AutoLoad)
    if not Engine.is_editor_hint():
        set_process(true)
        set_physics_process(true)
        change_game_state(GameState.MAIN_MENU)

func change_game_state(new_state: GameState):
    if current_game_state == new_state:
        return

    current_game_state = new_state
    emit_signal("game_state_changed", new_state)
    print("Game State Changed to: %s" % GameState.keys()[new_state])

    match new_state:
        GameState.LOADING:
            # Show loading screen
            pass
        GameState.MAIN_MENU:
            # Load main menu scene
            get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
            pass
        GameState.IN_GAME:
            # Load game world scene
            get_tree().change_scene_to_file("res://scenes/game_world/game_world.tscn")
            pass
        GameState.PAUSED:
            # Pause game, show pause menu
            get_tree().paused = true
            pass
        GameState.GAME_OVER:
            # Show game over screen
            pass

func spawn_player(player_scene: PackedScene, spawn_position: Vector3):
    if player_instance:
        player_instance.queue_free()

    player_instance = player_scene.instantiate()
    get_tree().current_scene.add_child(player_instance)
    player_instance.global_transform.origin = spawn_position
    emit_signal("player_spawned", player_instance)
    print("Player spawned at: %s" % spawn_position)

func get_player_node() -> Node:
    return player_instance

func pause_game():
    if current_game_state == GameState.IN_GAME:
        change_game_state(GameState.PAUSED)

func resume_game():
    if current_game_state == GameState.PAUSED:
        get_tree().paused = false
        change_game_state(GameState.IN_GAME)

func quit_game():
    get_tree().quit()
