extends KinematicBody2D

const MOVE_SPEED = 10.0
const MAX_HP = 100

enum MoveDirection { UP, DOWN, LEFT, RIGHT, NONE }

slave var slave_position = Vector2()
slave var slave_movement = MoveDirection.NONE
slave var slave_rotation = 0.0

var health_points = MAX_HP

func _ready():
	_update_health_bar()

func _physics_process(delta):
	var direction = MoveDirection.NONE
	if is_network_master():
		if Input.is_action_pressed('left'):
			direction = MoveDirection.LEFT
		if Input.is_action_pressed('right'):
			direction = MoveDirection.RIGHT
		if Input.is_action_pressed('up'):
			direction = MoveDirection.UP
		if Input.is_action_pressed('down'):
			direction = MoveDirection.DOWN
			
		rset_unreliable('slave_position', position)
		rset('slave_movement', direction)
		rset_unreliable('slave_rotation', rotation)
		_move(direction)
	else:
		_move(slave_movement)
		position = slave_position
		rotation = slave_rotation
	
	if get_tree().is_network_server():
		Network.update_position(int(name), position)

func _move(direction):
	match direction:
		MoveDirection.UP:
			move_and_collide(Vector2(0, -MOVE_SPEED))
		MoveDirection.DOWN:
			move_and_collide(Vector2(0, MOVE_SPEED))
		MoveDirection.LEFT:
			move_and_collide(Vector2(-MOVE_SPEED, 0))
		MoveDirection.RIGHT:
			move_and_collide(Vector2(MOVE_SPEED, 0))

func _update_health_bar():
	$GUI/HealthBar.value = health_points

func damage(value):
	health_points -= value
	if health_points <= 0:
		health_points = 0
		rpc('_die')
	_update_health_bar()

sync func _die():
	$RespawnTimer.start()
	set_physics_process(false)
	$Rifle.set_process(false)
	for child in get_children():
		if child.has_method('hide'):
			child.hide()
	$CollisionShape2D.disabled = true

func _on_RespawnTimer_timeout():
	set_physics_process(true)
	$Rifle.set_process(true)
	for child in get_children():
		if child.has_method('show'):
			child.show()
	$CollisionShape2D.disabled = false
	health_points = MAX_HP
	_update_health_bar()

func init(nickname, start_position, is_slave):
	$GUI/Nickname.text = nickname
	global_position = start_position
	if is_slave:
		$Rifle.modulate = Color(1, 1, 0)
