extends KinematicBody

var current_wapon = ""
var finalrotationdegreesz
var add_velocity = Vector3.ZERO
onready var bullet_scn = preload("res://Bullet.tscn")
onready var velocity_display = $Control2/Label
onready var horizontal_velocity_display = $Control2/Label2
onready var leftarea = get_node("RayCast2")
onready var rightarea = get_node("RayCast")
var reloading = false
var velocity = Vector3()
const ACCELERATION = 8
const DE_ACCELERATION = 8
const MOVE_SPEED = 34
const JUMP_FORCE = 55
const GRAVITY = 1.7
const MAX_FALL_SPEED = 500
var mouse_captured = false
var slide = false
const H_LOOK_SENS = 0.1
const V_LOOK_SENS = 0.1
var shootcooldown = 0
onready var tick_rate = $tick_rate
onready var cam = get_node("cam_origin")
onready var realcam = cam.get_node("Camera")
onready var tween = get_node("Tween")
onready var raycast = cam.get_node("RayCast")
var hp = 10
onready var gunanim = cam.get_node("AnimationPlayer")
onready var particles = cam.get_node("Particles")
var max_jet_speed = 70
var jet_speed = 8
var move_vec = Vector3()
var camdistance = 0
var y_velo = 0
onready var bodyAnim = get_node("PlayerGraphics/BodyPlayer")
const MAX_CAMERA_SHAKE = 0.5

puppet var puppet_position = Vector3.ZERO setget puppet_position_set
puppet var puppet_rotation = Vector2.ZERO
puppet var puppet_is_alive = true

var second_id = 0

onready var fire_rate = $fire_rate

func _ready():
	second_id = get_tree().get_network_unique_id()
	#if camdistance == 0:
		#get_node("PlayerGraphics").visible = false
	#else:
		#get_node("PlayerGraphics").visible = true
	#bodyAnim.set_loop(true)


func _input(event):
	if event is InputEventMouseMotion and is_network_master():
		cam.rotation_degrees.x -= event.relative.y * V_LOOK_SENS
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -90, 90)
		rotation_degrees.y -= event.relative.x * H_LOOK_SENS

 
func puppet_position_set(new_value):
	puppet_position = new_value
	tween.interpolate_property(self,"translation",global_transform.origin,puppet_position,0.05)
	#global_transform.origin = puppet_position
	tween.start()

func _physics_process(delta):
	var finalrotation = 0
	if is_network_master():
		get_node("Control2/Label3").text = str(hp)
		if hp<=0:
			rset("puppet_is_alive",false)
			visible = false
		realcam.current = true
		if Input.is_action_pressed("shoot") and !gunanim.is_playing():
			rpc("instance_bullet", get_tree().get_network_unique_id())
			reloading = true
			gunanim.play("fire")   
			pass
		var move_vec = Vector3()
		if !slide:
			if Input.is_action_pressed("BACKWARD"):
				move_vec.z += 1
			if Input.is_action_pressed("RIGHT"):
				move_vec.x += 1
			if Input.is_action_pressed("LEFT"):
				move_vec.x -= 1
			if Input.is_action_pressed("FORWARD"):
				move_vec.z -= 1
			elif Input.is_action_pressed("BACKWARD"):
				move_vec.z += 1
		if Input.is_action_pressed("slide"):
			slide = true
		else:
			slide = false
		if Input.is_action_just_pressed("im_on_fire"):
			togle_fire()
			rpc("togle_fire")
		move_vec = move_vec.rotated(Vector3(0, 1, 0), rotation.y)
		move_vec = move_vec.normalized()
		move_vec.y = 0
		if Input.is_action_just_pressed("slide"):
			get_node("CollisionShape").scale.z = 1
		if Input.is_action_just_released("slide"):
			get_node("CollisionShape").scale.z = 3
		var grounded = is_on_floor()
		#velocity.y -= GRAVITY
		var just_jumped = false
		if grounded:
			if Input.is_action_pressed("JUMP"):
				just_jumped = true
				velocity.y = JUMP_FORCE
		if grounded and velocity.y <= 0:
			velocity.y = -0.1
		if velocity.y < -MAX_FALL_SPEED:
			velocity.y = -MAX_FALL_SPEED
		if Input.is_action_just_pressed("ui_cancel"):
			if !mouse_captured:
				mouse_captured = true
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				mouse_captured = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		if Input.is_key_pressed(KEY_U):
			if velocity.y < max_jet_speed: 
				velocity.y += jet_speed
			else:
				velocity.y = max_jet_speed
		
		var hv = velocity
		var boingvec = Vector3(0,0,0)
		if leftarea.is_colliding():
			finalrotationdegreesz = -30
		elif rightarea.is_colliding():
			finalrotationdegreesz = 30
		else:
			finalrotationdegreesz = 0
		if !is_on_wall():
			velocity.y -= GRAVITY
			if leftarea.is_colliding() and !slide:
				boingvec = -leftarea.get_collision_normal()
			elif rightarea.is_colliding() and !slide:
				boingvec = -rightarea.get_collision_normal()
		else:
			velocity.y -= GRAVITY/2
			if Input.is_action_pressed("JUMP") and !slide:
				if leftarea.is_colliding():
					velocity.y = JUMP_FORCE
					boingvec = leftarea.get_collision_normal()
					boingvec*=30
				elif rightarea.is_colliding():
					velocity.y = JUMP_FORCE
					boingvec = rightarea.get_collision_normal()
					boingvec*=30
		hv += boingvec
		hv.y = 0
		if cam.rotation_degrees.z > finalrotationdegreesz:
			cam.rotation_degrees.z -=2
		if cam.rotation_degrees.z < finalrotationdegreesz:
			cam.rotation_degrees.z +=2
		var new_pos = move_vec * MOVE_SPEED
		var accel = DE_ACCELERATION
		if (move_vec.dot(hv) > 0):
			if !slide:
				accel = ACCELERATION
			else:
				accel = 0
		else:
			if slide:
				accel/= 6
		if !is_on_floor():
			accel = accel/8
		hv = hv.linear_interpolate(new_pos, accel * delta)
		velocity.x = hv.x
		velocity.z = hv.z
		velocity = move_and_slide(velocity + add_velocity, Vector3(0,1,0))
		add_velocity = Vector3.ZERO
	else:
		realcam.current = false
		cam.get_node("AKM3").visible = false
		cam.get_node("RPG").visible = true
		rotation.y = puppet_rotation.y
		cam.rotation.x = puppet_rotation.x
		if !puppet_is_alive:
			visible = false







sync func instance_bullet(id):
	var pbi = Global.instance_node_location(bullet_scn,GlobalWorld,cam.get_node("Position3D").global_transform.origin)
	pbi.name = "bullet" + name + str(Network.noni)
	pbi.set_network_master(id)
	pbi.rotation = rotation
	pbi.rotation.x = cam.rotation.x
	pbi.p_owner = id
	pbi.second_id = second_id
	Network.noni += 1

func _on_fire_rate_timeout():
	reloading = false
	pass # Replace with function body.

sync func wound(dmg):
	hp -= dmg

func togle_fire() -> void:
	get_node("cam_origin/im_on_fire").visible = !get_node("cam_origin/im_on_fire").visible

func _on_tick_rate_timeout():
	if is_network_master():
		rset_unreliable("puppet_position",global_transform.origin)
		rset_unreliable("puppet_rotation", Vector2(cam.rotation.x,rotation.y))
	pass # Replace with function body.

func get_distance_to_3d(start : Vector3, end : Vector3):
	return sqrt(pow(get_distance_to_2d(Vector2(start.x,start.z),Vector2(end.x,end.z)),2)+pow(start.y-end.y,2))

func get_distance_to_2d(start : Vector2, end : Vector2):
	return sqrt(pow(start.x-end.x,2)+pow(start.y-end.y,2))

func _on_velo_update_timeout():
	velocity_display.text = "velocity " + str(get_distance_to_3d(Vector3.ZERO,velocity))
	horizontal_velocity_display.text = "horizontal velocity " + str(get_distance_to_2d(Vector2(0,0),Vector2(velocity.x,velocity.z)))
	pass # Replace with function body.
