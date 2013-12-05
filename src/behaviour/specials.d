module behaviour.specials;

import std.stdio;

import game.game;
import game.level;
import game.actor;

import data.baseactors;

import util.rectangle;


public void specialBomb(Actor actor) {}
public void specialShotBurst(Actor actor) {}
public void specialMap(Actor actor) {}

public void specialDestroyNode(Actor actor) {
    Level level = actor.getLevel();
    Game game = level.getGame();
    Rectangle playArea = game.getPlayArea();

    // TODO: Should actually spawn a missile that stays near the player (glitchily in the real game), and head towards the nearest node when it finds one.
    // When it hits the node it dissappears and activates the node. The screen flashes 8 times to white (white-normal-white-normal-etc.). At 50hz though...
    // And does the player who fires the special get the 100 points score for the node?
    level.getActors().iterate(delegate bool(index, levelActor) {
        if (levelActor.intersects(playArea) == true) {
            if (levelActor.getBaseActor() == &BASEACTOR_INFO[BaseActorIndex.NODE_DORMANT]) {
                levelActor.damage(255, actor, AngleType.NONE);
                return true;
            }
        }
        return false;
    });
}

public void specialRepelMonsters(Actor actor) {}
public void specialFirstAid(Actor actor) {}
public void specialFreezeMonsters(Actor actor) {}
public void specialShield(Actor actor) {}
public void specialPartyPower(Actor actor) {}
public void specialAirBurst(Actor actor) {}
public void specialDistractMonsters(Actor actor) {}
public void specialMolotov(Actor actor) {}
public void specialGroundMine(Actor actor) {}
public void specialDynamite(Actor actor) {}
