extends Node

class_name InventoryManager

signal inventory_updated
signal hotbar_updated

const INVENTORY_SIZE = 27 # 3 rows of 9
const HOTBAR_SIZE = 9

var inventory_slots = [] # Array of Dictionaries {item_id: int, quantity: int}
var hotbar_slots = []    # Array of Dictionaries {item_id: int, quantity: int}
var selected_hotbar_slot_index = 0

func _ready():
    _initialize_inventory()

func _initialize_inventory():
    inventory_slots.resize(INVENTORY_SIZE)
    for i in range(INVENTORY_SIZE):
        inventory_slots[i] = { "item_id": VoxelBlockSystem.BlockID.AIR, "quantity": 0 }

    hotbar_slots.resize(HOTBAR_SIZE)
    for i in range(HOTBAR_SIZE):
        hotbar_slots[i] = { "item_id": VoxelBlockSystem.BlockID.AIR, "quantity": 0 }

    # Example: Add some starting items
    add_item(VoxelBlockSystem.BlockID.GRASS, 10)
    add_item(VoxelBlockSystem.BlockID.DIRT, 20)
    add_item(VoxelBlockSystem.BlockID.STONE, 5)
    add_item(VoxelBlockSystem.BlockID.WOOD, 15)
    add_item(VoxelBlockSystem.BlockID.GLASS, 3)

func add_item(item_id: int, quantity: int) -> bool:
    if quantity <= 0:
        return false

    var remaining_quantity = quantity

    # Try to stack in hotbar first
    for i in range(HOTBAR_SIZE):
        if hotbar_slots[i].item_id == item_id and hotbar_slots[i].quantity < get_max_stack_size(item_id):
            var space_left = get_max_stack_size(item_id) - hotbar_slots[i].quantity
            var amount_to_add = min(remaining_quantity, space_left)
            hotbar_slots[i].quantity += amount_to_add
            remaining_quantity -= amount_to_add
            emit_signal("hotbar_updated")
            if remaining_quantity == 0:
                return true

    # Then try to stack in main inventory
    for i in range(INVENTORY_SIZE):
        if inventory_slots[i].item_id == item_id and inventory_slots[i].quantity < get_max_stack_size(item_id):
            var space_left = get_max_stack_size(item_id) - inventory_slots[i].quantity
            var amount_to_add = min(remaining_quantity, space_left)
            inventory_slots[i].quantity += amount_to_add
            remaining_quantity -= amount_to_add
            emit_signal("inventory_updated")
            if remaining_quantity == 0:
                return true

    # Add to empty slot in hotbar
    for i in range(HOTBAR_SIZE):
        if hotbar_slots[i].item_id == VoxelBlockSystem.BlockID.AIR:
            hotbar_slots[i].item_id = item_id
            hotbar_slots[i].quantity = remaining_quantity
            emit_signal("hotbar_updated")
            return true

    # Add to empty slot in main inventory
    for i in range(INVENTORY_SIZE):
        if inventory_slots[i].item_id == VoxelBlockSystem.BlockID.AIR:
            inventory_slots[i].item_id = item_id
            inventory_slots[i].quantity = remaining_quantity
            emit_signal("inventory_updated")
            return true

    return false # Inventory full

func remove_item(item_id: int, quantity: int) -> bool:
    if quantity <= 0:
        return false

    var removed_count = 0

    # Remove from hotbar first
    for i in range(HOTBAR_SIZE):
        if hotbar_slots[i].item_id == item_id:
            var amount_to_remove = min(quantity - removed_count, hotbar_slots[i].quantity)
            hotbar_slots[i].quantity -= amount_to_remove
            removed_count += amount_to_remove
            if hotbar_slots[i].quantity == 0:
                hotbar_slots[i].item_id = VoxelBlockSystem.BlockID.AIR
            emit_signal("hotbar_updated")
            if removed_count == quantity:
                return true

    # Then remove from main inventory
    for i in range(INVENTORY_SIZE):
        if inventory_slots[i].item_id == item_id:
            var amount_to_remove = min(quantity - removed_count, inventory_slots[i].quantity)
            inventory_slots[i].quantity -= amount_to_remove
            removed_count += amount_to_remove
            if inventory_slots[i].quantity == 0:
                inventory_slots[i].item_id = VoxelBlockSystem.BlockID.AIR
            emit_signal("inventory_updated")
            if removed_count == quantity:
                return true

    return false # Not enough items

func get_item_count(item_id: int) -> int:
    var count = 0
    for item_slot in hotbar_slots:
        if item_slot.item_id == item_id:
            count += item_slot.quantity
    for item_slot in inventory_slots:
        if item_slot.item_id == item_id:
            count += item_slot.quantity
    return count

func get_max_stack_size(item_id: int) -> int:
    # This should be defined in a separate ItemData system for proper item management
    # For now, a simple rule:
    if item_id == VoxelBlockSystem.BlockID.AIR: return 0
    if item_id in [VoxelBlockSystem.BlockID.GRASS, VoxelBlockSystem.BlockID.DIRT, VoxelBlockSystem.BlockID.STONE, VoxelBlockSystem.BlockID.SAND, VoxelBlockSystem.BlockID.WOOD, VoxelBlockSystem.BlockID.BRICK, VoxelBlockSystem.BlockID.OBSIDIAN, VoxelBlockSystem.BlockID.ORE]: return 64 # Stackable blocks
    if item_id in [VoxelBlockSystem.BlockID.WATER, VoxelBlockSystem.BlockID.SNOW, VoxelBlockSystem.BlockID.ICE, VoxelBlockSystem.BlockID.LEAVES, VoxelBlockSystem.BlockID.GLASS]: return 64 # Other stackable items
    return 1 # Non-stackable items (tools, weapons, etc.)

func get_inventory_data() -> Array:
    return inventory_slots

func get_hotbar_data() -> Array:
    return hotbar_slots

func set_selected_hotbar_slot(index: int):
    if index >= 0 and index < HOTBAR_SIZE:
        selected_hotbar_slot_index = index
        emit_signal("hotbar_updated")

func get_selected_hotbar_item() -> Dictionary:
    if selected_hotbar_slot_index >= 0 and selected_hotbar_slot_index < HOTBAR_SIZE:
        return hotbar_slots[selected_hotbar_slot_index]
    return { "item_id": VoxelBlockSystem.BlockID.AIR, "quantity": 0 }

func swap_slots(slot_type_a: String, index_a: int, slot_type_b: String, index_b: int):
    var slot_a_ref
    var slot_b_ref

    if slot_type_a == "inventory":
        slot_a_ref = inventory_slots
    elif slot_type_a == "hotbar":
        slot_a_ref = hotbar_slots
    else:
        return

    if slot_type_b == "inventory":
        slot_b_ref = inventory_slots
    elif slot_type_b == "hotbar":
        slot_b_ref = hotbar_slots
    else:
        return

    if index_a < 0 or index_a >= slot_a_ref.size() or \
       index_b < 0 or index_b >= slot_b_ref.size():
        return

    var temp = slot_a_ref[index_a]
    slot_a_ref[index_a] = slot_b_ref[index_b]
    slot_b_ref[index_b] = temp

    emit_signal("inventory_updated")
    emit_signal("hotbar_updated")
