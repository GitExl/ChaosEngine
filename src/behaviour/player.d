module behaviour.player;

import std.stdio;
import std.random;

import game.actor;
import game.game;

import behaviour.util;


enum PlayerState : ubyte {
    STANDING,
    WALKING,
    FIRING
}

struct PlayerData {
    short delay;
    ubyte idleDelay;
    ubyte frameIndex;
    
    // Current state.
    PlayerState state;
    
    // Movement.
    byte moveX;
    byte moveY;
    
    // Firing attributes.
    bool isFiring;
    ubyte fireDelay;
    ubyte autoFireDelay;
}


public void playerUpdate(Actor actor, Game game) {
    if (actor.getFlag(ActorFlags.FROZEN) == true) {
        return;
    }

    PlayerData* data = cast(PlayerData*)actor.getDataPtr();
    bool animate;
    PlayerState state;

    data.delay -= 1;
    if (data.delay <= 0) {
        data.delay = 2;
        animate = true;
    }

    AngleType destAngle = movementToAngle(data.moveX, data.moveY);
    AngleType angle = actor.getAngle();

    // See if there is an angle that we have to turn towards.
    if (destAngle != AngleType.NONE && angle != destAngle && animate == true) {
        if ((angle == AngleType.NORTH && destAngle == AngleType.WEST) || (angle == AngleType.WEST && destAngle == AngleType.NORTH)) {
            actor.setAngle(AngleType.NORTHWEST);

        } else if ((angle == AngleType.WEST && destAngle == AngleType.SOUTH) || (angle == AngleType.SOUTH && destAngle == AngleType.WEST)) {
            actor.setAngle(AngleType.SOUTHWEST);

        } else if ((angle == AngleType.SOUTH && destAngle == AngleType.EAST) || (angle == AngleType.EAST && destAngle == AngleType.SOUTH)) {
            actor.setAngle(AngleType.SOUTHEAST);

        } else if ((angle == AngleType.EAST && destAngle == AngleType.NORTH) || (angle == AngleType.NORTH && destAngle == AngleType.EAST)) {
            actor.setAngle(AngleType.NORTHEAST);

        } else {
            actor.setAngle(destAngle);
        }
    }

    // Firing.
    if (data.isFiring == true) {
        state = PlayerState.FIRING;
        if (data.state != state) {
            data.frameIndex = 0;
            data.fireDelay = 1;
        }

        // Animate between 2 frames. autoFireDelay indicates how many frames to wait between shots.
        data.fireDelay -= 1;
        if (data.fireDelay <= 0) {
            if (data.frameIndex == 0) {
                data.frameIndex = 1;
                data.fireDelay = 1;
                actor.attack();
            } else {
                data.frameIndex = 0;
                data.fireDelay = cast(ubyte)(data.autoFireDelay + 1);
            }
        }

        // Each sprite frame has a different location in the texture.
        if (data.frameIndex == 0) {
            actor.setFrameIndex(actor.getAngle() - 1);
        } else if (data.frameIndex == 1) {
            actor.setFrameIndex(actor.getAngle() - 1 + 5 * 8);
        }
    
    // Walking.
    } else if (destAngle != 0) {
        state = PlayerState.WALKING;
        if (state != data.state) {
            animate = true;
            data.frameIndex = 0;
        }

        actor.moveForward(destAngle);
        
        if (animate == true) {
            data.frameIndex = (data.frameIndex + animate) & 3;
            actor.setFrameIndex(8 + (actor.getAngle() - 1) * 4 + data.frameIndex);
        }

    
    // Standing idle.
    } else {
        state = PlayerState.STANDING;
        if (state != data.state) {
            data.idleDelay = 150;
        }

        data.frameIndex = 0;

        data.idleDelay -= 1;
        if (data.idleDelay <= 0) {
            data.idleDelay = 150;
            actor.setAngle(cast(AngleType)uniform(1, 8));   
        }

        actor.setFrameIndex(actor.getAngle() - 1);
    }

    data.state = state;
}

private AngleType movementToAngle(const int moveX, const int moveY) {
    if (moveX == 0 && moveY == -1) {
        return AngleType.NORTH;
    } else if (moveX == 1 && moveY == -1) {
        return AngleType.NORTHEAST;
    } else if (moveX == 1 && moveY == 0) {
        return AngleType.EAST;
    } else if (moveX == 1 && moveY == 1) {
        return AngleType.SOUTHEAST;
    } else if (moveX == 0 && moveY == 1) {
        return AngleType.SOUTH;
    } else if (moveX == -1 && moveY == 1) {
        return AngleType.SOUTHWEST;
    } else if (moveX == -1 && moveY == 0) {
        return AngleType.WEST;
    } else if (moveX == -1 && moveY == -1) {
        return AngleType.NORTHWEST;
    }

    return AngleType.NONE;
}