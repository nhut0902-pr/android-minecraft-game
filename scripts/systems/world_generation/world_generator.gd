extends Node

class_name WorldGenerator

const CHUNK_SIZE = Vector3i(16, 128, 16)
const NOISE_SCALE_TERRAIN = 0.015
const NOISE_SCALE_BIOME = 0.005
const TERRAIN_HEIGHT_SCALE = 40
const SEA_LEVEL = 60

var noise_terrain: FastNoiseLite
var noise_biome: FastNoiseLite

func _init():
    noise_terrain = FastNoiseLite.new()
    noise_terrain.seed = randi() # Random seed for varied worlds
    noise_terrain.noise_type = FastNoiseLite.TYPE_PERLIN
    noise_terrain.frequency = NOISE_SCALE_TERRAIN
    noise_terrain.fractal_octaves = 4
    noise_terrain.fractal_lacunarity = 2.0
    noise_terrain.fractal_gain = 0.5

    noise_biome = FastNoiseLite.new()
    noise_biome.seed = randi() + 1 # Different seed for biome noise
    noise_biome.noise_type = FastNoiseLite.TYPE_SIMPLEX
    noise_biome.frequency = NOISE_SCALE_BIOME

func generate_chunk(chunk_coords: Vector3i) -> Array:
    var chunk_data = []
    chunk_data.resize(CHUNK_SIZE.x * CHUNK_SIZE.y * CHUNK_SIZE.z)

    for x in range(CHUNK_SIZE.x):
        for z in range(CHUNK_SIZE.z):
            var world_x = chunk_coords.x * CHUNK_SIZE.x + x
            var world_z = chunk_coords.z * CHUNK_SIZE.z + z

            var biome_value = noise_biome.get_noise_2d(world_x, world_z)
            var biome_type = _get_biome_from_noise(biome_value)

            var terrain_height = int(noise_terrain.get_noise_2d(world_x, world_z) * TERRAIN_HEIGHT_SCALE + SEA_LEVEL)

            for y in range(CHUNK_SIZE.y):
                var block_id = VoxelBlockSystem.BlockID.AIR # Default to air

                if y < terrain_height:
                    block_id = _get_block_for_height(y, terrain_height, biome_type)
                elif y <= SEA_LEVEL and block_id == VoxelBlockSystem.BlockID.AIR: # Fill water below sea level
                    block_id = VoxelBlockSystem.BlockID.WATER

                _set_block_in_chunk_data(chunk_data, x, y, z, block_id)
    return chunk_data

func _get_biome_from_noise(noise_value: float) -> String:
    # Simple biome distribution based on noise value
    if noise_value < -0.6:
        return "snow"
    elif noise_value < -0.3:
        return "desert"
    elif noise_value < 0.2:
        return "plains"
    elif noise_value < 0.5:
        return "forest"
    else:
        return "mountains"

func _get_block_for_height(y: int, terrain_height: int, biome_type: String) -> int:
    if y == terrain_height - 1:
        match biome_type:
            "plains", "forest": return VoxelBlockSystem.BlockID.GRASS
            "desert": return VoxelBlockSystem.BlockID.SAND
            "snow": return VoxelBlockSystem.BlockID.SNOW
            _:
                return VoxelBlockSystem.BlockID.DIRT
    elif y >= terrain_height - 4:
        return VoxelBlockSystem.BlockID.DIRT
    else:
        return VoxelBlockSystem.BlockID.STONE

func _set_block_in_chunk_data(chunk_data: Array, x: int, y: int, z: int, block_id: int):
    var index = x + CHUNK_SIZE.x * (y + CHUNK_SIZE.y * z)
    if index >= 0 and index < chunk_data.size():
        chunk_data[index] = block_id

func get_block_in_chunk_data(chunk_data: Array, x: int, y: int, z: int) -> int:
    if x < 0 or x >= CHUNK_SIZE.x or y < 0 or y >= CHUNK_SIZE.y or z < 0 or z >= CHUNK_SIZE.z:
        return VoxelBlockSystem.BlockID.AIR # Out of bounds is air
    var index = x + CHUNK_SIZE.x * (y + CHUNK_SIZE.y * z)
    return chunk_data[index]
