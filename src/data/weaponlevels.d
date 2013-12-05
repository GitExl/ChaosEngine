module data.weaponlevels;

import data.anims;

// Brigand.
// Multipled bullets lined up.
struct WeaponLevelRifle {
    ubyte damage;
    AnimIndex animIndex;
    ubyte count;
    bool penetrates;
}

const WeaponLevelRifle[] LEVELS_BRIGAND = [
    {7,  AnimIndex.BRIGAND_1, 1, false},
    {9,  AnimIndex.BRIGAND_2, 1, false},
    {9,  AnimIndex.BRIGAND_3, 1, true},
    {11, AnimIndex.BRIGAND_4, 1, true},
    {7,  AnimIndex.BRIGAND_1, 2, false},
    {8,  AnimIndex.BRIGAND_2, 2, false},
    {8,  AnimIndex.BRIGAND_3, 2, true},
    {9,  AnimIndex.BRIGAND_4, 2, true},
    {7,  AnimIndex.BRIGAND_1, 3, false},
    {8,  AnimIndex.BRIGAND_2, 3, false},
    {8,  AnimIndex.BRIGAND_3, 3, true},
    {9,  AnimIndex.BRIGAND_4, 3, true},
    {7,  AnimIndex.BRIGAND_1, 4, false},
    {8,  AnimIndex.BRIGAND_2, 4, false},
    {8,  AnimIndex.BRIGAND_3, 4, true},
    {9,  AnimIndex.BRIGAND_4, 4, true},
];

// Mercenary.
// Black and gold balls fired in a spread.
struct WeaponLevelBallGun {
    ubyte damage;
    ubyte count;
    ubyte goldCount;
    ubyte spread;
    bool hasDelay;
}

const WeaponLevelBallGun[] LEVELS_MERCENARY = [
    {4, 2, 0, 3, true},
    {5, 2, 1, 3, true},
    {4, 3, 1, 3, true},
    {4, 3, 2, 4, true},
    {5, 3, 2, 4, true},
    {4, 4, 2, 4, true},
    {4, 4, 3, 5, true},
    {5, 4, 3, 5, true},
    {5, 5, 3, 5, true},
    {5, 5, 4, 6, true},
    {6, 5, 4, 6, true},
    {6, 6, 5, 6, true},
    {6, 6, 6, 7, true},
];

// Gentleman.
// 3 energy balls, smallest ball at the back of the row.
struct WeaponLevelPistol {
    ubyte damage;
    ubyte rows;
    ubyte goldCount;
}

const WeaponLevelPistol[] LEVELS_GENTLEMAN = [
    {5,  1, 0},
    {6,  1, 1},
    {7,  1, 2},
    {8,  1, 3},
    {6,  2, 0},
    {7,  2, 1},
    {8,  2, 2},
    {9,  2, 3},
    {10, 2, 3},
    {11, 2, 3},
    {12, 2, 3},
    {13, 2, 3},
    {14, 2, 3},
    {15, 2, 3},
];

// Navvie.
// Bullets, same behaviour as brigand.
const WeaponLevelRifle[] LEVELS_NAVVIE = [
    {8,  AnimIndex.NAVVIE_1, 1, false},
    {10, AnimIndex.NAVVIE_2, 1, true},
    {10, AnimIndex.NAVVIE_3, 1, true},
    {12, AnimIndex.NAVVIE_4, 1, false},
    {8,  AnimIndex.NAVVIE_1, 2, false},
    {9,  AnimIndex.NAVVIE_2, 2, true},
    {9,  AnimIndex.NAVVIE_3, 2, true},
    {10, AnimIndex.NAVVIE_4, 2, false},
    {8,  AnimIndex.NAVVIE_1, 3, false},
    {9,  AnimIndex.NAVVIE_2, 3, true},
    {9,  AnimIndex.NAVVIE_3, 3, true},
    {10, AnimIndex.NAVVIE_4, 3, false},
    {8,  AnimIndex.NAVVIE_1, 4, false},
    {9,  AnimIndex.NAVVIE_2, 4, true},
    {9,  AnimIndex.NAVVIE_3, 4, true},
    {10, AnimIndex.NAVVIE_4, 4, true},
    {11, AnimIndex.NAVVIE_4, 4, false},
];

// Thug.
// BallGun, same behaviour as mercenary.
const WeaponLevelBallGun[] LEVELS_THUG = [
    {4, 2, 0, 3, false},
    {5, 2, 1, 3, false},
    {4, 3, 1, 3, false},
    {4, 3, 2, 4, false},
    {5, 3, 2, 4, false},
    {4, 4, 2, 4, false},
    {4, 4, 3, 5, false},
    {5, 4, 3, 5, false},
    {5, 5, 3, 5, false},
    {5, 5, 4, 6, false},
    {6, 5, 4, 6, false},
    {6, 6, 4, 6, false},
    {6, 6, 5, 7, false},
    {7, 6, 5, 7, false},
    {7, 7, 6, 7, false},
    {7, 7, 7, 8, false},
];

// Preacher.
// 5 small balls in a row, close together. Does not explode upon distance expiration.
struct WeaponLevelLightGun {
    ubyte damage;
    AnimIndex animIndex;
    ubyte actorDistance;
}

const WeaponLevelLightGun[] LEVELS_PREACHER = [
    {5,  AnimIndex.PREACHER_1, 3},
    {7,  AnimIndex.PREACHER_2, 3},
    {9,  AnimIndex.PREACHER_3, 4},
    {11, AnimIndex.PREACHER_4, 4},
    {13, AnimIndex.PREACHER_5, 5},
    {15, AnimIndex.PREACHER_6, 5},
    {17, AnimIndex.PREACHER_7, 6},
    {19, AnimIndex.PREACHER_8, 6},
    {21, AnimIndex.PREACHER_8, 6},
    {23, AnimIndex.PREACHER_8, 6},
    {25, AnimIndex.PREACHER_8, 6},
    {27, AnimIndex.PREACHER_8, 6},
];