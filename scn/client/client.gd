extends "res://scn/client/websocket_client.gd"

enum Requests {
    GET_ID,
    GET_TOKEN,
    VERIFY_TOKEN
   }

func _connected(proto = ""):
    _client.get_peer(1).put_packet(JSON.print({
        type = Requests.GET_ID
    }).to_utf8())

func _on_data():
    var msg: String = _client.get_peer(1).get_packet().get_string_from_utf8()
    print(msg)
    if JSON.parse(msg).get_error() != OK:
        return
    var response: Dictionary = JSON.parse(msg).result
    if response.error != "":
        print(response.error)
        $VBoxContainer/Label.set_text(response.error)
        return
    $VBoxContainer/Label.set_text("")
    match int(response.type):
        Requests.GET_TOKEN:
            get_token(response.data)
        Requests.VERIFY_TOKEN:
            verify_token(response.data)
        Requests.GET_ID:
            $VBoxContainer/Label2.set_text("ID: "+str(response.data.id))

func get_token(data: Dictionary):
    $VBoxContainer/Token.set_text(data.token)
    $VBoxContainer/Label.set_text("Token received! Will expire in %s seconds" % data.expires_in)

func _on_Button_pressed():
    $VBoxContainer/Token.set_text("")
    _client.get_peer(1).put_packet(JSON.print({
        type = Requests.GET_TOKEN,
        data = {
            email = $VBoxContainer/Email.get_text(), 
            pwd = $VBoxContainer/Password.get_text()
            }
        }).to_utf8())

func verify_token(data: Dictionary):
    if data.success:
        $VBoxContainer/Label.set_text("You are AUTHORIZED!")

func _on_Button2_pressed():
    _client.get_peer(1).put_packet(JSON.print({
        type = Requests.VERIFY_TOKEN,
        data = {
            token = $VBoxContainer/Token.get_text()
            }
       }).to_utf8())


func _on_Button3_pressed():
    $VBoxContainer/Email.set_text("")
    $VBoxContainer/Password.set_text("")
    connect_to_socket()
