extends VBoxContainer
class_name SongCard

var song_name = ""
var completed = false
var highscore = 0
var timesplayed = 1

onready var songName = $SongName
onready var completeTexture = $SongStats/Complete
onready var failedTexture = $SongStats/Failed
onready var score = $SongStats/Score
onready var timesPlayed = $SongStats/TimesPlayed


func _ready():
	timesPlayed.text = "Played: " + str(clamp(timesplayed, 1, 999))
	score.text = "Highscore: " + str(clamp(highscore, 0, 999999999))
	songName.text = song_name
	if completed:
		completeTexture.visible = true
		failedTexture.visible = false
	else:
		completeTexture.visible = false
		failedTexture.visible = true


func set_song(song):
	song_name = song.fname
	completed = song.completed
	highscore = song.highscore
	timesplayed = song.timesplayed
