module behaviour.pickups;

import game.game;
import game.player;

import behaviour.specials;

import data.specials;


public void pickupAirBurst(Game game, Player* player) {
    specialAirBurst(player.actor);
}

public void pickupDistractMonsters(Game game, Player* player) {
    specialDistractMonsters(player.actor);
}

public void pickupBomb(Game game, Player* player) {
    specialBomb(player.actor);
}

public void pickupDestroyNode(Game game, Player* player) {
    specialDestroyNode(player.actor);
}

public void pickupDynamite(Game game, Player* player) {
    specialDynamite(player.actor);
}

public void pickupFirstAid(Game game, Player* player) {
    specialFirstAid(player.actor);
}

public void pickupFreezeMonsters(Game game, Player* player) {
    specialFreezeMonsters(player.actor);
}

public void pickupGroundMine(Game game, Player* player) {
    specialGroundMine(player.actor);
}

public void pickupMap(Game game, Player* player) {
    specialMap(player.actor);
}

public void pickupMolotov(Game game, Player* player) {
    specialMolotov(player.actor);
}

public void pickupPartyPower(Game game, Player* player) {
    specialPartyPower(player.actor);
}

public void pickupRepelMonsters(Game game, Player* player) {
    specialRepelMonsters(player.actor);
}

public void pickupShield(Game game, Player* player) {
    specialShield(player.actor);
}

public void pickupShotBurst(Game game, Player* player) {
    specialShotBurst(player.actor);
}

public void pickupCoins1(Game game, Player* player) {
    player.money += 5;
}

public void pickupCoins2(Game game, Player* player) {
    player.money += 10;
}

public void pickupCoins3(Game game, Player* player) {
    player.money += 15;
}

public void pickupCoins4(Game game, Player* player) {
    player.money += 20;
}

public void pickupCoins5(Game game, Player* player) {
    player.money += 30;
}

public void pickupEmerald1(Game game, Player* player) {
    player.money += 100;
}

public void pickupEmerald2(Game game, Player* player) {
    player.money += 200;
}

public void pickupFood1(Game game, Player* player) {
    // TODO: dont heal beyond level max.
    player.actor.heal(5);
}

public void pickupFood2(Game game, Player* player) {
    // TODO: dont heal beyond level max.
    player.actor.heal(15);
}

public void pickupExtraLife(Game game, Player* player) {
    player.lives += 1;
    if (player.lives > 99) {
        player.lives = 99;
    }
}

public void pickupPlayerSave(Game game, Player* player) {}

public void pickupPowerup(Game game, Player* player) {
    player.weaponLevel += 1;
}

public void pickupSpecialPower(Game game, Player* player) {
    player.specialPowerCount += 1;
    if (player.specialPowerCount > 6) {
        player.specialPowerCount = 6;
    }
}

public void pickupTelephone(Game game, Player* player) {}