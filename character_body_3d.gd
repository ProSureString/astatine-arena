extends CharacterBody3D

@export var speed = 8.0
@export var acceleration = 10.0

var BulletScene = preload("res://bullet.tscn")
var shoot_cooldown = 0.3
var time_since_shot = 0.0

@onready var cam = $Camera

func shoot_bullet():
	print("bulet shot by", name)
	var bullet = BulletScene.instantiate()
	bullet.global_transform = global_transform  
	get_parent().add_child(bullet)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	var target_velocity: Vector3 = direction * speed
	
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	move_and_slide()
	
	if Input.is_action_pressed("quit"):
		#$"../".exit_game(name.to_int())
		get_tree().quit()
		
	
	time_since_shot += delta
	if Input.is_action_pressed("shoot") and time_since_shot >= shoot_cooldown:
		shoot_bullet()
		time_since_shot = 0.0
