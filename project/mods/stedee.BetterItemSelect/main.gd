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

func _add_raw_item_no_count_check(data, save = true):
	if PlayerData.inventory.size() >= 10000:
		PlayerData._send_notification("inventory full, item trashed!", 1)
		return - 1
	
	data = _validate_item_safety_no_count_check(data)
	PlayerData.inventory.append(data)
	if save:
		PlayerData.emit_signal("_inventory_refresh")
		
func _validate_item_safety_no_count_check(item_data, filter_unobtainable = true):
	var FALLBACK_ITEM = {"id": "fish_lake_salmon", "ref": randi(), "size": 60.0, "quality": 0, "tags": [], "custom_name": ""}
	
	if not (item_data is Dictionary):
		return FALLBACK_ITEM
	
	var required_keys = ["id", "ref", "size", "quality"]
	for key in required_keys:
		if not item_data.keys().has(key):
			return FALLBACK_ITEM
	
	var item_id = str(item_data.id)
	var size = item_data.size
	var quality = item_data.quality
	var ref = item_data.ref
	var tags = item_data.tags if item_data.keys().has("tags") else []
	var custom_name = item_data.custom_name if item_data.keys().has("custom_name") else ""
	var count = item_data.count if item_data.keys().has("count") else 1
	
	
	if not Globals.item_data.keys().has(item_id):
		print("Item Does Not Exist.")
		return FALLBACK_ITEM
	
	
	if filter_unobtainable:
		var idata = Globals.item_data[item_id]["file"]
		if idata.unobtainable:
			return FALLBACK_ITEM
	
	
	if not (size is float or size is int): size = 60.0
	else: size = clamp(size, 0.01, 999999999.0)
	
	if not (quality is int): quality = 0
	else: quality = clamp(quality, 0, PlayerData.QUALITY_DATA.size() - 1)
	
	if not (ref is int): ref = randi()
	if ref == 0 and filter_unobtainable: ref = randi()
	
	if not (tags is Array): tags = []
	else:
		var new_tags = []
		for i in tags: new_tags.append(str(tags[i]))
		tags.clear()
		tags = new_tags
	
	custom_name = str(custom_name).left(28)
	custom_name = custom_name.replace("[", "")
	custom_name = custom_name.replace("]", "")
	
	# no count check
	#count = clamp(count, 1, 99)
	
	return {"id": item_id, "ref": ref, "size": size, "quality": quality, "tags": tags, "custom_name": custom_name, "count": count}
