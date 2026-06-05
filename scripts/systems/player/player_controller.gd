extends CharacterBody3D

class_name PlayerController

signal position_changed(new_position)

@export var move_speed = 5.0
@export var sprint_speed_multiplier = 1.5
@export var jump_velocity = 8.0
@export var mouse_sensitivity = 0.002

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D
var head: Node3D

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    camera = $Head/Camera3D
    head = $Head

func _physics_process(delta):
    _handle_movement(delta)
    _handle_camera_rotation(delta)
    emit_signal("position_changed", global_transform.origin)

func _input(event):
    if event is InputEventMouseMotion:
        _rotate_camera(event)
    if event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _handle_movement(delta):
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if is_on_floor():
        if Input.is_action_just_pressed("jump"):
            velocity.y = jump_velocity
    else:
        velocity.y -= gravity * delta

    var current_speed = move_speed
    if Input.is_action_pressed("sprint"):
        current_speed *= sprint_speed_multiplier

    if direction:
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
    else:
        velocity.x = move_and_slide().x
        velocity.z = move_and_slide().z

    move_and_slide()

func _handle_camera_rotation(delta):
    # This is handled by _input for mouse motion
    pass

func _rotate_camera(event: InputEventMouseMotion):
    rotate_y(-event.relative.x * mouse_sensitivity)
    head.rotate_x(-event.relative.y * mouse_sensitivity)
    head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _on_interact():
    # Raycast to detect block for breaking/placing
    var ray_length = 5.0
    var space_state = get_world_3d().direct_space_state
    var camera_origin = camera.global_transform.origin
    var camera_forward = -camera.global_transform.basis.z
    var query = PhysicsRayQueryParameters3D.create(camera_origin, camera_origin + camera_forward * ray_length)
    var result = space_state.intersect_ray(query)

    if result:
        var hit_pos = result.position
        var hit_normal = result.normal
        var block_pos = Vector3(floor(hit_pos.x), floor(hit_pos.y), floor(hit_pos.z))

        if Input.is_action_just_pressed("break_block"):
            # Assuming ChunkManager is a singleton or accessible
            if ChunkManager:
                ChunkManager.set_block(block_pos, VoxelBlockSystem.BlockID.AIR)
        elif Input.is_action_just_pressed("place_block"):
            var place_pos = block_pos + hit_normal
            # Assuming current_item_in_hand gives a block ID
            var block_to_place = VoxelBlockSystem.BlockID.DIRT # Placeholder
            if ChunkManager:
                ChunkManager.set_block(place_pos, block_to_place)

func _get_current_item_in_hand() -> int:
    # Placeholder for getting item from inventory/hotbar
    return VoxelBlockSystem.BlockID.STONE # Example: always place stone
