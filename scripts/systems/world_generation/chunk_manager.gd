extends Node

class_name ChunkManager

signal chunk_loaded(chunk_coords)
signal chunk_unloaded(chunk_coords)
signal block_changed(world_pos, new_block_id)

const CHUNK_SIZE = Vector3i(16, 128, 16) # x, y, z dimensions
const RENDER_DISTANCE_CHUNKS = 8 # How many chunks in each direction to render from player

var loaded_chunks = {}
var world_generator: WorldGenerator
var voxel_block_system: VoxelBlockSystem
var player_position_chunk: Vector3i = Vector3i(0,0,0)

func _ready():
    world_generator = WorldGenerator.new()
    voxel_block_system = VoxelBlockSystem.new()
    add_child(world_generator)
    add_child(voxel_block_system)

    # Connect to player position updates (assuming GameManager handles player spawning and updates)
    if GameManager.get_player_node():
        _on_player_position_updated(GameManager.get_player_node().global_transform.origin)
    GameManager.player_spawned.connect(_on_player_spawned)

func _on_player_spawned(player_node):
    player_node.position_changed.connect(_on_player_position_updated) # Assuming player has a position_changed signal
    _on_player_position_updated(player_node.global_transform.origin)

func _on_player_position_updated(new_player_world_pos: Vector3):
    var new_chunk_coords = world_to_chunk_coords(new_player_world_pos)
    if new_chunk_coords != player_position_chunk:
        player_position_chunk = new_chunk_coords
        _update_loaded_chunks()

func _update_loaded_chunks():
    var chunks_to_load = {}
    var chunks_to_unload = loaded_chunks.duplicate()

    for x in range(-RENDER_DISTANCE_CHUNKS, RENDER_DISTANCE_CHUNKS + 1):
        for z in range(-RENDER_DISTANCE_CHUNKS, RENDER_DISTANCE_CHUNKS + 1):
            var chunk_coords = Vector3i(player_position_chunk.x + x, 0, player_position_chunk.z + z)
            chunks_to_load[chunk_coords] = true

            if chunks_to_unload.has(chunk_coords):
                chunks_to_unload.erase(chunk_coords)
            else:
                # Load new chunk
                if not loaded_chunks.has(chunk_coords):
                    _load_chunk_data_and_mesh(chunk_coords)

    # Unload chunks that are out of range
    for chunk_coords in chunks_to_unload.keys():
        _unload_chunk(chunk_coords)

func _load_chunk_data_and_mesh(chunk_coords: Vector3i):
    var chunk_data = world_generator.generate_chunk(chunk_coords)
    var chunk_mesh_instance = MeshInstance3D.new()
    chunk_mesh_instance.mesh = voxel_block_system.generate_chunk_mesh(chunk_data, chunk_coords)
    chunk_mesh_instance.name = "Chunk_%s_%s_%s" % [chunk_coords.x, chunk_coords.y, chunk_coords.z]
    chunk_mesh_instance.position = chunk_coords_to_world_pos(chunk_coords)
    add_child(chunk_mesh_instance)
    loaded_chunks[chunk_coords] = { "node": chunk_mesh_instance, "data": chunk_data }
    emit_signal("chunk_loaded", chunk_coords)
    print("Loaded chunk: %s" % chunk_coords)

func _unload_chunk(chunk_coords: Vector3i):
    if loaded_chunks.has(chunk_coords):
        var chunk_info = loaded_chunks[chunk_coords]
        chunk_info.node.queue_free()
        loaded_chunks.erase(chunk_coords)
        emit_signal("chunk_unloaded", chunk_coords)
        print("Unloaded chunk: %s" % chunk_coords)

func get_block(world_pos: Vector3) -> int:
    var chunk_coords = world_to_chunk_coords(world_pos)
    var local_block_coords = world_to_local_block_coords(world_pos)

    if loaded_chunks.has(chunk_coords):
        var chunk_data = loaded_chunks[chunk_coords].data
        return voxel_block_system.get_block_in_chunk_data(chunk_data, local_block_coords.x, local_block_coords.y, local_block_coords.z)
    return VoxelBlockSystem.BlockID.AIR # Return air if chunk not loaded

func set_block(world_pos: Vector3, new_block_id: int):
    var chunk_coords = world_to_chunk_coords(world_pos)
    var local_block_coords = world_to_local_block_coords(world_pos)

    if loaded_chunks.has(chunk_coords):
        var chunk_info = loaded_chunks[chunk_coords]
        var chunk_data = chunk_info.data
        voxel_block_system.set_block_in_chunk_data(chunk_data, local_block_coords.x, local_block_coords.y, local_block_coords.z, new_block_id)
        # Regenerate mesh for the affected chunk
        chunk_info.node.mesh = voxel_block_system.generate_chunk_mesh(chunk_data, chunk_coords)
        emit_signal("block_changed", world_pos, new_block_id)
        print("Set block at %s in chunk %s to %s" % [local_block_coords, chunk_coords, new_block_id])

func world_to_chunk_coords(world_pos: Vector3) -> Vector3i:
    return Vector3i(floor(world_pos.x / CHUNK_SIZE.x), 0, floor(world_pos.z / CHUNK_SIZE.z))

func world_to_local_block_coords(world_pos: Vector3) -> Vector3i:
    var chunk_x = floor(world_pos.x / CHUNK_SIZE.x)
    var chunk_z = floor(world_pos.z / CHUNK_SIZE.z)
    var local_x = int(fmod(world_pos.x, CHUNK_SIZE.x))
    var local_y = int(fmod(world_pos.y, CHUNK_SIZE.y))
    var local_z = int(fmod(world_pos.z, CHUNK_SIZE.z))
    # Handle negative coordinates correctly for modulo
    if local_x < 0: local_x += CHUNK_SIZE.x
    if local_y < 0: local_y += CHUNK_SIZE.y
    if local_z < 0: local_z += CHUNK_SIZE.z
    return Vector3i(local_x, local_y, local_z)

func chunk_coords_to_world_pos(chunk_coords: Vector3i) -> Vector3:
    return Vector3(chunk_coords.x * CHUNK_SIZE.x, 0, chunk_coords.z * CHUNK_SIZE.z)

func _exit_tree():
    # Clean up all loaded chunks when the manager is removed
    for chunk_coords in loaded_chunks.keys():
        _unload_chunk(chunk_coords)
