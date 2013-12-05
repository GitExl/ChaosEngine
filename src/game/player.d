module game.player;

import game.actor;


public struct Player {
    uint money;
    uint score;

    ubyte lives;
    ubyte weaponLevel;
    ubyte specialPowerCount;
    ubyte selectedSpecial;

    uint characterIndex;
    uint skillLevel;
    
    Actor actor;
}
