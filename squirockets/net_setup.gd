extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var player = preload("res://player.tscn")
onready var fps = get_node("Label2")
onready var control_node = get_node("conrol_node")
onready var device_ip = get_node("Label")
onready var ip_line = get_node("conrol_node/LineEdit")
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("network_peer_connected",self,"_player_connected")
	get_tree().connect("network_peer_disconnected",self,"_player_disconnected")
	get_tree().connect("connected_to_server",self,"_connected_to_server")
	
	device_ip.text = Network.ip_address
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _player_connected(id) -> void:
	instance_player(id)
	print("player " + str(id) + " connected")

func _player_disconnected(id) -> void:
	print("player " + str(id) + " disconnected")

func _on_server_pressed():
	control_node.hide()
	Network.create_server()
	
	instance_player(get_tree().get_network_unique_id())
	pass # Replace with function body.



func _on_join_pressed():
	control_node.hide()
	Network.ip_address = ip_line.text
	Network.join_server()
	pass # Replace with function body.

func _connected_to_server():
	yield(get_tree().create_timer(0.1),"timeout")
	instance_player(get_tree().get_network_unique_id())

func instance_player(id):
	var player_instance = Global.instance_node_location(player,GlobalWorld,GlobalWorld.get_node("spawnpoint").transform.origin)
	player_instance.name = str(id)
	player_instance.set_network_master(id)


func _on_Timer_timeout():
	fps.set_text("FPS "+str(Engine.get_frames_per_second()))
	pass # Replace with function body.
