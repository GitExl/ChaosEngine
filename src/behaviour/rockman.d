module behaviour.rockman;

import game.actor;
import game.game;
import game.util;
import game.player;

import behaviour.util;


struct RockmanData {
    ubyte walkIndex;
    byte delay;    
    byte nearestPlayer;
    ubyte nearestDistance;
}


public void rockmanUpdate(Actor actor, Game game) {
    RockmanData* data = cast(RockmanData*)actor.getDataPtr();

    data.delay -= 1;
    if (data.delay <= 0) {
        data.delay = 2;

        if (actor.getFlag(ActorFlags.JUSTSPAWNED) == true) {
            actor.moveDown();
            data.walkIndex = (data.walkIndex + 1) % 4;

        } else {
            Player[] players = game.getPlayers();

            data.nearestPlayer = cast(byte)getNearestPlayer(actor, players, 192);
            if (data.nearestPlayer > -1) {
                faceActor(actor, players[data.nearestPlayer].actor);

                int distance = getDistanceBetween(players[data.nearestPlayer].actor, actor);
                if (distance > 64) {
                    data.walkIndex = (data.walkIndex + 1) % 4;
                    actor.moveForward(actor.getAngle());
                }
            }
        }

        actor.setFrameIndex(4 * (actor.getAngle() - 1) + data.walkIndex);
    }
}