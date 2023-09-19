extends Node

@export var SERVER_ADDRESS = "127.0.0.1"
@export var SERVER_PORT = 9999

var player_scene = preload("res://Player.tscn")
var host = false

# Called when the node enters the scene tree for the first time.
func _ready():
  start()


func start():
  var peer = ENetMultiplayerPeer.new()

  var _peer = peer.create_server(SERVER_PORT)

  if peer.host:
    host = true
    multiplayer.multiplayer_peer = peer
    print("Server listening on port: ", SERVER_PORT)

  else:
    _peer = null
    print("Server failed to start. Starting client")
  
    _peer = peer.create_client(SERVER_ADDRESS, SERVER_PORT)
    print("Client connecting to server at: ", SERVER_ADDRESS, ":", SERVER_PORT)

    var _peer_connected =  multiplayer.peer_connected.connect(on_peer_connected)
    var _peer_disconnected = multiplayer.peer_disconnected.connect(on_peer_disconnected)

    var _sync_started = SyncManager.sync_started.connect(on_sync_started)
    var _sync_stopped = SyncManager.sync_stopped.connect(on_sync_stopped)
    var _sync_lost = SyncManager.sync_lost.connect(on_sync_lost)
    var _sync_regained = SyncManager.sync_regained.connect(on_sync_regained)
    var _sync_error = SyncManager.sync_error.connect(on_sync_error)
    
    multiplayer.multiplayer_peer = peer

func on_peer_connected(id):
  SyncManager.add_peer(id)
  print(id, " connected!")
  
  if !host && id != 1:
    if multiplayer.get_unique_id() > id:
      $World/Player1.set_multiplayer_authority(id)
      print(multiplayer.get_unique_id(), ' player 1 multiplayer auth ', id)
      $World/Player2.set_multiplayer_authority(multiplayer.get_unique_id())
      print(multiplayer.get_unique_id(), ' player 2 multiplayer auth ', multiplayer.get_unique_id())
    else:
      $World/Player1.set_multiplayer_authority(multiplayer.get_unique_id())
      print(multiplayer.get_unique_id(), ' player 1 multiplayer auth ', multiplayer.get_unique_id())
      $World/Player2.set_multiplayer_authority(id)
      print(multiplayer.get_unique_id(), ' player 2 multiplayer auth ', id)
         
  if host:
    $Camera3D.current = true
    await get_tree().create_timer(2).timeout
    var peers = multiplayer.get_peers()
    print('server peers ', peers)
    if len(peers) > 1:
      print('we have enough peers, assigning control on server')
      if peers[0] > peers[1]:
        $World/Player1.set_multiplayer_authority(peers[1])
        print(multiplayer.get_unique_id(), ' player 1 multiplayer auth ', peers[1])
        $World/Player2.set_multiplayer_authority(peers[0])
        print(multiplayer.get_unique_id(), ' player 2 multiplayer auth ', peers[0])
      else:
        $World/Player1.set_multiplayer_authority(peers[0])
        print(multiplayer.get_unique_id(), ' player 1 multiplayer auth ', peers[0])
        $World/Player2.set_multiplayer_authority(peers[1])
        print(multiplayer.get_unique_id(), ' player 2 multiplayer auth ', peers[1])
    else:
      print('peer failed to connect. Dying dead.')
      get_tree().quit()
      
    SyncManager.start()
  
  
func on_peer_disconnected(id):
  SyncManager.remove_peer(id)
  print(id, " disconnected!")
  
  
func on_sync_started():
  print("Sync started!")  
  
func on_sync_stopped():
  print("Sync stopped!")
  
func on_sync_lost():
  print("Sync lost!")
  
func on_sync_regained():
  print("Sync regained!")

func on_sync_error():
  print("Sync error!")
