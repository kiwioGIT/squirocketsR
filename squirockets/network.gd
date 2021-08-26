extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 6

var server = null
var client = null
var noni = 0 setget noni_set
puppet var puppet_noni = 0 setget puppet_noni_set

var ip_address = ""



func _ready() -> void:

	
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168."):
			ip_address = ip
	
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connection_failed")

func create_server() -> void:
	server = NetworkedMultiplayerENet.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().set_network_peer(server)
	
func puppet_noni_set(new_value):
	noni = new_value

func noni_set(new_value):
	noni = new_value
	
	if get_tree().is_network_server():
		rset("puppet_noni", noni)



func join_server() -> void:
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(client)

func reset_network_connection() -> void:
	if get_tree().has_network_peer():
		get_tree().network_peer = null

func _connected_to_server() -> void:
	print("Successfully connected to the server")
	

func _server_disconnected() -> void:
	print("Disconnected from the server")



