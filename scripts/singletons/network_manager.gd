extends Node

class_name NetworkManager

signal player_connected(id)
signal player_disconnected(id)
signal game_state_received(state_data)
signal player_moved(id, position, rotation)

const DEFAULT_PORT = 9000
const MAX_PLAYERS = 10

var peer: ENetMultiplayerPeer
var is_server = false

func _ready():
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func create_server(port: int = DEFAULT_PORT) -> Error:
    peer = ENetMultiplayerPeer.new()
    var err = peer.create_server(port, MAX_PLAYERS)
    if err == OK:
        multiplayer.multiplayer_peer = peer
        is_server = true
        print("Server created on port: %s" % port)
        return OK
    else:
        print("Error creating server: %s" % err)
        return err

func join_server(ip_address: String, port: int = DEFAULT_PORT) -> Error:
    peer = ENetMultiplayerPeer.new()
    var err = peer.create_client(ip_address, port)
    if err == OK:
        multiplayer.multiplayer_peer = peer
        is_server = false
        print("Attempting to connect to server at %s:%s" % [ip_address, port])
        return OK
    else:
        print("Error creating client: %s" % err)
        return err

func disconnect_from_server():
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = null
        is_server = false
        print("Disconnected from server.")

func _on_peer_connected(id: int):
    print("Player connected: %s" % id)
    emit_signal("player_connected", id)
    if is_server:
        # Send initial game state to new player
        # Example: rpc_id(id, "send_initial_game_state", get_game_state())
        pass

func _on_peer_disconnected(id: int):
    print("Player disconnected: %s" % id)
    emit_signal("player_disconnected", id)

func _on_connected_to_server():
    print("Successfully connected to server.")

func _on_connection_failed():
    print("Failed to connect to server.")

func _on_server_disconnected():
    print("Server disconnected.")
    disconnect_from_server()

@rpc("any_peer", "call_local")
func send_player_movement(position: Vector3, rotation: Vector3):
    # This function will be called by clients to send their movement to the server
    # On the server, it will then broadcast to other clients
    if is_server:
        # Server receives movement from client, then broadcasts to others
        rpc("receive_player_movement", multiplayer.get_remote_sender_id(), position, rotation)
    else:
        # Client sends movement to server
        rpc_id(1, "send_player_movement", position, rotation) # 1 is server ID

@rpc("any_peer")
func receive_player_movement(id: int, position: Vector3, rotation: Vector3):
    # This function is called by the server to update all clients about player movement
    # Or by clients to receive updates from server
    emit_signal("player_moved", id, position, rotation)

@rpc("any_peer", "call_local")
func send_game_state(state_data: Dictionary):
    # Example for sending full game state (e.g., when a new player joins)
    emit_signal("game_state_received", state_data)

func get_game_state() -> Dictionary:
    # Placeholder for actual game state retrieval
    return {"world_seed": 12345, "players": {}}
