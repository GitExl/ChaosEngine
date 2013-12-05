module data.anims;

import data.attacks;


struct Anim {
    int size;

    ubyte frameIndex;
    ubyte frameCount;
    ubyte speed;

    bool hasRotations;
    bool loops;
}


static Anim[] ANIM_INFO = [
    // 32x32 sprites.
    {32, 0,  10, 1, false, false}, // Large explosion
    {32, 10, 8,  1, false, false}, // Large pop

    // 16x16 sprites.
    {16, 0,  10, 1, false, false}, // Small explosion
    {16, 10, 2,  2, false, false}, // Blob
    {16, 12, 8,  1, false, false}, // Small pop
    {16, 20, 1,  2, true,  true},  // Exhaust fire
    {16, 28, 4,  2, false, true},  // Air burst missile
    {16, 32, 4,  2, false, true},  // Rock projectile 1
    {16, 36, 1,  2, false, true},  // Lobber ball
    {16, 37, 3,  2, false, false}, // Lobber ball shatter
    {16, 40, 2,  2, false, true},  // Attract monster gadget
    {16, 42, 2,  2, false, true},  // Ground mine
    {16, 44, 8,  2, false, false}, // Baron's bomb
    {16, 52, 1,  2, true,  true},  // Node death missile
    {16, 60, 1,  2, false, true},  // Unknown
    {16, 61, 4,  2, false, true},  // Rock projectile 2
    {16, 65, 4,  2, false, true},  // Node projectile
    {16, 69, 1,  2, false, true},  // Unknown
    {16, 70, 7,  2, false, false}, // Fireman flame
    {16, 77, 1,  2, false, true},  // Unknown
    {16, 78, 1,  2, false, true},  // Unknown projectile
    {16, 80, 8,  2, false, false}, // Dynamite in air
    {16, 88, 4,  2, false, false}, // Dynamite on ground, fuse burning
    {16, 92, 4,  2, false, true},  // Unknown projectile
    {16, 96, 1,  8, false, true},  // A
    {16, 97, 1,  8, false, true},  // B
    {16, 98, 1,  8, false, true},  // C
    {16, 99, 1,  8, false, true},  // D
    
    // 8x8 sprites.
    {8, 1,   1, 1, false, true},  // Unknown projectile
    {8, 2,   1, 1, false, false},  // Gentleman projectile 1 A
    {8, 3,   1, 1, false, false},  // Gentleman projectile 1 B
    {8, 4,   1, 1, false, false},  // Gentleman projectile 1 C
    {8, 5,   1, 1, false, true},  // Gentleman projectile 2 A
    {8, 6,   1, 1, false, true},  // Gentleman projectile 2 B
    {8, 7,   1, 1, false, true},  // Gentleman projectile 2 C
    {8, 8,   8, 1, false, false}, // Bomb
    {8, 16,  1, 1, false, true},  // Mercenary ball 1
    {8, 17,  1, 1, false, true},  // Mercenary ball 2
    {8, 18, 10, 1, false, true},  // Numbers
    {8, 28,  3, 1, false, true},  // Unknown
    {8, 31,  1, 1, false, true},  // Preacher 1
    {8, 32,  1, 1, false, true},  // Preacher 2
    {8, 33,  1, 1, false, true},  // Preacher 3
    {8, 34,  1, 1, false, true},  // Preacher 4
    {8, 35,  1, 1, false, true},  // Preacher 5
    {8, 36,  1, 1, false, true},  // Preacher 6
    {8, 37,  1, 1, false, true},  // Preacher 7
    {8, 38,  1, 1, false, true},  // Preacher 8
    {8, 39,  1, 1, false, true},  // Unknown projectile
    {8, 40,  1, 1, true,  true},  // Navvie projectile 1
    {8, 48,  1, 1, true,  true},  // Navvie projectile 2
    {8, 56,  1, 1, true,  true},  // Navvie projectile 3
    {8, 64,  1, 1, true,  true},  // Navvie projectile 4
    {8, 88,  1, 1, true,  true},  // Brigand projectile 1
    {8, 96,  1, 1, true,  true},  // Brigand projectile 2
    {8, 104, 1, 1, true,  true},  // Brigand projectile 3
    {8, 112, 1, 1, true,  true},  // Brigand projectile 4
    {8, 120, 8, 1, false, true},  // Silver coin
    {8, 128, 8, 1, false, true},  // Gold coin
    {8, 136, 7, 1, false, false}, // Pickup effect
    {8, 143, 4, 1, false, true},  // Node shield
    {8, 147, 4, 1, false, true},  // Rock projectile 3
    {8, 151, 4, 1, false, true},  // Rock projectile 4
];

enum AnimIndex : int {
    // 32x32
    EXPLODE_LARGE,
    POP_LARGE,

    // 16x16
    EXPLODE_SMALL,
    BLOB,
    POP_SMALL,
    EXHAUST,
    AIR_BURST,
    ROCK_1,
    LOBBER_BALL,
    LOBBER_BALL_PIECE,
    ATTRACT_MONSTER,
    GROUND_MINE,
    BARON_BOMB,
    MISSILE,
    UNKNOWN_1,
    ROCK_2,
    UNKNOWN_6,
    UNKNOWN,
    FLAME,
    UNKNOWN_2,
    UNKNOWN_3,
    DYNAMITE_AIR,
    DYNAMITE_FUSE,
    UNKNOWN_4,
    CHAR_A,
    CHAR_B,
    CHAR_C,
    CHAR_D,

    // 8x8
    UNKNOWN_5,
    GENTLEMAN_1A,
    GENTLEMAN_1B,
    GENTLEMAN_1C,
    GENTLEMAN_2A,
    GENTLEMAN_2B,
    GENTLEMAN_2C,
    BOMB,
    MERCENARY_NAVVIE_1,
    MERCENARY_NAVVIE_2,
    NUMBERS,
    UNKNOWN_11,
    PREACHER_1,
    PREACHER_2,
    PREACHER_3,
    PREACHER_4,
    PREACHER_5,
    PREACHER_6,
    PREACHER_7,
    PREACHER_8,
    UNKNOWN_8,
    NAVVIE_1,
    NAVVIE_2,
    NAVVIE_3,
    NAVVIE_4,
    BRIGAND_1,
    BRIGAND_2,
    BRIGAND_3,
    BRIGAND_4,
    COIN_SILVER,
    COIN_GOLD,
    POP_TINY,
    NODE_SHIELD,
    ROCK_3,
    ROCK_4,

    // Dummy
    DUMMY
}