module behaviour.util;

import std.math;

import game.game;
import game.actor;
import game.player;

import data.anims;


alias void delegate(Actor bullet) ProjectileThrowFunc;


private struct BulletAngleData {
    byte startX;
    byte startY;
    byte incrementX;
    byte incrementY;
}

private static BulletAngleData[] BULLET_ANGLEDATA = [
    {-1,  0,  1,  0},
    {-1, -1,  1,  1},
    { 0, -1,  0,  1},
    { 1, -1, -1,  1},
    { 1,  0, -1,  0},
    { 1,  1, -1, -1},
    { 0,  1,  0, -1},
    {-1,  1,  1, -1},
];


package int getNearestPlayer(Actor actor, Player[] players, int maxDistance) {
    int distance = 0;
    int nearestDistance = 0xffff;
    int nearestPlayer = -1;

    foreach (int index, ref Player player; players) {
        distance = getDistanceBetween(actor, player.actor);
        if (distance >= maxDistance) {
            continue;
        }

        if (distance < nearestDistance) {
            nearestPlayer = cast(byte)index;
            nearestDistance = distance;
        }
    }

    return nearestPlayer;
}

package void throwProjectileSeries(AnimIndex animIndex, int count, int distance, Actor source, ProjectileThrowFunc func) {
    int startDistance = ((count - 1) * distance) / 2;
    int angle = source.getAngle() - 1;

    int sX = BULLET_ANGLEDATA[angle].startX * startDistance;
    int sY = BULLET_ANGLEDATA[angle].startY * startDistance;
    int iX = BULLET_ANGLEDATA[angle].incrementX * distance;
    int iY = BULLET_ANGLEDATA[angle].incrementY * distance;

    for (int index; index < count; index++) {
        func(source.throwProjectile(animIndex, sX + (iX * index), sY + (iY * index)));
    }
}

package int getDistanceBetween(Actor actor1, Actor actor2) {
    return cast(int)fmax(abs(actor1.getX() - actor2.getX()), abs(actor1.getY() - actor2.getY()));
}