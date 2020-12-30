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