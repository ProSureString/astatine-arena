extends Area3D

@export var max_bounces = 3
@export var speed_transfer_factor = 0.3  
@export var bullet_length_scale = 0.1
@export var final_bounce_decay = true

var velocity = Vector3.FORWARD * 20.0
var bounce_count = 0
var shooter = null
var is_final_bounce = false

@onready var mesh = $MeshInstance3D if has_node("MeshInstance3D") else null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	connect("body_entered", _on_body_entered)
	update_bullet_appearance()

func _physics_process(delta):
	if is_final_bounce:
		var decay_rate = 100.0 * delta
		velocity = velocity.move_toward(Vector3.ZERO, decay_rate)
		
		if velocity.length_squared() < 0.1:
			queue_free()
	
	if not is_final_bounce:
		global_translate(velocity * delta)
		
		# Make the bullet face the direction it is moving
		if velocity.length_squared() > 0:
			look_at(global_position + velocity.normalized(), Vector3.UP)
	
	update_bullet_appearance()

func update_bullet_appearance():
	if mesh:
		var length = velocity.length() * bullet_length_scale
		mesh.scale = Vector3(mesh.scale.x, length, mesh.scale.z)

func _on_body_entered(body):
		
	if body is CharacterBody3D:
		# Hit a player - transfer momentum and disappear
		var impact_direction = velocity.normalized()
		var impact_strength = velocity.length() * speed_transfer_factor
		
		body.velocity += impact_direction * impact_strength
		
		queue_free()
	else:
		# Hit a wall or other object - bounce
		handle_bounce(body)

func handle_bounce(body):
	# Get the collision normal
	var space_state = get_world_3d().direct_space_state
	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = global_position - velocity.normalized() * 0.5
	ray_params.to = global_position + velocity.normalized() * 0.5
	ray_params.exclude = [self, shooter] if shooter else [self]
	
	var collision = space_state.intersect_ray(ray_params)
	if collision and collision.normal:
		print("bullet bounced")
		
		# Reflect velocity around the normal
		velocity = velocity.bounce(collision.normal)
		
		# Count this bounce
		bounce_count += 1
		
		# Check if this is the final bounce
		if bounce_count >= max_bounces:
			if final_bounce_decay:
				# Start decaying velocity to zero
				is_final_bounce = true
			else:
				# Just destroy the bullet immediately
				queue_free()
	#else:
		# Fallback if ray didn't detect collision normal
		#queue_free()
