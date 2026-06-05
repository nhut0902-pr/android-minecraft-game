extends Node

class_name AudioManager

const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready():
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    music_player.bus = MUSIC_BUS

    sfx_player = AudioStreamPlayer.new()
    add_child(sfx_player)
    sfx_player.bus = SFX_BUS

    # Ensure audio buses exist (can be set up in Project Settings -> Audio Bus)
    if AudioServer.get_bus_index(MUSIC_BUS) == -1:
        print("Warning: Music bus not found. Please create it in Project Settings -> Audio Bus.")
    if AudioServer.get_bus_index(SFX_BUS) == -1:
        print("Warning: SFX bus not found. Please create it in Project Settings -> Audio Bus.")

func play_music(music_path: String, volume_db: float = 0.0):
    if music_player.stream and music_player.stream.resource_path == music_path:
        if not music_player.playing:
            music_player.play()
        return

    var music_stream = load(music_path)
    if music_stream:
        music_player.stream = music_stream
        music_player.volume_db = volume_db
        music_player.play()
    else:
        print("Error: Music file not found at %s" % music_path)

func stop_music():
    music_player.stop()

func set_music_volume(volume_db: float):
    music_player.volume_db = volume_db

func play_sfx(sfx_path: String, volume_db: float = 0.0):
    var sfx_stream = load(sfx_path)
    if sfx_stream:
        sfx_player.stream = sfx_stream
        sfx_player.volume_db = volume_db
        sfx_player.play()
    else:
        print("Error: SFX file not found at %s" % sfx_path)

func set_sfx_volume(volume_db: float):
    sfx_player.volume_db = volume_db

func get_music_volume() -> float:
    return music_player.volume_db

func get_sfx_volume() -> float:
    return sfx_player.volume_db
