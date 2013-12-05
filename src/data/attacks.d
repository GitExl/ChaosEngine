module data.attacks;

import behaviour.attack;

import game.actor;
import game.level;

import data.anims;


alias void function(AnimIndex, Actor) AttackFunction;


struct Attack {
    AttackIndex type;
    int delay;
    int speed;
    int distance;
    int damage;
}

struct AttackInfo {
    AttackFunction behaviour;
    AnimIndex animIndex;
}


static const AttackInfo[] ATTACK_INFO = [
    {null,           AnimIndex.DUMMY}, // None, dummy.
    {null,           AnimIndex.UNKNOWN_1}, // Clone\robot attack
    {&attackMercenary, AnimIndex.DUMMY}, // Mercenary attack
    {&attackNavvie,    AnimIndex.DUMMY}, // Navvie attack
    {&attackThrow,     AnimIndex.UNKNOWN_1}, // Same as clone\robot attack?
    {&attackBrigand,   AnimIndex.DUMMY}, // Brigand attack
    {&attackThrow,     AnimIndex.UNKNOWN_1}, // Same as clone\robot attack?
    {&attackThug,      AnimIndex.DUMMY}, // Thug attack
    {&attackPreacher,  AnimIndex.DUMMY}, // Preacher attack
    {&attackThrow,     AnimIndex.UNKNOWN_1}, // Same as clone\robot attack?
    {&attackGentleman, AnimIndex.DUMMY}, // Gentleman attack
    {null,           AnimIndex.DUMMY}, // Stream of mercenary projectiles?
    {null,           AnimIndex.DUMMY}, // DeathHead Turret bullet
    {null,           AnimIndex.DUMMY}, // Compost pop 1
    {null,           AnimIndex.DUMMY}, // Emplacement missile
    {null,           AnimIndex.DUMMY}, // Fireman attack
    {null,           AnimIndex.DUMMY}, // Thumper ball
    {null,           AnimIndex.DUMMY}, // Frog leap
    {null,           AnimIndex.DUMMY}, // Unknown
    {null,           AnimIndex.DUMMY}, // Compost pop 2
    {&attackThrow,   AnimIndex.UNKNOWN_1}, // Same as clone\robot attack?
    {&attackThrow,   AnimIndex.ROCK_1}, // Rock throw
    {&attackThrow,   AnimIndex.ROCK_3}, // Beast\sewer attack
    {null,           AnimIndex.DUMMY}, // Unknown
    {&attackThrow,   AnimIndex.ROCK_2}, // Lizardman projectile
    {null,           AnimIndex.DUMMY}, // Blob projectile
    {&attackThrow,   AnimIndex.ROCK_4}, // Dustdevil projectile
    {null,           AnimIndex.UNKNOWN_1}, // Kangaroo
    {null,           AnimIndex.DUMMY}, // Lobber lob
    {null,           AnimIndex.DUMMY}, // "Laser"
    {null,           AnimIndex.DUMMY}, // Emplacement missile 2
    {&attackThrow,   AnimIndex.NODE_SHIELD}, // Active node shield
    {null,           AnimIndex.DUMMY}, // Baron's attack
    {null,           AnimIndex.DUMMY}, // Baron's bomb throw
    {&attackThrow,   AnimIndex.UNKNOWN_2}, // Guard\hand attack
    {&attackThrow,   AnimIndex.UNKNOWN_2}, // Gyro\Mechanic projectile
    {null,           AnimIndex.DUMMY}, // Halftrack attack
    {null,           AnimIndex.DUMMY}, // Missing link attack
];

enum AttackIndex : int {
    NONE,
    CLONEGUN1,
    MERCENARYGUN,
    NAVVIEGUN,
    CLONEGUN2,
    BRIGANDGUN,
    CLONEGUN3,
    THUGGUN,
    PREACHERGUN,
    CLONEGUN4,
    GENTLEMANGUN,
    MERCENARYSTREAM,
    DEATHHEAD,
    COMPOST1,
    EMPLACEMENT1,
    FIREMAN,
    THUMPER,
    FROGLEAP,
    UNKNOWN1,
    COMPOST2,
    CLONEGUN5,
    ROCK,
    BEASTSEWER,
    UNKNOWN2,
    LIZARDMAN,
    BLOB,
    DUSTDEVIL,
    KANGAROO,
    LOBBER,
    LASER,
    EMPLACEMENT2,
    NODESHIELD,
    BARON,
    BARONBOMB,
    GUARDHAND,
    GYROMECHANIC,
    HALFTRACK,
    MISSINGLINK,
}