extends Node

const SAVE_FILE = "user://wonderjam_save_data.json"

var Song = load("res://Utils/Song.gd")
var songs_played = {}


func _ready():
	load_game()


func has_recent_songs():
	return len(songs_played.values()) > 0


func custom_datetime_sort(a, b):
	if a.get_last_played_timestamp() > b.get_last_played_timestamp():
		return true
	return false


func get_recent_songs():
	var songs = songs_played.values()
	songs.sort_custom(self, "custom_datetime_sort")
	return songs


func get_fname_key(filepath: String):
	var fname = filepath.get_file()
	return fname.get_basename()


func play_song(filepath: String):
	assert(filepath.is_abs_path())
	assert(can_play_song(filepath))

	var key = get_fname_key(filepath)
	if key in songs_played:
		var song = songs_played[key]
		song.play(filepath)
		save_game()
		return
	
	var song = Song.new(filepath)
	songs_played[key] = song
	save_game()


func complete_song(filepath: String, score: int):
	var key = get_fname_key(filepath)
	assert(key in songs_played)
	var song = songs_played[key]
	song.complete(score)
	save_game()


func can_play_song(filepath: String):
	assert(filepath.is_abs_path())
	var file = File.new()
	return file.file_exists(filepath)


func save_game():
	var save_game = File.new()
	save_game.open(SAVE_FILE, File.WRITE)

	for key in songs_played:
		var song = songs_played[key]
		var song_data = song.save()
		save_game.store_line(to_json(song_data))

	save_game.close()


func load_game():
	var save_game = File.new()
	if not save_game.file_exists(SAVE_FILE):
		return

	save_game.open(SAVE_FILE, File.READ)

	while not save_game.eof_reached():
		var current_line = save_game.get_line()
		if current_line == "":
			continue

		var song_obj = parse_json(current_line)
		if song_obj == null:
			continue

		var song = Song.new(song_obj.path)
		var key = get_fname_key(song_obj.path)
		song.load_data(song_obj)
		songs_played[key] = song

	save_game.close()
