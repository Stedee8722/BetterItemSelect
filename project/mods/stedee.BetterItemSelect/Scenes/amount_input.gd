extends Control

var ref = 0
var idata
var entry

signal _amount_selected

func _ready():
	set_process_input(true)

func ask_amount(id, item_data, icon):
	ref = id
	idata = item_data
	$"BG/VBoxContainer/CenterContainer/Panel/TextureRect".texture = icon
	$"BG/VBoxContainer/CenterContainer/Panel/stack_count".text = "x" + str(item_data["count"])
	$"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".modulate = Color(1, 1, 1)
	$"BG/VBoxContainer/HBoxContainer/HBoxContainer2/Button".text = "Done"
	$"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".text = ""
	visible = true

func _on_done_Button_pressed():
	if $"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".text == null || not $"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".text.is_valid_integer():
		$"BG/VBoxContainer/HBoxContainer/HBoxContainer2/Button".text = "Invalid"
		$"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".modulate = Color(1, 0, 0)
		return
	if int($"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".text) > idata["count"]:
		$"BG/VBoxContainer/HBoxContainer/HBoxContainer2/Button".text = "Insufficient"
		$"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".modulate = Color(1, 0, 0)
		return
	$"BG/VBoxContainer/HBoxContainer/HBoxContainer2/Button".text = "Done"
	$"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".modulate = Color(1, 1, 1)
	var count = int($"BG/VBoxContainer/HBoxContainer/HBoxContainer/LineEdit".text)
	entry = {"idata": idata, "count": count}
	emit_signal("_amount_selected", entry)
	visible = false

func _on_half_Button_pressed():
	var count = ceil(idata["count"]/2)
	entry = {"idata": idata, "count": count}
	emit_signal("_amount_selected", entry)
	visible = false

func _on_all_Button_pressed():
	var count = idata["count"]
	entry = {"idata": idata, "count": count}
	emit_signal("_amount_selected", entry)
	visible = false

func _input(ev):
	if Input.is_key_pressed(KEY_ENTER):
		_on_done_Button_pressed()

func _on_close_Button_pressed():
	entry = {"idata": idata, "count": 0}
	emit_signal("_amount_selected", entry)
	visible = false
