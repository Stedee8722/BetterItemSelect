extends Node

const item_selector_panel := preload("res://mods/stedee.BetterItemSelect/Scenes/item_selector_panel.tscn")
const amount_input_panel := preload("res://mods/stedee.BetterItemSelect/Scenes/amount_input.tscn")

var item_select

func _ready():
	get_tree().connect("node_added", self, "check_node")

func check_node(node: Node) -> void:
	if node.name == "item_select":
		item_select = node
		var panel := item_selector_panel.instance()
		item_select.get_node("Control").add_child(panel)
		var other_panel := amount_input_panel.instance()
		other_panel.visible = false
		item_select.get_node("Control").add_child(other_panel)
		var old_panel = item_select.get_node("Control/Panel")
		old_panel.hide()

func bulk_remove_item(item_id, count):
	var item
	var index
	for i in PlayerData.inventory:
		if i["ref"] == item_id:
			item = i
	
	assert(item, "No item found!")
	
	index = PlayerData.inventory.find(item)
	var has_stacks = false
	
	if item.keys().has("count") and item["count"] > count:
		PlayerData.inventory[index]["count"] -= count
		has_stacks = true
	else:
		item["count"] = 0
		has_stacks = false

	if not has_stacks:
		PlayerData.inventory.erase(item)

		for key in PlayerData.hotbar.keys():
			if PlayerData.hotbar[key] == item_id: PlayerData.hotbar[key] = 0
	
		PlayerData.locked_refs.erase(item_id)

		PlayerData.emit_signal("_item_removal", item_id)

	PlayerData.emit_signal("_inventory_refresh")
	PlayerData.emit_signal("_hotbar_refresh")
