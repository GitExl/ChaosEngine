module main;

import std.stdio;
import std.conv;
import std.string;

import derelict.sdl2.sdl;

import game.game;


int main(string[] argv) {
    DerelictSDL2.load();

    SDL_Init(SDL_INIT_VIDEO);

    Game game = new Game();

    uint levelIndex = 0;
    foreach (int index, string arg; argv) {
        if (toLower(arg) == "--dump-textures") {
            writeln("Dumping textures to /textures...");
            game.dumpTextures();
        
        } else if (toLower(arg) == "--level") {
            if (argv.length <= index + 1) {
                writeln("Not enough arguments for --level.");
            } else {
                levelIndex = to!uint(argv[index + 1]);
            }

        }
    }
    
    game.levelEnter(null, levelIndex, 0);
    game.loop();
    game.destroy();

    SDL_Quit();

    return 0;
}
