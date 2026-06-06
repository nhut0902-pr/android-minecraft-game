extends Node

class_name VoxelBlockSystem

# Define block IDs and their properties
enum BlockID { AIR, GRASS, DIRT, STONE, SAND, WATER, SNOW, ICE, WOOD, LEAVES, GLASS, BRICK, OBSIDIAN, ORE }

# Block properties dictionary (e.g., texture, transparency, collidable)
var block_properties = {
    BlockID.AIR: { "name": "Air", "transparent": true, "collidable": false, "texture": "" },
    BlockID.GRASS: { "name": "Grass", "transparent": false, "collidable": true, "texture": "res://assets/textures/grass.png" },
    BlockID.DIRT: { "name": "Dirt", "transparent": false, "collidable": true, "texture": "res://assets/textures/dirt.png" },
    BlockID.STONE: { "name": "Stone", "transparent": false, "collidable": true, "texture": "res://assets/textures/stone.png" },
    BlockID.SAND: { "name": "Sand", "transparent": false, "collidable": true, "texture": "res://assets/textures/sand.png" },
    BlockID.WATER: { "name": "Water", "transparent": true, "collidable": false, "texture": "res://assets/textures/water.png" },
    BlockID.SNOW: { "name": "Snow", "transparent": false, "collidable": true, "texture": "res://assets/textures/snow.png" },
    BlockID.ICE: { "name": "Ice", "transparent": true, "collidable": true, "texture": "res://assets/textures/ice.png" },
    BlockID.WOOD: { "name": "Wood", "transparent": false, "collidable": true, "texture": "res://assets/textures/wood.png" },
    BlockID.LEAVES: { "name": "Leaves", "transparent": true, "collidable": false, "texture": "res://assets/textures/leaves.png" },
    BlockID.GLASS: { "name": "Glass", "transparent": true, "collidable": true, "texture": "res://assets/textures/glass.png" },
    BlockID.BRICK: { "name": "Brick", "transparent": false, "collidable": true, "texture": "res://assets/textures/brick.png" },
    BlockID.OBSIDIAN: { "name": "Obsidian", "transparent": false, "collidable": true, "texture": "res://assets/textures/obsidian.png" },
    BlockID.ORE: { "name": "Ore", "transparent": false, "collidable": true, "texture": "res://assets/textures/ore.png" },
}

# Directions for face culling
const FACES = {
    "+x": Vector3i(1, 0, 0),
    "-x": Vector3i(-1, 0, 0),
    "+y": Vector3i(0, 1, 0),
    "-y": Vector3i(0, -1, 0),
    "+z": Vector3i(0, 0, 1),
    "-z": Vector3i(0, 0, -1),
}

# Vertices for a unit cube (centered at origin)
const CUBE_VERTICES = [
    Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5), # Front (+Z)
    Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5), # Back (-Z)
    Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5), # Right (+X)
    Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5), # Left (-X)
    Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5), # Top (+Y)
    Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5)  # Bottom (-Y)
]

# Indices for a unit cube (two triangles per face)
const CUBE_INDICES = [
    0, 1, 2, 2, 3, 0, # Front
    4, 5, 6, 6, 7, 4, # Back
    8, 9, 10, 10, 11, 8, # Right
    12, 13, 14, 14, 15, 12, # Left
    16, 17, 18, 18, 19, 16, # Top
    20, 21, 22, 22, 23, 20  # Bottom
]

# Normals for each face
const CUBE_NORMALS = [
    Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), # Front
    Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), # Back
    Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), # Right
    Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), # Left
    Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), # Top
    Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0)  # Bottom
]

# UVs for each face (assuming a single texture atlas or individual textures)
const CUBE_UVS = [
    Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # Front
    Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), # Back
    Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # Right
    Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0), # Left
    Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # Top
    Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)  # Bottom
]

func get_block_name(block_id: int) -> String:
    if block_properties.has(block_id):
        return block_properties[block_id]["name"]
    return "Unknown"

func is_block_transparent(block_id: int) -> bool:
    if block_properties.has(block_id):
        return block_properties[block_id]["transparent"]
    return false

func is_block_collidable(block_id: int) -> bool:
    if block_properties.has(block_id):
        return block_properties[block_id]["collidable"]
    return false

func get_block_texture_path(block_id: int) -> String:
    if block_properties.has(block_id) and block_properties[block_id].has("texture"):
        return block_properties[block_id]["texture"]
    return "" # No texture or unknown block

# Function to generate mesh for a chunk using Greedy Meshing and Face Culling
func generate_chunk_mesh(chunk_data: Array, chunk_coords: Vector3i) -> ArrayMesh:
    var mesh = ArrayMesh.new()
    var arrays = []
    arrays.resize(ArrayMesh.ARRAY_MAX)

    var vertices = PackedVector3Array()
    var uvs = PackedVector2Array()
    var normals = PackedVector3Array()
    var indices = PackedInt32Array()

    var current_vertex_offset = 0

    # Iterate through each block in the chunk
    for z in range(ChunkManager.CHUNK_SIZE.z):
        for y in range(ChunkManager.CHUNK_SIZE.y):
            for x in range(ChunkManager.CHUNK_SIZE.x):
                var block_id = get_block_in_chunk_data(chunk_data, x, y, z)

                if block_id != BlockID.AIR and not is_block_transparent(block_id):
                    # Check each face of the block
                    for face_idx in range(6): # 6 faces of a cube
                        var normal_vec = CUBE_NORMALS[face_idx * 4] # Get normal for the face
                        var neighbor_offset = Vector3i(normal_vec.x, normal_vec.y, normal_vec.z)

                        if should_render_face(chunk_data, x, y, z, neighbor_offset):
                            # Add vertices, UVs, normals for this face
                            var base_vertex_idx = face_idx * 4
                            var base_index_idx = face_idx * 6

                            for i in range(4):
                                vertices.append(CUBE_VERTICES[base_vertex_idx + i] + Vector3(x, y, z))
                                uvs.append(CUBE_UVS[base_vertex_idx + i])
                                normals.append(CUBE_NORMALS[base_vertex_idx + i])

                            for i in range(6):
                                indices.append(CUBE_INDICES[base_index_idx + i] + current_vertex_offset)
                            current_vertex_offset += 4 # 4 vertices per face

    arrays[ArrayMesh.ARRAY_VERTEX] = vertices
    arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
    arrays[ArrayMesh.ARRAY_NORMAL] = normals
    arrays[ArrayMesh.ARRAY_INDEX] = indices

    if vertices.size() > 0:
        mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
        # Assign a material (e.g., a SpatialMaterial with a texture atlas)
        var material = StandardMaterial3D.new()
        material.albedo_texture = load("res://assets/textures/dirt.png") # Use a default texture for now. A texture atlas is recommended for performance.
        material.cull_mode = BaseMaterial3D.CULL_BACK
        mesh.surface_set_material(0, material)

    return mesh

# Helper function to check if a block face should be rendered (for face culling)
func should_render_face(chunk_data: Array, x: int, y: int, z: int, normal: Vector3i) -> bool:
    var neighbor_x = x + normal.x
    var neighbor_y = y + normal.y
    var neighbor_z = z + normal.z

    # Check if neighbor is outside chunk boundaries
    if neighbor_x < 0 or neighbor_x >= ChunkManager.CHUNK_SIZE.x or \
       neighbor_y < 0 or neighbor_y >= ChunkManager.CHUNK_SIZE.y or \
       neighbor_z < 0 or neighbor_z >= ChunkManager.CHUNK_SIZE.z:
        # If neighbor is outside, assume it's an air block (or another chunk's block) and render the face
        return true

    var neighbor_block_id = get_block_in_chunk_data(chunk_data, neighbor_x, neighbor_y, neighbor_z)
    return is_block_transparent(neighbor_block_id) # Render face if neighbor is transparent

func get_block_in_chunk_data(chunk_data: Array, x: int, y: int, z: int) -> int:
    if x < 0 or x >= ChunkManager.CHUNK_SIZE.x or y < 0 or y >= ChunkManager.CHUNK_SIZE.y or z < 0 or z >= ChunkManager.CHUNK_SIZE.z:
        return BlockID.AIR # Out of bounds is air
    var index = x + ChunkManager.CHUNK_SIZE.x * (y + ChunkManager.CHUNK_SIZE.y * z)
    return chunk_data[index]

func set_block_in_chunk_data(chunk_data: Array, x: int, y: int, z: int, block_id: int):
    if x < 0 or x >= ChunkManager.CHUNK_SIZE.x or y < 0 or y >= ChunkManager.CHUNK_SIZE.y or z < 0 or z >= ChunkManager.CHUNK_SIZE.z:
        return
    var index = x + ChunkManager.CHUNK_SIZE.x * (y + ChunkManager.CHUNK_SIZE.y * z)
    chunk_data[index] = block_id
