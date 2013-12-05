module behaviour.anim;

import data.anims;

import game.actor;
import game.game;


struct AnimData {
    Anim* anim;
    byte counter;
    ubyte currentFrame;
}


public void animUpdate(Actor actor, Game game) {
    actor.moveForward();

    AnimData* data = cast(AnimData*)actor.getDataPtr();
    if (data.anim.frameCount <= 1) {
        return;
    }

    data.counter -= 1;
    if (data.counter <= 0) {
        data.counter = data.anim.speed;

        if (data.anim.hasRotations == true) {
            data.currentFrame += 8;
        } else {
            data.currentFrame += 1;
        }

        if (data.currentFrame >= data.anim.frameIndex + data.anim.frameCount) {
            if (data.anim.loops == true) {
                data.currentFrame = data.anim.frameIndex;
            } else {
                actor.remove(true);
            }
        }

        actor.setFrameIndex(data.currentFrame);
    }
}