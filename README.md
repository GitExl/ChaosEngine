Chaos Engine
============
A remake of the Chaos Engine CD32 engine. A lot of features are still missing, but it's in a playable state.

Running
-------
You will need CD32 game data in the ./bin/gamedata directory to run the game.

The starting level index can be specified on the commandline. For example "ChaosEngine 4" will start from the first Workshops level.

Use the commandline parameter --dump-textures to have the game output all textures into the textures directory.

Compiling
---------
This project is written in D.
http://dlang.org/

To compile it you can use the included Visual Studio 2012 project. You will need the VisualD plugin to use D with Visual Studio.
http://rainers.github.io/visuald/

You will also need to have Derelict3 installed, with the SDL2 library files built and available.
https://github.com/aldacron/Derelict3
