extends Node
class_name Song

var path = ""
var fname = ""
var completed = false
var score = 0
var highscore = 0
var timesplayed = 1
var lastplayed = {}


func _init(filepath: String):
	assert(filepath.is_abs_path())
	self.path = filepath
	self.fname = filepath.get_file()
	self.completed = false
	self.score = 0
	self.highscore = 0
	self.timesplayed = 1
	self.lastplayed = OS.get_datetime(true)


func play(filepath):
	self.path = filepath
	self.fname = filepath.get_file()
	self.lastplayed = OS.get_datetime(true)
	self.timesplayed += 1


func get_last_played_timestamp():
	return OS.get_unix_time_from_datetime(self.lastplayed)


func save():
	return {
		"path": self.path,
		"fname": self.fname,
		"completed": self.completed,
		"score": self.score,
		"highscore": self.highscore,
		"timesplayed": self.timesplayed,
		"lastplayed": self.lastplayed
	}


func complete(final_score):
	self.completed = true
	self.score = max(final_score, 0)
	if self.score > self.highscore:
		self.highscore = self.score


func load_data(json_obj):
	assert(json_obj.path.is_abs_path())
	self.path = json_obj.path
	self.fname = json_obj.fname
	self.completed = json_obj.get("completed", false)
	self.score = max(json_obj.get("score", 0), 0)
	self.highscore = max(json_obj.get("highscore", 0), 0)
	self.timesplayed = max(json_obj.get("timesplayed", 1), 1)
	self.lastplayed = json_obj.get("lastplayed", OS.get_datetime(true))
