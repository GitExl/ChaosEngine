module data.characters;

import data.baseactors;
import data.text;
import data.attacks;


struct SkillLevel {
    int skill;
    int specialCount;
    int health;
    int speed;
    int wisdom;
}

struct CharacterInfo {
    int nameStringIndex;
    int baseActorIndex;

    int price;

    SkillLevel[] skillLevels;
    ubyte[] specialPowers;

    AttackIndex attackIndex;
    int autoFireDelay;

    int unknown1;
    int unknown2;
    int unknown3;
    int unknown4;
    int unknown5;
}

static const CharacterInfo[] CHARACTER_INFO = [
    // Brigand.
    {
	    Text.CHARACTER_0,
	    BaseActorIndex.BRIGAND,
	    2750,
        [
            {0, 1, 25, 7, 2},
            {2, 1, 35, 7, 3},
            {4, 1, 45, 7, 4},
            {6, 2, 50, 7, 5},
            {8, 2, 55, 7, 5},
            {10, 2, 60, 7, 6},
            {11, 2, 65, 7, 7},
            {12, 3, 70, 8, 7},
            {13, 3, 75, 8, 8},
            {14, 3, 80, 8, 8},
            {15, 3, 85, 9, 9},
        ],
	    [1, 11, 10],
	    AttackIndex.BRIGANDGUN,
	    5,
	    3, 8, 6425, 10, 3
    },

    // Mercenary.
    {
	    Text.CHARACTER_1,
	    BaseActorIndex.MERCENARY,
	    2750,
        [
            {0, 1, 25, 7, 2},
            {2, 1, 35, 7, 3},
            {4, 1, 45, 7, 4},
            {5, 2, 50, 7, 5},
            {6, 2, 55, 7, 5},
            {7, 2, 60, 7, 6},
            {8, 2, 65, 7, 7},
            {9, 3, 70, 8, 7},
            {10, 3, 75, 8, 8},
            {11, 3, 80, 8, 8},
            {12, 3, 85, 9, 9},
        ],
	    [0, 12, 5],
	    AttackIndex.MERCENARYGUN,
	    5,
	    3, 6, 6425, 4, 3
    },

    // Gentleman.
    {
	    Text.CHARACTER_2,
	    BaseActorIndex.GENTLEMAN,
	    2500,
        [
            {0, 1, 20, 7, 2},
            {2, 1, 25, 7, 3},
            {4, 2, 30, 7, 5},
            {6, 2, 35, 7, 6},
            {7, 2, 40, 8, 7},
            {8, 3, 45, 8, 8},
            {9, 3, 50, 8, 9},
            {10, 3, 55, 9, 9},
            {11, 4, 60, 9, 10},
            {12, 4, 65, 9, 10},
            {13, 4, 70, 10, 10},
        ],
	    [2, 10, 4, 8],
	    AttackIndex.GENTLEMANGUN,
	    5,
	    14, 8, 5140, 10, 3
    },

    // Navvie.
    {
	    Text.CHARACTER_3,
	    BaseActorIndex.NAVVIE,
	    3000,
        [
            {0, 1, 30, 6, 1},
            {2, 1, 40, 6, 2},
            {4, 1, 50, 6, 3},
            {6, 1, 60, 6, 4},
            {8, 2, 70, 7, 4},
            {10, 2, 75, 7, 5},
            {12, 2, 80, 7, 5},
            {13, 2, 85, 8, 6},
            {14, 2, 90, 8, 6},
            {15, 2, 95, 8, 7},
            {16, 2, 100, 8, 8},
        ],
	    [13, 1],
	    AttackIndex.NAVVIEGUN,
	    5,
	    1, 6, 7710, 0, 3
    },

    // Thug.
    {
	    Text.CHARACTER_4,
	    BaseActorIndex.THUG,
	    3000,
        [
            {0, 1, 30, 6, 1},
            {2, 1, 40, 6, 2},
            {4, 1, 50, 6, 3},
            {6, 1, 60, 6, 4},
            {8, 2, 70, 7, 4},
            {10, 2, 75, 7, 5},
            {11, 2, 80, 7, 5},
            {12, 2, 85, 8, 6},
            {13, 2, 90, 8, 6},
            {14, 2, 95, 8, 7},
            {15, 2, 100, 8, 8},
        ],
	    [11, 9],
	    AttackIndex.THUGGUN,
	    5,
	    2, 6, 7710, 5, 3
    },

    // Preacher.
    {
	    Text.CHARACTER_5,
	    BaseActorIndex.PREACHER,
	    2500,
        [
            {0, 1, 15, 7, 3},
            {2, 1, 20, 7, 4},
            {4, 2, 25, 7, 5},
            {6, 2, 30, 7, 6},
            {8, 2, 35, 8, 7},
            {9, 3, 40, 8, 8},
            {10, 3, 45, 8, 9},
            {11, 3, 50, 9, 9},
            {12, 4, 55, 9, 10},
            {13, 4, 60, 9, 10},
            {14, 4, 65, 10, 10},
        ],
	    [5, 2, 7, 6],
	    AttackIndex.PREACHERGUN,
	    5,
	    14, 7, 5140, 10, 3
    },
];

enum CharacterIndex : ubyte {
    BRIGAND,
    MERCENARY,
    GENTLEMAN,
    NAVVIE,
    THUG,
    PREACHER,
}