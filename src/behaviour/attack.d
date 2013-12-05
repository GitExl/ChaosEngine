module behaviour.attack;

import std.stdio;

import game.actor;
import game.level;

import data.weaponlevels;
import data.baseactors;
import data.attacks;
import data.anims;
import data.collision;

import behaviour.util;

import util.random;


public void attackBrigand(AnimIndex animIndex, Actor source) {
    attackRifle(&LEVELS_BRIGAND[source.getWeaponLevel()], source);
}

public void attackMercenary(AnimIndex animIndex, Actor source) {
    attackBallGun(&LEVELS_MERCENARY[source.getWeaponLevel()], source);
}

public void attackGentleman(AnimIndex animIndex, Actor source) {
    const WeaponLevelPistol* level = &LEVELS_GENTLEMAN[source.getWeaponLevel()];

    Attack* attack;
    AnimIndex anim;

    int spacing = 8;
    int angle = source.getAngle();
    if (angle == 2 || angle == 4 || angle == 6 || angle == 8) {
        spacing = 6;
    }

    for (int index; index < 3; index++) {
        if (index < level.goldCount) {
            anim = cast(AnimIndex)(AnimIndex.GENTLEMAN_2C - index);
        } else {
            anim = cast(AnimIndex)(AnimIndex.GENTLEMAN_1C - index);
        }

        throwProjectileSeries(anim, level.rows, 16, source, delegate void(bullet) {
            bullet.moveForward(bullet.getAngle(), spacing * index);

            bullet.setSpeed(15);

            attack = bullet.getAttack();
            attack.distance = 14;

            if (index < 2) {
                bullet.setDeathType(DeathType.NONE);
                bullet.setCollisionGroup(CollideIndex.EMPTY);
            } else {
                bullet.setFlag(ActorFlags.PENETRATES);
                attack.damage = level.damage;
            }
        });
    }
}

public void attackNavvie(AnimIndex animIndex, Actor source) {
    attackRifle(&LEVELS_NAVVIE[source.getWeaponLevel()], source);
}

public void attackThug(AnimIndex animIndex, Actor source) {
    attackBallGun(&LEVELS_THUG[source.getWeaponLevel()], source);
}

public void attackPreacher(AnimIndex animIndex, Actor source) {
}

private void attackRifle(const WeaponLevelRifle* level, Actor source) {
    Attack* attack;
    throwProjectileSeries(level.animIndex, level.count, 10, source, delegate void(bullet) {
        bullet.setSpeed(15);
        if (level.penetrates == true) {
            bullet.setFlag(ActorFlags.PENETRATES);
        }

        attack = bullet.getAttack();
        attack.damage = level.damage;
        attack.distance = 10;
    });
}

private void attackBallGun(const WeaponLevelBallGun* level, Actor source) {
    Actor bullet;
    Attack* attack;
    AnimIndex anim;

    int vX;
    int vY;
    int rX;
    int rY;

    // Calculate spread modifier value.
    // See ACHAOS 0x14A3A.
    short spreadA = level.spread & 0xf;
    short spreadB = cast(short)(1 << spreadA);
    spreadA = cast(short)(spreadB - 1);
    spreadB = spreadB >> 1;

    for (int index; index < level.count; index++) {
        if (index < level.goldCount) {
            anim = AnimIndex.MERCENARY_NAVVIE_1;
        } else {
            anim = AnimIndex.MERCENARY_NAVVIE_2;
        }

        // Throw from initial position.
        // See ACHAOS 0x14ACE.
        rX = cast(int)(getRandomUByte() & 7) - 4;
        rY = cast(int)(getRandomUByte() & 7) - 4;
        bullet = source.throwProjectile(anim, rX, rY);

        bullet.setSpeed(15);
        if (index < level.goldCount) {
            bullet.setFlag(ActorFlags.PENETRATES);
        }

        attack = bullet.getAttack();
        attack.damage = level.damage;
        attack.distance = 11;
        
        if (level.hasDelay == true) {
            attack.delay = index;
        }

        // Modify velocity to add spread.
        // See ACHAOS 0x14A3A.
        rX = (cast(int)(getRandomUByte() & spreadA) - spreadB) >> 3;
        rY = (cast(int)(getRandomUByte() & spreadA) - spreadB) >> 3;

        bullet.getVelocity(vX, vY);
        switch(source.getAngle()) {
            case 1, 5:
                bullet.setVelocity(vX + rX, vY);
                break;
            case 2, 4, 6, 8:
                bullet.setVelocity(vX + rX, vY + rY);
                break;
            case 3, 7:
                bullet.setVelocity(vX, vY + rY);
                break;
            default:
                break;
        }
    }
}

public void attackThrow(AnimIndex animIndex, Actor source) {
    source.throwProjectile(animIndex);
}