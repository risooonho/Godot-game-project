extends Sprite

const Bullet = preload("res://weapons/bullet/Bullet.tscn")
# warning-ignore:unused_argument
func _process(delta):
	if is_network_master():
		if Input.is_action_pressed('shoot') and $Timer.is_stopped():
			rpc('_shoot')
			$Timer.start()
		#rotation += get_local_mouse_position().angle()
		
func _on_Timer_timeout():
	$Timer.stop()

sync func _shoot():
	var bullet = Bullet.instance()
	add_child(bullet)
	bullet.global_position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	
func _physics_process(delta):
	if is_network_master():
		var look_vec = get_global_mouse_position() - global_position
		global_rotation = atan2(look_vec.y, look_vec.x) + PI/2.0