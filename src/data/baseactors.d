module data.baseactors;

import behaviour.player;
import behaviour.rockman;
import behaviour.anim;
import behaviour.node;

import data.collision;

import game.actor;
import game.game;

import render.renderer;


enum DeathType : ubyte {
    NONE = 0,
    POP_TINY = 1,
    POP_SMALL = 2,
    EXPLODE_BIG = 3,
    EXPLODE_SMALL = 4,
}


alias void function(Actor, Game) BehaviourFuncUpdate;
alias bool function(Actor) BehaviourFuncDeath;
alias void function(Actor) BehaviourFuncInit;


struct BaseActor {
    TextureRef textureRef;

    int width;
    int height;

    bool hasRotations;

    int spawnFrame;
    int spawnX;
    int spawnY;

    int projectileOffsetIndex;

    ubyte collisionGroup;

    uint flags;
    DeathType deathType;

    BehaviourFuncInit behaviourFuncInit;
    BehaviourFuncUpdate behaviourFuncUpdate;
    BehaviourFuncDeath behaviourFuncDeath;
}

static BaseActor[] BASEACTOR_INFO = [
    // Sewer
    {
        TextureRef("sprite_sewer"),
        32, 32,
        true,
        16,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Brigand player
    {
        TextureRef("sprite_brigand"),
        32, 32,
        true,
        0,
        0,
        0,
        16,
        CollideIndex.PLAYERS,
        ActorFlags.PUSHDEATH | ActorFlags.INTERACTS,
        DeathType.EXPLODE_BIG,
        null,
        &playerUpdate,
        null
    },

    // Mercenary player
    {
        TextureRef("sprite_mercenary"),
        32, 32,
        true,
        0,
        0,
        0,
        18,
        CollideIndex.PLAYERS,
        ActorFlags.PUSHDEATH | ActorFlags.INTERACTS,
        DeathType.EXPLODE_BIG,
        null,
        &playerUpdate,
        null
    },

    // Beetle
    {
        TextureRef("sprite_beetle"),
        16, 16,
        true,
        13,
        0,
        0,
        7,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Gentleman player
    {
        TextureRef("sprite_gentleman"),
        32, 32,
        true,
        0,
        0,
        0,
        17,
        CollideIndex.PLAYERS,
        ActorFlags.PUSHDEATH | ActorFlags.INTERACTS,
        DeathType.EXPLODE_BIG,
        null,
        &playerUpdate,
        null
    },

    // Navvie player
    {
        TextureRef("sprite_navvie"),
        32, 32,
        true,
        0,
        0,
        0,
        14,
        CollideIndex.PLAYERS,
        ActorFlags.PUSHDEATH | ActorFlags.INTERACTS,
        DeathType.EXPLODE_BIG,
        null,
        &playerUpdate,
        null
    },

    // Thug player
    {
        TextureRef("sprite_thug"),
        32, 32,
        true,
        0,
        0,
        0,
        19,
        CollideIndex.PLAYERS,
        ActorFlags.PUSHDEATH | ActorFlags.INTERACTS,
        DeathType.EXPLODE_BIG,
        null,
        &playerUpdate,
        null
    },

    // Dormant node
    {
        TextureRef("sprite_node"),
        16, 48,
        false,
        0,
        0,
        0,
        2,
        CollideIndex.NODES,
        ActorFlags.IMMOBILE | ActorFlags.SOLID,
        DeathType.NONE,
        &nodeInit,
        &nodeUpdate,
        &nodeDeath
    },

    // Active node
    {
        TextureRef("sprite_node"),
        16, 48,
        false,
        3,
        0,
        0,
        2,
        CollideIndex.EMPTY,
        ActorFlags.NONE,
        DeathType.NONE,
        &nodeInit,
        &nodeUpdate,
        &nodeDeath
    },

    // DeathHead turret
    {
        TextureRef("sprite_dhturret"),
        32, 32,
        false,
        0,
        0,
        0,
        9,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Bouncing blob
    {
        TextureRef("sprite_blob"),
        32, 32,
        false,
        0,
        0,
        0,
        10,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Rock man
    {
        TextureRef("sprite_rockman"),
        32, 32,
        true,
        16,
        0,
        0,
        11,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Spider
    {
        TextureRef("sprite_spider"),
        16, 16,
        true,
        13,
        0,
        0,
        12,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Thumper
    {
        TextureRef("sprite_thumper"),
        16, 16,
        false,
        0,
        0,
        0,
        4,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Compost heap
    {
        TextureRef("sprite_compost"),
        32, 32,
        false,
        0,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Missing link
    {
        TextureRef("sprite_missinglink"),
        32, 32,
        true,
        11,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Fire man
    {
        TextureRef("sprite_fireman"),
        16, 16,
        true,
        16,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Emplacement
    {
        TextureRef("sprite_emplacement"),
        32, 32,
        true,
        0,
        0,
        0,
        20,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Mechanic
    {
        TextureRef("sprite_mechanic"),
        16, 16,
        true,
        16,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Gyro
    {
        TextureRef("sprite_gyro"),
        32, 32,
        false,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Frogger
    {
        TextureRef("sprite_frogger"),
        32, 32,
        true,
        20,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Lizard man
    {
        TextureRef("sprite_lizardman"),
        32, 32,
        true,
        16,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Slug
    {
        TextureRef("sprite_slug"),
        16, 16,
        true,
        16,
        0,
        0,
        13,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Guard
    {
        TextureRef("sprite_guard"),
        32, 32,
        true,
        15,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Preacher player
    {
        TextureRef("sprite_preacher"),
        32, 32,
        true,
        0,
        0,
        0,
        15,
        CollideIndex.PLAYERS,
        ActorFlags.PUSHDEATH | ActorFlags.INTERACTS,
        DeathType.EXPLODE_BIG,
        null,
        &playerUpdate,
        null
    },

    // Dust devil
    {
        TextureRef("sprite_dustdevil"),
        32, 32,
        false,
        0,
        0,
        0,
        5,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Kangaroo
    {
        TextureRef("sprite_kangaroo"),
        32, 32,
        true,
        17,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Beast
    {
        TextureRef("sprite_beast"),
        32, 32,
        true,
        0,
        0,
        0,
        21,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Steam jet
    {
        TextureRef("sprite_steamjet"),
        16, 16,
        false,
        0,
        8,
        3,
        6,
        CollideIndex.EMPTY,
        ActorFlags.IMMOBILE,
        DeathType.NONE,
        null,
        null,
        null
    },

    // Stone watcher
    {
        TextureRef("sprite_stonewatcher"),
        32, 32,
        false,
        0,
        0,
        0,
        3,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Spider cocoon
    {
        TextureRef("sprite_cocoon"),
        32, 32,
        false,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Lobber
    {
        TextureRef("sprite_lobber"),
        32, 32,
        true,
        0,
        0,
        0,
        22,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Hand
    {
        TextureRef("sprite_hand"),
        32, 32,
        true,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Mace
    {
        TextureRef("sprite_mace"),
        32, 32,
        false,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Rat
    {
        TextureRef("sprite_rat"),
        16, 16,
        true,
        13,
        0,
        0,
        12,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Energy ball
    {
        TextureRef("sprite_energyball"),
        32, 32,
        true,
        0,
        8,
        16,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Robot
    {
        TextureRef("sprite_robot"),
        32, 32,
        true,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        null,
        null
    },

    // Halftrack
    {
        TextureRef("sprite_halftrack"),
        32, 32,
        true,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Revving dome A
    {
        TextureRef("sprite_revvingdome"),
        16, 16,
        false,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // Laser shot
    {
        TextureRef("sprite_expl16"),
        16, 16,
        false,
        0,
        0,
        0,
        0,
        CollideIndex.EMPTY,
        ActorFlags.NONE,
        DeathType.NONE,
        null,
        null,
        null
    },

    // Revving dome B
    {
        TextureRef("sprite_revvingdome"),
        16, 16,
        false,
        0,
        0,
        0,
        6,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_SMALL,
        null,
        null,
        null
    },

    // The Baron
    {
        TextureRef("sprite_thebaron"),
        16, 16,
        false,
        0,
        0,
        -8,
        23,
        CollideIndex.MONSTERS,
        ActorFlags.IMMOBILE,
        DeathType.NONE,
        null,
        null,
        null
    },

    // Player clone
    {
        TextureRef("sprite_mercenary"),
        32, 32,
        true,
        16,
        0,
        0,
        0,
        CollideIndex.MONSTERS,
        ActorFlags.NONE,
        DeathType.EXPLODE_BIG,
        null,
        &rockmanUpdate,
        null
    },

    // Anim 8
    {
        TextureRef("sprite_sp8"),
        8, 8,
        false,
        0,
        0,
        0,
        0,
        CollideIndex.EMPTY,
        ActorFlags.ONTOP,
        DeathType.NONE,
        null,
        &animUpdate,
        null
    },

    // Anim 16
    {
        TextureRef("sprite_expl16"),
        16, 16,
        false,
        0,
        0,
        0,
        0,
        CollideIndex.EMPTY,
        ActorFlags.ONTOP,
        DeathType.NONE,
        null,
        &animUpdate,
        null
    },

    // Anim 32
    {
        TextureRef("sprite_expl32"),
        32, 32,
        false,
        0,
        0,
        0,
        0,
        CollideIndex.EMPTY,
        ActorFlags.ONTOP,
        DeathType.NONE,
        null,
        &animUpdate,
        null
    },
];

enum BaseActorIndex : int {
    SEWER,
    BRIGAND,
    MERCENARY,
    BEETLE,
    GENTLEMAN,
    NAVVIE,
    THUG,
    NODE_DORMANT,
    NODE_ACTIVE,
    DHTURRET,
    BLOB,
    ROCKMAN,
    SPIDER,
    THUMPER,
    COMPOST,
    MISSINGLINK,
    FIREMAN,
    EMPLACEMENT,
    MECHANIC,
    GYRO,
    FROGGER,
    LIZARDMAN,
    SLUG,
    GUARD,
    PREACHER,
    DUSTDEVIL,
    KANGAROO,
    BEAST,
    STEAMJET,
    STONEWATCHER,
    COCOON,
    LOBBER,
    HAND,
    MACE,
    RAT,
    ENERGYBALL,
    ROBOT,
    HALFTRACK,
    REVDOME1,
    EXPL_16,
    REVDOME2,
    BARON,
    CLONE,
    ANIM8,
    ANIM16,
    ANIM32,
}

immutable short[][] PROJECTILE_OFFSETS = [
    [
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
    ],
    [
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
    ],
    [
        0, 0,
        0, 0,
        0, -16,
        0, 0,
        0, 0,
        0, 0,
        0, -8,
        0, 0,
    ],
    [
        0, 0,
        0, 0,
        0, 0,
        4, 16,
        0, 16,
        -2, 16,
        0, 0,
        0, 0,
    ],
    [
        -1, -5,
        -1, -5,
        -1, -5,
        -1, -5,
        -1, -5,
        -1, -5,
        -1, -5,
        -1, -5,
    ],
    [
        8, 0,
        8, 8,
        0, 8,
        -8, 8,
        -8, 0,
        -8, -8,
        0, -8,
        8, -8,
    ],
    [
        0, -12,
        0, -8,
        6, -8,
        0, -4,
        0, 2,
        0, 0,
        -6, -6,
        6, -8,
    ],
    [
        8, -2,
        13, 0,
        16, 5,
        12, 10,
        8, 13,
        3, 8,
        0, 4,
        3, 0,
    ],
    [
        -1, 5,
        -1, 5,
        -1, 5,
        -1, 5,
        -1, 5,
        -1, 5,
        -1, 5,
        -1, 5,
    ],
    [
        0, -17,
        9, -13,
        16, -2,
        8, 4,
        0, 8,
        -9, 3,
        -16, -2,
        -9, -13,
    ],
    [
        8, 14,
        8, 14,
        8, 14,
        8, 14,
        8, 14,
        8, 14,
        8, 14,
        8, 14,
    ],
    [
        0, -19,
        7, -19,
        8, -5,
        2, -2,
        0, -3,
        -2, -3,
        -8, -3,
        -8, -18,
    ],
    [
        8, -2,
        13, 0,
        16, 5,
        12, 10,
        8, 13,
        3, 8,
        0, 4,
        3, 0,
    ],
    [
        0, -2,
        0, 0,
        -2, 2,
        0, 0,
        0, 0,
        0, 0,
        2, 2,
        0, 0,
    ],
    [
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
    ],
    [
        0, 0,
        0, -2,
        -4, 0,
        -5, -7,
        0, -8,
        5, -7,
        5, 0,
        2, -1,
    ],
    [
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, -2,
        0, 0,
        0, 0,
    ],
    [
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
    ],
    [
        4, -14,
        4, 0,
        8, 2,
        0, 0,
        4, 12,
        0, 6,
        -8, 4,
        2, 0,
    ],
    [
        4, 0,
        4, 0,
        0, 4,
        0, 0,
        2, 0,
        4, 0,
        0, 2,
        0, 0,
    ],
    [
        0, -32,
        16, -24,
        24, -8,
        16, 8,
        0, 16,
        -16, 8,
        -24, -8,
        -16, -24,
    ],
    [
        0, -8,
        12, -8,
        16, 4,
        10, 12,
        0, 16,
        -12, 12,
        -16, 4,
        -14, -8,
    ],
    [
        0, -8,
        8, 0,
        8, 0,
        4, 0,
        0, 4,
        -4, 0,
        -10, 0,
        -8, 0,
    ],
    [
        2, 2,
        -8, 8,
        16, 0,
        -12, 8,
        -4, -8,
        0, -4,
        0, -4,
        2, 4,
    ],
];
