extends Tree

func _gui_input(event):
	if not get_focus_owner() == self:
		return
		
	if event.is_action_pressed("ui_up"):
		_move_sel_up()
	if event.is_action_pressed("ui_down"):
		_move_sel_down()


func _is_item_visible(item):
	var p = item.get_parent()
	if p:
		return not p.collapsed
	return true

func _show_if_hidden(item):
	if item == null:
		return
	
	if not _is_item_visible(item):
		var p = item.get_parent()
		if p:
			print("Uncollapsing Parent")
			p.collapsed = false

func _first_selectable(item):
	if item == null:
		return null
	if item.is_selectable(0):
		return item
	return _first_selectable(item.get_children())


func _move_selection(dir):
	var selitem = get_selected()
	if selitem:
		var nitem = null
		if dir == -1:
			nitem = selitem.get_prev()
		else:
			nitem = selitem.get_next()
		
		if nitem:
			_show_if_hidden(nitem)
			nitem.select(0)
		else:
			var p = selitem.get_parent()
			if p:
				p = p.get_next()
				if p:
					nitem = p.get_children()
					if nitem:
						_show_if_hidden(nitem)
						nitem.select(0)


func _move_sel_up():
	_move_selection(-1)

func _move_sel_down():
	_move_selection(1)


func _on_focus_entered():
	var selitem = get_selected()
	if not selitem:
		selitem = get_root().get_children()
		if selitem:
			selitem = _first_selectable(selitem)
			if selitem:
				_show_if_hidden(selitem)
				selitem.select(0)
