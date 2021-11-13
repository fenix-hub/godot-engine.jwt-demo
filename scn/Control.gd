extends Control

var server: PackedScene = load("res://scn/server/Server.tscn")
var client: PackedScene = load("res://scn/client/Client.tscn")

func _ready():
    if OS.has_feature("server"):
        add_child(server.instance())
    if OS.has_feature("client"):
        add_child(client.instance())
