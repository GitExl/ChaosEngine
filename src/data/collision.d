module data.collision;


immutable ubyte[] COLLISION_MASKS = [
    0b00000000, // Empty
    0b00001100, // Players
    0b00000000, // Monsters
    0b00000000, // Pickups
    0b00000000, // Nodes
    0b00010110, // Projectiles
];

enum CollideIndex : ubyte {
    EMPTY,
    PLAYERS,
    MONSTERS,
    PICKUPS,
    NODES,
    PROJECTILES
}