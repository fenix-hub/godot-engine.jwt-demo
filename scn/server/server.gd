extends "res://scn/server/websocket_server.gd"

var EMAIL: String = "user@email.test"
var PWD: String = "test.test"

const secret: String = "mysecret"
var algorithm: JWTAlgorithm = JWTAlgorithm.new(HashingContext.HASH_SHA256, secret)

enum Requests {
    GET_ID,
    GET_TOKEN,
    VERIFY_TOKEN
   }

func _printt(id, msg) -> void:
    print("[PEER %s] >> %s" % [id, msg])

func _on_data(id):
    var pkt: PoolByteArray = _server.get_peer(id).get_packet()
    var mess: String = pkt.get_string_from_utf8()
    if JSON.parse(mess).error != OK:
        return
    var req: Dictionary = JSON.parse(mess).result
    match int(req.type): 
        Requests.GET_ID:
            send_id(id)
        Requests.GET_TOKEN:
            create_token(id, req.data)
        Requests.VERIFY_TOKEN:
            verify_token(id, req.data)
        _:
            _printt(id, "request not recognized")

func send_id(id) -> void:
    _printt(id, "requested id")
    _server.get_peer(id).put_packet(JSON.print({error = "", data = { id = id }, type = Requests.GET_ID}).to_utf8())

func create_token(id: int, data: Dictionary) -> void:
    _printt(id, "requested authorization...")
    var email: String = data.email
    var pwd: String = data.pwd
    if not (auth_user(email, pwd)):
        _printt(id, "unauthorized")
        _server.get_peer(id).put_packet(JSON.print({error = "UNAUTHORIZED", type = Requests.GET_TOKEN}).to_utf8())
        return
    
    _printt(id, "authorized")
    var expires_in: int = 10
    var token: String = JWT.create().with_issuer("godot-server") \
    .with_claim("id",id).with_expires_at(OS.get_unix_time() + expires_in) \
    .sign(algorithm)
    _printt(id, "JWT = "+token)
    _server.get_peer(id).put_packet(JSON.print({error = "", type = Requests.GET_TOKEN, data = {token = token, expires_in = expires_in}}).to_utf8())

func verify_token(id: int, data: Dictionary) -> void:
    var jwt_verifier: JWTVerifier = JWT.require(algorithm).with_issuer("godot-server").with_claim("id",id).build()
    var verify: int = jwt_verifier.verify(data.token)
    _printt(id, jwt_verifier.exception)
    _server.get_peer(id).put_packet(JSON.print({error = jwt_verifier.exception, type = Requests.VERIFY_TOKEN, data = {success = (verify == JWTVerifier.Exceptions.OK)}}).to_utf8())

func auth_user(email: String, pwd: String) -> bool:
    return email == EMAIL and pwd == PWD
