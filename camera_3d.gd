extends Camera3D

# Offset from parent's origin; adjust as needed.
@export var fixed_offset: Vector3 = Vector3(0, 10, 0)
# Smoothing factor for both parent's rotation and camera position updates.
@export var smoothing_speed: float = 50.0

var locked_basis: Basis

func _ready() -> void:
	# Save the camera’s starting rotation to keep it locked.
	locked_basis = global_transform.basis

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		# Get the mouse position and cast a ray from the camera.
		var mouse_pos = get_viewport().get_mouse_position()
		var from = project_ray_origin(mouse_pos)
		var to = from + project_ray_normal(mouse_pos) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var ray_params = PhysicsRayQueryParameters3D.new()
		ray_params.from = from
		ray_params.to = to
		# Exclude self from the raycast.
		ray_params.exclude = [self]
		
		var result = space_state.intersect_ray(ray_params)
		if result:
			var target_point = result.position
			# Get parent's current global position.
			var parent_node = get_parent()
			var parent_pos = parent_node.global_transform.origin
			# Compute a direction from the parent to the target point, ignoring vertical differences.
			var target_direction = (Vector3(target_point.x, parent_pos.y, target_point.z) - parent_pos).normalized()
			# Create a basis for the parent using a look_at, with Vector3.UP as the up direction.
			var desired_basis = Basis().looking_at(target_direction, Vector3.UP)
			# Smoothly interpolate parent's current basis toward the desired basis.
			parent_node.global_transform.basis = parent_node.global_transform.basis.slerp(desired_basis, smoothing_speed * delta)
		
		# Update the camera’s global position relative to the parent's updated position.
		var new_cam_pos = get_parent().global_transform.origin + fixed_offset
		# Smooth the camera movement.
		global_transform.origin = global_transform.origin.lerp(new_cam_pos, smoothing_speed * delta)
		# Lock the camera’s rotation by reassigning the saved locked_basis.
		global_transform.basis = locked_basis
