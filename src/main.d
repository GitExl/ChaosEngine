module main;

import derelict.sdl2.sdl;

import game.game;

int main(string[] argv) {
    DerelictSDL2.load();

    SDL_Init(SDL_INIT_VIDEO);

    Game game = new Game();
    game.levelEnter(null, 0, 0);
    game.loop();
    game.destroy();

    SDL_Quit();

    return 0;
}
