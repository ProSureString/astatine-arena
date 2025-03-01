extends CharacterBody3D

@export var speed = 6.5
@export var acceleration = 6.0
@export var player_index: int = -1  # -1 means unassigned

# Tracking state
var is_active = false  # whaeter this player hsa joind gam yet ro not
var input_device = -1  # -1: keyboard, => 0: gamepad device ID
var BulletScene = preload("res://weapons/scenes/basic.tscn")
var shoot_cooldown = 0.3
var time_since_shot = 0.0

# Signals
signal player_joined(player_node, device_id)
signal player_shot(player_node)

func _ready() -> void:
	# Keep physics process disabled until player joins
	set_physics_process(false)
	set_process(false)
	# Make visible but semi-transparent to show it's inactive

func assign_input_device(device: int) -> void:
	input_device = device
	is_active = true
	player_index = $"..".register_player(self, device)
	
	# Make fully visible
	
	# Enable physics and processing
	set_physics_process(true)
	set_process(true)
	
	# Notify that this player has joined
	emit_signal("player_joined", self, device)
	print("Player ", player_index, " joined with device ", device)

func shoot_bullet() -> void:
	print("bullet shot by", name)
	var bullet = BulletScene.instantiate()
	bullet.global_transform = $BulletSpawn.global_transform

	# Set bullet properties
	var bullet_speed = 15.0
	var recoil_force = 2.0

	var forward_dir = -global_transform.basis.z.normalized()

	# Calculate the forward velocity component
	var forward_velocity = velocity.dot(forward_dir) * forward_dir

	# Set the bullet's velocity
	bullet.velocity = forward_velocity + forward_dir * bullet_speed
	bullet.shooter = self

	# Apply recoil to the shooter
	velocity += -forward_dir * recoil_force

	get_parent().add_child(bullet)
	emit_signal("player_shot", self)

func _physics_process(delta: float) -> void:
	if !is_active:
		return
		
	# Handle input based on device
	var input_dir: Vector2
	
	if input_device == -1:
		# Keyboard controls
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		print("kbc")
	else:
		# Gamepad controls - use joypad motion from the specific device
		input_dir = Vector2(
			Input.get_joy_axis(input_device, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(input_device, JOY_AXIS_LEFT_Y)
		)
		
		# Apply deadzone
		if input_dir.length() < 0.2:
			input_dir = Vector2.ZERO
		else:
			input_dir = input_dir.normalized() * ((input_dir.length() - 0.2) / 0.8)
	
	var direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	var target_velocity: Vector3 = direction * speed
	print(target_velocity)
	
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	
	move_and_slide()
	
	# Restrict Y movement to keep player on ground
	velocity.y = 0
	
	# Shooting logic
	time_since_shot += delta
	var shoot_pressed = false
	
	if input_device == -1:
		# Keyboard shooting
		shoot_pressed = Input.is_action_pressed("shoot")
	else:
		# Gamepad shooting (using right trigger)
		shoot_pressed = Input.get_joy_axis(input_device, JOY_AXIS_TRIGGER_RIGHT) > 0.5 or Input.is_joy_button_pressed(input_device, JOY_BUTTON_RIGHT_SHOULDER)
	
	if shoot_pressed and time_since_shot >= shoot_cooldown:
		shoot_bullet()
		time_since_shot = 0.0
	
	# Handle rotation based on input device
	update_rotation(delta)

func update_rotation(delta: float) -> void:
	var look_dir = Vector2.ZERO
	
	if input_device == -1:
		# Keyboard + mouse aiming
		var mouse_pos = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera_3d()
		
		if camera:
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000
			
			var space_state = get_world_3d().direct_space_state
			var ray_params = PhysicsRayQueryParameters3D.new()
			ray_params.from = from
			ray_params.to = to
			ray_params.exclude = [self]
			
			var result = space_state.intersect_ray(ray_params)
			if result:
				var target_point = result.position
				# Compute direction from self to target point, ignoring height
				var target_pos = Vector3(target_point.x, global_position.y, target_point.z)
				var target_direction = (target_pos - global_position).normalized()
				
				# Create basis with look_at
				var desired_basis = Basis().looking_at(target_direction, Vector3.UP)
				# Smooth rotation
				global_transform.basis = global_transform.basis.slerp(desired_basis, 10 * delta)
	else:
		# Gamepad aiming with right stick
		look_dir.x = Input.get_joy_axis(input_device, JOY_AXIS_RIGHT_X)
		look_dir.y = Input.get_joy_axis(input_device, JOY_AXIS_RIGHT_Y)
		
		# Apply deadzone
		if look_dir.length() > 0.3:
			var direction = Vector3(look_dir.x, 0, look_dir.y).normalized()
			var desired_basis = Basis().looking_at(direction, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(desired_basis, 10 * delta)
