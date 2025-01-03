extends VBoxContainer

onready var item_select = $"/root/stedeeBetterItemSelect".item_select

# Called when the node enters the scene tree for the first time.
func _ready():
	var box = $Panel / Control / ScrollContainer / GridContainer
	
	for child in box.get_children(): child.queue_free()
	
	var index = 0
	for item in PlayerData.inventory:
		if item_select.filter != [] and not item_select.filter.has(item["id"]): continue
		if item_select.tag_filter != "": if not item.keys().has("tags") or not item["tags"].has(item_select.tag_filter): continue
		
		if item_select.ignore_specified:
			if Globals.item_data[item["id"]]["file"].unselectable: continue
			if PlayerData.locked_refs.has(item["ref"]): continue
		else:
			if Globals.item_data[item["id"]]["file"].unrenamable: continue
		
		var i = preload("res://Scenes/HUD/inventory_item.tscn").instance()
		box.add_child(i)
		i._setup_item(item["ref"])
		i.slot = index
		i.connect("pressed", self, "_item_pressed", [i, item])
		index += 1
	
	get_parent().get_node("Label").text = "SELECT ITEMS (0/" + str(item_select.max_items) + ")"

func _process(delta):
	var flag = false
	for ref in item_select.selected:
		if PlayerData._find_item_code(ref)["count"] > 99:
			flag = true
			break
			
	if flag:
		$RichTextLabel.visible = true
	else:
		$RichTextLabel.visible = false

func _item_pressed(slot, item):
	print(item)
	var idata = PlayerData._find_item_code(item["ref"])
	var id = idata["id"]
	assert(Globals.item_data.keys().has(id), "ERROR: You have an item that doesn't exist?.");
	var data = Globals.item_data[id]["file"]
	
	var new_data = item
	var box = $Panel2 / Control / ScrollContainer / GridContainer
	
	if slot.highlighted:
		for entry in item_select.selected:
			if entry == item["ref"]:
				item_select.selected.erase(entry)
		slot._highlight( not slot.highlighted)
		for child in box.get_children():
			if child.saved_ref == item["ref"]:
				child.queue_free()
				break

	elif item_select.selected.size() < item_select.max_items:
		if idata.keys().has("count") && idata["count"] > 1:
			$"../main/".ask_amount(item["ref"], idata, data.icon)
			var entry = yield($"../main/", "_amount_selected")
			if entry["count"] == 0: return
			new_data = split_stack(entry["idata"], entry["count"])
		if new_data["ref"] == item["ref"]:
			slot._highlight( not slot.highlighted)
		item_select.selected.append(new_data["ref"])
		var i = preload("res://Scenes/HUD/inventory_item.tscn").instance()
		box.add_child(i)
		i._setup_item(new_data["ref"])
		i.connect("pressed", self, "_split_item_pressed", [slot, new_data, item["ref"]])
	get_parent().get_node("Label").text = "SELECT ITEMS (" + str(item_select.selected.size()) + "/" + str(item_select.max_items) + ")"

func split_stack(data, count):
	var new_data = data.duplicate(true)
	if data.keys().has("count") and data["count"] > count:
		$"/root/stedeeBetterItemSelect".bulk_remove_item(data["ref"], count)
		new_data["count"] = count
		randomize()
		var ref = randi()
		new_data["ref"] = ref
		$"/root/stedeeBetterItemSelect"._add_raw_item_no_count_check(new_data)
		return new_data
	else:
		return new_data

func merge_stack(data, og_ref):
	var i
	for item in PlayerData.inventory:
		if item["ref"] == og_ref:
			i = item
	
	assert(i, "Uhh this shouldn't have happened!")
	var index = PlayerData.inventory.find(i)
	PlayerData.inventory[index]["count"] += data["count"]
		
	PlayerData.emit_signal("_inventory_refresh")
	PlayerData.emit_signal("_hotbar_refresh")

func _split_item_pressed(slot, item, original_ref):
	var box = $Panel2 / Control / ScrollContainer / GridContainer
	for entry in item_select.selected:
		if entry == item["ref"]:
			item_select.selected.erase(entry)
	for child in box.get_children():
		if child.saved_ref == item["ref"]:
			child.queue_free()
			break
	get_parent().get_node("Label").text = "SELECT ITEMS (" + str(item_select.selected.size()) + "/" + str(item_select.max_items) + ")"
	if slot.highlighted || not item.keys().has("count"): 
		slot._highlight( not slot.highlighted)
		return
	merge_stack(item, original_ref)
