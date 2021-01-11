extends Node

const SongCard = preload("res://UI/SongCard.tscn")

var loading_messages = [
	"Mining bitcoin",
	"Computing on the block chain",
	"Tap tap tapping the beat",
	"Identifying beats poorly",
	"Doing a bad job overall",
	"Disappointing my father",
	"Machine learning the beats",
	"Using GANS",
	"Avoiding COVID-19",
	"I promise this is a game",
	"Opening a car loan on your behalf",
	"Generating winter wonderland",
	"This song is sick! Great choice!",
	"Trying really hard",
	"Doing my best worst job",
	"Loading completed 6 years ago",
	"None of these mean anything",
	"We're doing it live!",
	"Look behind you!",
	"Computers are hard",
	"I had so many plans",
	"There was so much to do",
	"There was no way"
]

var loading_dots = ""
var player_leaving = false
var player_looking_at_map = false
var player_looking_at_songs = false
var preload_done = false
var song_selected = false setget set_song_selected
var has_recent_songs = false setget set_has_recent_songs

onready var fadeLayer = $FadeLayer
onready var fileDialog = $UI/FileDialog
onready var mapFrame = $BackgroundLayer/Interior/MapFrameDark
onready var songFrame = $BackgroundLayer/Interior/SongFrame/SongFrameDark
onready var songsPlayed = $BackgroundLayer/SongsPlayed
onready var introText = $BackgroundLayer/IntroText
onready var loadingText = $BackgroundLayer/LoadingText
onready var chalkboardHelper = $BackgroundLayer/ChalkBoardHelperPopup
onready var mapHelper = $BackgroundLayer/MapHelperPopup
onready var animationPlayer = $AnimationPlayer
onready var dotdotdotTimer = $BackgroundLayer/LoadingText/DotDotDotTimer
onready var loadingLabel = $BackgroundLayer/LoadingText/LoadingLabel
onready var loadedAnimationPlayer = $LoadedArraowAnimator


func _ready():
	fadeLayer.fade_in()
	preload_done = BackgroundMusicAnalyzer.is_preload_done
	# warning-ignore:return_value_discarded
	BackgroundMusicAnalyzer.connect("preload_done", self, "_on_BackgroundMusicAnalyzer_preload_done")

	chalkboardHelper.scale = Vector2.ZERO
	mapHelper.scale = Vector2.ZERO
	self.has_recent_songs = SaveAndLoad.has_recent_songs()

	var count = 0
	for song in SaveAndLoad.get_recent_songs():
		var instance = SongCard.instance()
		instance.set_song(song)
		songsPlayed.add_child(instance)
		count += 1
		if count >= 6:
			break


func _input(event):
	if event.is_action_pressed("ui_up") and player_looking_at_map:
		fileDialog.popup_centered()


func set_has_recent_songs(value):
	has_recent_songs = value
	
	if not has_recent_songs:
		introText.visible = true
		songsPlayed.visible = false
		loadingText.visible = false
	else:
		introText.visible = false
		songsPlayed.visible = true
		loadingText.visible = false


func set_song_selected(value):
	song_selected = value
	if song_selected:
		loadingText.visible = true
		introText.visible = false
		songsPlayed.visible = false
		mapFrame.visible = false
		songFrame.visible = false
		if player_looking_at_map:
			animationPlayer.play_backwards("MapHelp")
			player_looking_at_map = false
		if player_looking_at_songs:
			animationPlayer.play_backwards("ChalkboardHelp")
			player_looking_at_songs = false
		dotdotdotTimer.start()


func _on_BackgroundMusicAnalyzer_preload_done():
	preload_done = true
	if player_leaving:
		fadeLayer.fade_out()


func _on_FadeLayer_fade_out_complete():
	if preload_done:
		# warning-ignore:return_value_discarded
		get_tree().change_scene("res://MainGame/PlaySong/AboveClouds.tscn")
	else:
		# warning-ignore:return_value_discarded
		get_tree().change_scene("res://MainGame/Home/Home.tscn")


func _on_ExitArea_body_entered(body):
	if body is Player:
		player_leaving = true
		if not song_selected or preload_done:
			fadeLayer.fade_out()


func _on_ExitArea_body_exited(body):
	if body is Player:
		player_leaving = false


func _on_FileDialog_file_selected(path):
	SaveAndLoad.play_song(path)
	BackgroundMusicAnalyzer.preload_song(path)
	self.song_selected = true


func _on_MapArea_body_entered(body):
	if body is Player and not self.song_selected:
		animationPlayer.play("MapHelp")
		player_looking_at_map = true
		mapFrame.visible = true


func _on_MapArea_body_exited(body):
	if body is Player and not self.song_selected:
		animationPlayer.play_backwards("MapHelp")
		player_looking_at_map = false
		mapFrame.visible = false


func _on_SongArea_body_exited(body):
	if body is Player and not self.song_selected and self.has_recent_songs:
		animationPlayer.play_backwards("ChalkboardHelp")
		player_looking_at_songs = false
		songFrame.visible = false


func _on_SongArea_body_entered(body):
	if body is Player and not self.song_selected and self.has_recent_songs:
		animationPlayer.play("ChalkboardHelp")
		player_looking_at_songs = true
		songFrame.visible = true


func _on_DotDotDotTimer_timeout():
	if preload_done:
		loadingLabel.text = "Song Ready!"
		loadedAnimationPlayer.play("LoadingComplete")
		return

	if len(loading_dots) == 1 or len(loading_dots) == 3 and len(loading_messages) > 0:
		loading_messages.shuffle()
		var message = loading_messages.pop_front()
		for child in loadingText.get_children():
			if child.name.begins_with("LoadingMessage") and child.text == "":
				child.text = message
				break

	if len(loading_dots) < 3:
		loading_dots += "."
	else:
		loading_dots = ""

	loadingLabel.text = "Loading" + loading_dots
	dotdotdotTimer.start()
