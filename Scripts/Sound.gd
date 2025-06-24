extends Node

# Configurações
@export var tracks: Array[AudioStream] = []
@export_range(-80, 24) var volume_db: float = -6.0



var music_player: AudioStreamPlayer

func _ready():
	# Cria o player se não existir
	if !has_node("BackgroundMusicPlayer"):
		music_player = AudioStreamPlayer.new()
		music_player.name = "BackgroundMusicPlayer"
		music_player.volume_db = volume_db
		add_child(music_player)
		music_player.connect("finished", Callable(self, "_on_music_finished"))
	
	play_random_music()

func play_random_music():
	if tracks.size() == 0:
		push_warning("Nenhuma música configurada no MusicManager")
		return
	
	# Escolhe nova música aleatória
	var new_index = randi() % tracks.size()
	music_player.stream = tracks[new_index]
	music_player.play()

func _on_music_finished():
	play_random_music()

func reset_background_music():
	if music_player:
		music_player.stop()
		play_random_music()
