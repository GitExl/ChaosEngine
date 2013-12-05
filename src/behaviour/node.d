module behaviour.node;

import game.actor;
import game.game;

import data.collision;


struct NodeData {
    byte delay;
    bool stopped;
}


public void nodeInit(Actor actor) {
    NodeData* data = cast(NodeData*)actor.getDataPtr();

    if (actor.getFrameIndex() == 0) {
        data.stopped = true;
    }
}

public void nodeUpdate(Actor actor, Game game) {
    NodeData* data = cast(NodeData*)actor.getDataPtr();

    if (data.stopped == true) {
        return;
    }

    data.delay -= 1;
    if (data.delay <= 0) {
        data.delay = 2;

        int frameIndex = actor.getFrameIndex();

        // Node destroy.
        if (frameIndex < 3) {
            frameIndex += 1;
        
        // Node animates.
        } else if (frameIndex < 7) {
            frameIndex += 1;
            if (frameIndex >= 7) {
                frameIndex = 4;
                actor.attack();
            }
        }

        // TODO: Activation lightning animation.

        actor.setFrameIndex(frameIndex);
    }
}

public bool nodeDeath(Actor actor) {
    NodeData* data = cast(NodeData*)actor.getDataPtr();

    if (actor.getFrameIndex() == 0) {
        data.stopped = false;
        actor.setCollisionGroup(CollideIndex.EMPTY);
        actor.getLevel().nodeActivate();

    } else {
        data.stopped = true;
        actor.setFrameIndex(3);

    }

    return false;
}