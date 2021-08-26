extends KinematicBody
var motionofset = Vector3(0,0,0)
var velo = Vector3(1,0,0)
var speed = 90
var ofset = 0.02 
var life_time = 100
var start = true
var can_die = true
var started_dying = false
var explostion_radius = 15
var second_id = 0
var current_wapon = "rpg"
var gravity = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var explosion = get_node("explosion_area")
var player_rotation = Vector3(0,0,0)
puppet var puppet_position setget puppet_position_set
puppet var puppet_rotation = Vector3.ZERO
puppet var puppet_velocity = Vector3.ZERO
onready var trail = get_node("TrailRenderer")
onready var trail2 = get_node("TrailRenderer2")
var p_owner = 0

onready var initial_position = global_transform.origin

func _ready() -> void:
	explosion.get_node("CollisionShape").shape.radius = explostion_radius
	explosion.get_node("CollisionShape").disabled = true
	if is_network_master():
		visible = false
		#trail.width = 0.05
		#trail.exp_max_points = 5
		#trail2.width = 0.05
		#trail2.exp_max_points = 5
		#scale = Vector3(0.1,0.1,0.1)
		rset("puppet_position", global_transform.origin)
		rset("puppet_rotation", rotation)
		rset("puppet_velocity", velo)


# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	var velo = -global_transform.basis.z * speed * delta
	var collision = move_and_collide(velo)
	
	if collision != null:
		coll(collision.collider)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
sync func die() -> void:
	queue_free()

func puppet_position_set(new_value) -> void:
	puppet_position = new_value
	global_transform.origin = puppet_position

func coll(body) -> void:
	explode()
	#rpc("die")


func _on_Area_body_entered(body):
	if body.is_in_group("player") and can_die and !body.is_network_master():
		explode()
		body.hp -= 1


func _on_Timer_timeout():
	if get_tree().is_network_server():
		rpc("die")

func explode() -> void:
	get_node("boom").emitting = true
	get_node("boom").get_node("light").visible = true
	get_node("Spatial").visible = false
	explosion.get_node("CollisionShape").disabled = false
	if get_tree().is_network_server():
		if !started_dying:
			get_node("explodie").start()
			started_dying = true
	if !started_dying:
			get_node("explodie2").start()
			started_dying = true



func _on_Timer2_timeout():
	can_die = true
	pass # Replace with function body.


func _on_Timer3_timeout():
	visible = true
	pass # Replace with function body.


func _on_explosion_area_body_entered(body):
	if body.is_in_group("player") and body.is_network_master():
		if body.second_id != p_owner:
			body.rpc("wound",1)
		var dir = body.transform.origin - transform.origin
		dir = dir.normalized()
		body.add_velocity += dir*70
	pass # Replace with function body.


func _on_explodie_timeout():
	rpc("die")



func _on_explodie2_timeout():
	die()
	pass # Replace with function body.
