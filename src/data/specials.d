module data.specials;

import game.actor;

import behaviour.specials;

import data.text;


alias void function(Actor actor) SpecialPowerFunc;

struct SpecialPower {
    Text name;
    SpecialPowerFunc func;
}

static const SpecialPower[] SPECIAL_POWERS = [
    {Text.SPECIALPOWER_0, &specialBomb},
    {Text.SPECIALPOWER_1, &specialShotBurst},
    {Text.SPECIALPOWER_2, &specialMap},
    {Text.SPECIALPOWER_3, &specialDestroyNode},
    {Text.SPECIALPOWER_4, &specialRepelMonsters},
    {Text.SPECIALPOWER_5, &specialFirstAid},
    {Text.SPECIALPOWER_6, &specialFreezeMonsters},
    {Text.SPECIALPOWER_7, &specialShield},
    {Text.SPECIALPOWER_8, &specialPartyPower},
    {Text.SPECIALPOWER_9, &specialAirBurst},
    {Text.SPECIALPOWER_10, &specialDistractMonsters},
    {Text.SPECIALPOWER_11, &specialMolotov},
    {Text.SPECIALPOWER_12, &specialGroundMine},
    {Text.SPECIALPOWER_13, &specialDynamite},
];