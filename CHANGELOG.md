# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Use the following sub-headings when adding changelog entries:

* __Added__ for new features.
* __Changed__ for changes in existing functionality.
* __Deprecated__ for soon-to-be removed features.
* __Removed__ for now removed features.
* __Fixed__ for any bug fixes.
* __Security__ in case of vulnerabilities.


## Released v0.8.5 - 2021-01-11

### Fixed

* Player could walk off the level in the `OutsideHouse` area - Fixed the collision shapes
* Fixed player stats not refilling after death
* Fixed a bug where you would be dropped into the same song again if you leave the house after completing the song

### Added

* Sound effects (just for item pickup right now)
* Bomb pickup item, health pickup item, and multiplier pickup item
* Health and bomb UI elements
* Game music for when not playing a song (CC0 from [ccMixter](http://ccmixter.org))
* Bomb effect that kills all enemies on screen

## Unreleased - 2021-01-10

### Added

* Finished importing art for boss enemy
* Added eyes to fire enemy
* Added player health
* Added enemy fire bullet
* Made the game possible to lose
* Added game icon
* Added game logo
* Added score and multiplier
* Added support for game saves
* Added chalkboard and tutorial
* Added "reset" support to the music handling classes so you can play more than one song without having to restart the game
* Added player death effect
* Added flying animation
* Added shooting animation
* Added UI element for a song card that can be displayed in the recent songs list on the chalkboard
* Added loading information
* Added helpful tutorial "control" popups
* Added fonts
* Added "flash" effect for when player gets hurt

### Changed

* Turned on "Treat warnings as errors" and fixed serval minor issues
* Code cleanup
* Changed the beat and peak detection to not hold mutexes as long
* Can no longer leave the house while a song is loading. Can leave when the song is done loading
* Changed title screen "press anything" prompt to be in a proper font
* Changed hurtbox to support invincibility
* Give player 1 second of invincibility on damage

## Unreleased - 2021-01-09

### Added

* Some new art assets for the game icon, health bar, and some more houses
* Added a fog shader for the boss area to make it more spooky

### Changed

* Change the game name to WonderJam
* Found and fixed a [bug in Godot](https://github.com/godotengine/godot/pull/45036) that causes our game to lock up when polling the `AudioServer`. Will need to export the game using a custom version as the fix likely won't be in Godot official in time
* Broke the beat detection up into 3 classes:
    * `BackgroundMusicAnalyzer` - Which handles the analysis of the muted background song. This will emit `preload_done` when a song is ready
    * `BPMDetector` - Which identifies the BPM for the song and exposes a `get_beats_now` method that will return any beats (following the BPM) that should be displayed for the current frame
    * `PeakDetector` - Which identifies peaks in the audio and exposes a `get_peaks_now` method (along with other frequency-specific ones) that returns the peaks for different frequency ranges for the current frame

### Removed

* Enemies no longer collide (was making things complicated)

## Unreleased - 2021-01-02

### Added

* Added stars to home scene
* Added snowflakes
* Started work on button to select file in web export.
* Added smoke to house
* Added base spooky tree boss enemy
    * Added initial body, flames, etc. - Still needs limbs, skeleton, and animations
* Added a fade layer to fade in and out between scene transitions
* Added placeholder title logo and prompt text
* Added a test `BelowClouds` scene to hold the boss for now
* Created a "flow" of sorts for starting the game, selecting a songs, etc.
* Created an intro animation
* Added Troy Story Games logo

### Changed

* Tweak footprint dissolve rate
* rearranged some files.
* Changed the title screen and main menu around
* Broke home scene into peaces so the "outside house" area could be used in both the main menu and as a playable area
* Game now starts inside the house

### Removed

* Removed the progress bar (for now)
* Removed Godot `icon.png`

## Unreleased - 2021-01-01

### Added

* Laser beam gradient (not used yet)
* Background mountain art and stars
* Explode particle effect
* Particle scene for the new star texture
* Enemy spawner that spawns enemies based on the music
* Basic Flame enemy movement script
* Opaque version of the background trees to go in front of the mountains


### Changed

* Flames, WideFlames, and Dissolve effects are all static now (e.g. we're not making a new noise texture every time)
    * Creating a unique noise texture for each object was adding considerable overhead
* Updated all the scenes that inherit the above mentioned effects to use the static noise texture
* Updated player home areas to have more trees
* Added the new mountains to the high background
* Added stars to the high background
* Added a hitbox to the laser
* Added damage to the laser
* Made enemies kill-able

### Removed

* Removed the `Flames.gd` script - We don't need code for the flames anymore.

## Unreleased - 2020-12-31 (pt. 3)

### Changed

* Better idle animation frame

## Unreleased - 2020-12-31 (pt. 2)

### Added

* Interior of house scene
* New rounded wide fire gradient for the fireplace
* Added histagram visualizer to the `AboveClouds` scene
* Added ability to move between the house and outside
* Added an `EnemyStats` scene to track enemy health
* Added a custom HTML file for the HTML export template that handles drag-n-drop so players can add their songs when playing in a browser

### Changed

* Histagram visualizer is now a tool so you can see what's going on in the editor
* Histagram visualizer improved to be more configurable via exports
* Histagram visualizer code cleanup
* Fixed animation not always stopping on first frame
* Tree and bush naming cleanup
* Updated the ice beam to create the pulse animation in code so it can be configured entirely via the exports
* Updated the base `GameArea` scene to contain some `Node`-type nodes to organize the scenese a bit so they're not so cluttered
* Tweaked the min and max frequency ranges

## Unreleased - 2020-12-31

### Added

* Snow dirt path back and front instead of a single image
* Snow path (no dirt) for the home area
* Player's footprint (for home area)
* Made footprints appear and disolve as the player walks
* Added a "snow accumulation" gradient (which is just a solid white-ish color)
* Added an `Events` auto-load to handle global events
   * Added footprint signal so that the footprint could be placed on the path node rather than the player node

### Modified

* Added noise options as export variables to the `DisolvingSprite` base scene
* Added footprint code to the player scene

### Removed

* Removed the snow dirt path image and broke it into a foreground/background path for more layers

## Unreleased - 2020-12-30

### Added

* Laser shader
* Better laser pulsing logic

### Changed

* Laser particle size and amount

## Unreleased - 2020-12-29

### Added

* Walking animations for winter guy (Aseprite + png sprite sheet + scene modifications)
* An `get_energy_for_frequency_range` helper function 

### Changed

* Fixed glowing for laser so it looks better (still needs more work)
* Added a stadard deviation helper to Utils (for beat analysis)
* Massively improved beat detection
* Started added energy and further beat analysis (WIP - Detect lulls, drops, and BPM eventually)
* Modified laser to pulse to the beat
* Improved scrolling background to the beat

## Unreleased - 2020-12-28 (pt. 3)

### Added

* A wider non-circular fire
* An enemy base scene
* An initial fire enemy using the flames shader
* Some more art
* Added default export locations and setup basic parameters for Windows, Android, and Web export
* Laser ice beam thing based on https://github.com/GDQuest/godot-2d-space-game

### Changed

* Broke the flame shader out into it's own object along with the flames material so they can be reused
* Modified the flame shader to set custom flame colors and some other tweaks

## Unreleased - 2020-12-28 (pt. 2)

### Added

* Added `CollisionWalls` - A basic scene used to create the invisible walls to prevent the player from going off screen when above clouds
* Added `GameArea` base scene which is used as the base scene for everything in the `MainGame` folder - Has a darkness layer and a world environment for lighting and glow effects

### Changed

* Improved flames lighting and embers 
* Modified noise texture utilitiy to default to a 512x512 texture so you don't __have__ to specify if you don't need to
* Modifed the `AboveClouds` scene to responde to the beat
* Modified the `BeatDetector` to track LOW, MED, and HIGH range of beats based on frequency split being used (default 24)
* Updated the player's home area
* Updated all tress, bushes and other in-game sprites to position them differnetly (this was an attempt to make use of YSort which I abandoned - We can switch them back but leaving them the way they are now doesn't hurt) (TLDR - YSort isn't gonna work here which is fine)
* Modified the base Parallax background sceneto have a canvas modulate so the darkness of the background can be controlled
* Boosted the snow particle's "self-modulate" to be over 100% so it shines through the darkness layer

### Removed

* Deleted the standalone `TheDarkness` scene in favor of putting the `CavasModulate` node inside both the `GameArea` and `ParallaxBackground` scenes

## Unreleased - 2020-12-28

### Added

* Flame shader with 2D light, glow, and embers
* Art for house
* Art for `Tree 2`
* Art for clouds
* Cloud particle effect
* A `UI` scene that has just the progress bar for now (just to break the code up)
* A `HighBackground` scene (similar to `LowBackground`) - It's the Parallax background we display above the clouds
* A temporary `TEST` scene that I'm using to test out the flame shader

### Changed

* `BeatDetector` is an auto-load singleton now
* Home level now has player house, trees, bushes, etc.
* Transition from song selection through to playing is in place
* Simplified player movement
* Organized code layout - `MainGame` is now a folder which contains the `House` and `PlaySong` subfolders.
    * `House` contains the players "loading" scene. This is where the player will go after they select a song. They will be able to walk around for a few seconds while the song loads and when they're ready they can do soemthing (idk) to start the song
    * `PlaySong` contains the `AboveClouds` scene which is going to be the main gameplay scene. We still need to make a scene for "below the clouds" when the player comes in to "winterize" a location

## Removed

* `MainInstances.tres` and `.gd` - Don't need them anymore now that `BeatDetector` is a singleton
* Removed player jump for now - Probably don't need to overegnineer player ground movement since it's not really main-game

## Unreleased - 2020-12-27

### Added

* Parallax background
* Bunch of new art

### Changed

* Player physics and mechanics to have a walking and flying mode

### Removed

* Removed test art

## Unreleased - 2020-12-02

### Added

* New MicroGame `ConnectTheDots` - Still Work-in-progress (b/c you can cheat) - But the basics are there.
  * Works on phone

## Unreleased - 2020-12-24

### Added

* `AudioPlayer` auto-load singleton to manage the main and background audio players
* Several new art assets
* Improvements to the beat-detection algorithm
    * background analysis runs in a thread rather than tieing it to the framerate
    * elliminate several duplicate beats
* Created this changelog to track progress

### Changes

* Code organization, etc.