module data.textures;

import data.palettes;


enum BitmapMode : int {
    CHUNKY,
    PLANAR,
    AMIGA,
}

struct TextureFileInfo {
    string fileName;
    string textureName;
    int mode;
    
    int offset;
    int count;
    
    int width;
    int height;
    int bitPlanes;
    
    int paletteIndex;
    int subPaletteIndex;
    
    bool masked;
    bool worldVersions;
}

static const TextureFileInfo[] TEXTURE_FILES = [
    // Screens.
    {"am_back.bin",  "screen_menu",  BitmapMode.AMIGA, 0x0, 1, 320, 200, 5, 11, 0, false, false},
    {"am_dead.bin",  "screen_death", BitmapMode.AMIGA, 0x0, 1, 320, 200, 5, 43, 0, false, false},
    {"am_equip.bin", "screen_equip", BitmapMode.AMIGA, 0x0, 1, 320, 200, 5, 19, 0, false, false},

    // Fonts and text graphics.
    {"am_font.bin",  "font_large_5_a",      BitmapMode.PLANAR, 0x0,    34, 16, 16, 5, 11, 0, false, false},
    {"am_font.bin",  "font_large_5_b",      BitmapMode.PLANAR, 0x1ae0, 34, 16, 16, 5, 11, 0, false, false},
    {"am_font.bin",  "decal_select_player", BitmapMode.PLANAR, 0x35c0, 5,  32, 32, 5, 11, 0, false, false},
    {"am_font.bin",  "decal_game_over",     BitmapMode.PLANAR, 0x4240, 4,  32, 32, 5, 11, 0, false, false},
    {"am_font.bin",  "decal_select_game",   BitmapMode.PLANAR, 0x4c40, 5,  32, 32, 5, 11, 0, false, false},
    {"am_font.bin",  "decal_password",      BitmapMode.PLANAR, 0x58c0, 4,  32, 32, 5, 11, 0, false, false},
    {"am_font.bin",  "decal_unknown",       BitmapMode.PLANAR, 0x62c0, 1,  32, 32, 5, 11, 0, false, false},
    {"am_font.bin",  "text_password_fire",  BitmapMode.PLANAR, 0x6540, 3,  64, 8,  5, 11, 0, false, false},

    // Instruction fonts.
    {"am_itext.bin", "font_small_2",   BitmapMode.PLANAR, 0x0,   37, 8,  8,  2, 4,  0,  false, false},
    {"am_itext.bin", "font_small_5_a", BitmapMode.PLANAR, 0x250, 31, 8,  8,  5, 11, 0,  false, false},
    {"am_itext.bin", "font_small_5_b", BitmapMode.PLANAR, 0x728, 31, 8,  8,  5, 11, 0,  false, false},
    {"am_itext.bin", "font_small_1",   BitmapMode.PLANAR, 0xc00, 35, 8,  8,  1, 4,  0,  false, false},
    {"am_itext.bin", "font_large_2",   BitmapMode.PLANAR, 0xd18, 28, 16, 16, 2, 4,  11, false, false},

    // Outro graphics.
    {"am_outr0.bin", "outro_scream",   BitmapMode.AMIGA,  0x0,    1,  320, 200, 5, 37, 0, false, false},
    {"am_outr1.bin", "outro_death",    BitmapMode.PLANAR, 0x0,    7,  80,  96,  5, 39, 0, false, false},
    {"am_outr2.bin", "outro_mouth",    BitmapMode.PLANAR, 0x0,    10, 48,  48,  5, 39, 0, false, false},
    {"am_outr2.bin", "outro_eyebrows", BitmapMode.PLANAR, 0x3840, 3,  48,  16,  5, 39, 0, false, false},
    {"am_outr2.bin", "outro_eyes",     BitmapMode.PLANAR, 0x3de0, 2,  48,  16,  5, 39, 0, false, false},

    // Title graphics.
    {"am_title.bin", "title_screen", BitmapMode.AMIGA, 0x0, 1, 320, 200, 5, 0, 0, false, false},
    {"cetitle1.sp",  "title_logo",   BitmapMode.AMIGA, 0x0, 4, 64,  60,  4, 0, 0, false, false},

    // HUD graphics.
    {"panel.bin", "hud_pieces1",       BitmapMode.PLANAR, 0x0,    12, 16, 24, 4, 0, 2, false, false},
    {"panel.bin", "hud_pieces2",       BitmapMode.PLANAR, 0x900,  2,  32, 24, 4, 0, 2, true,  false},
    {"panel.bin", "hud_numbers_small", BitmapMode.PLANAR, 0xc00,  10, 16, 7,  4, 0, 2, true,  false},
    {"panel.bin", "hud_specials_bar",  BitmapMode.PLANAR, 0xe30,  2,  16, 2,  4, 0, 2, true,  false},
    {"panel.bin", "hud_numbers_large", BitmapMode.PLANAR, 0xe68,  10, 16, 9,  4, 0, 2, true,  false},
    {"panel.bin", "hud_specials",      BitmapMode.PLANAR, 0x1138, 14, 16, 16, 4, 0, 2, true,  false},
    
    // HUD portraits.
    {"brigand.bin",  "hud_player0", BitmapMode.CHUNKY, 0x6000, 1, 32, 24, 4, 0, 2, false, false},
    {"mercenry.bin", "hud_player1", BitmapMode.CHUNKY, 0x6000, 1, 32, 24, 4, 0, 2, false, false},
    {"gentlman.bin", "hud_player2", BitmapMode.CHUNKY, 0x6000, 1, 32, 24, 4, 0, 2, false, false},
    {"navvie.bin",   "hud_player3", BitmapMode.CHUNKY, 0x6000, 1, 32, 24, 4, 0, 2, false, false},
    {"thug.bin",     "hud_player4", BitmapMode.CHUNKY, 0x6000, 1, 32, 24, 4, 0, 2, false, false},
    {"preacher.bin", "hud_player5", BitmapMode.CHUNKY, 0x6000, 1, 32, 24, 4, 0, 2, false, false},

    // Equip screen graphics.
    {"equip_screen", "equip_specialpowers1",  BitmapMode.PLANAR, 0x0,    14, 16, 16, 5, 19, 0,  false, false},
    {"equip_screen", "equip_character_bulb",  BitmapMode.PLANAR, 0x8c0,  4,  16, 16, 5, 19, 0,  false, false},
    {"equip_screen", "equip_numbers",         BitmapMode.PLANAR, 0xbe0,  10, 16, 8,  4, 19, 7,  false, false},
    {"equip_screen", "equip_bulb_all",        BitmapMode.PLANAR, 0xe60,  3,  16, 8,  5, 19, 0,  false, false},
    {"equip_screen", "equip_arrows",          BitmapMode.PLANAR, 0xf50,  5,  16, 19, 5, 19, 0,  false, false},
    {"equip_screen", "equip_weapons",         BitmapMode.PLANAR, 0x17c4, 6,  80, 24, 4, 19, 10, false, false},
    {"equip_screen", "equip_strength_bars",   BitmapMode.PLANAR, 0x2e44, 2,  48, 8,  4, 19, 10, false, false},
    {"equip_screen", "equip_font",            BitmapMode.PLANAR, 0x3084, 30, 16, 8,  5, 19, 0,  false, false},
    {"equip_screen", "equip_buttons",         BitmapMode.PLANAR, 0x3d54, 6,  32, 32, 5, 19, 0,  false, false},
    {"equip_screen", "equip_specialpowers2",  BitmapMode.PLANAR, 0x4c54, 14, 16, 18, 5, 19, 0,  false, false},
    {"equip_screen", "equip_specialpowers3",  BitmapMode.PLANAR, 0x562c, 14, 16, 18, 5, 19, 0,  false, false},
    {"equip_screen", "equip_digits",          BitmapMode.PLANAR, 0x6784, 40, 16, 8,  4, 19, 11, false, false},
    {"equip_screen", "equip_frame",           BitmapMode.PLANAR, 0x9f04, 1,  32, 32, 5, 19, 0,  false, false},
    {"equip_screen", "equip_lights",          BitmapMode.PLANAR, 0xa184, 18, 16, 16, 5, 19, 0,  false, false},
    {"equip_screen", "equip_bars_unknown",    BitmapMode.PLANAR, 0xacc4, 1,  48, 8,  5, 19, 0,  false, false},
    {"equip_screen", "equip_names",           BitmapMode.PLANAR, 0xadb4, 6,  64, 9,  5, 19, 0,  false, false},
    {"equip_screen", "equip_names_the",       BitmapMode.PLANAR, 0xb624, 12, 48, 8,  5, 19, 0,  false, false},
    
    // Large portraits.
    {"equip_screen", "portrait_large_brigand",   BitmapMode.PLANAR, 0x7184, 1, 48, 48, 4, 19, 2, false, false},
    {"equip_screen", "portrait_large_mercenary", BitmapMode.PLANAR, 0x7604, 1, 48, 48, 4, 19, 3, false, false},
    {"equip_screen", "portrait_large_gentleman", BitmapMode.PLANAR, 0x7a84, 1, 48, 48, 4, 19, 4, false, false},
    {"equip_screen", "portrait_large_navvie",    BitmapMode.PLANAR, 0x7f04, 1, 48, 48, 4, 19, 5, false, false},
    {"equip_screen", "portrait_large_thug",      BitmapMode.PLANAR, 0x8384, 1, 48, 48, 4, 19, 6, false, false},
    {"equip_screen", "portrait_large_preacher",  BitmapMode.PLANAR, 0x8804, 1, 48, 48, 4, 19, 7, false, false},
    {"equip_screen", "portrait_large_empty",     BitmapMode.PLANAR, 0x8c84, 1, 48, 48, 4, 19, 2, false, false},

    // Small portraits.
    {"equip_screen", "portrait_small_brigand",   BitmapMode.PLANAR, 0x9104, 1, 32, 32, 4, 19, 2, false, false},
    {"equip_screen", "portrait_small_mercenary", BitmapMode.PLANAR, 0x9304, 1, 32, 32, 4, 19, 3, false, false},
    {"equip_screen", "portrait_small_gentleman", BitmapMode.PLANAR, 0x9504, 1, 32, 32, 4, 19, 4, false, false},
    {"equip_screen", "portrait_small_navvie",    BitmapMode.PLANAR, 0x9704, 1, 32, 32, 4, 19, 5, false, false},
    {"equip_screen", "portrait_small_thug",      BitmapMode.PLANAR, 0x9904, 1, 32, 32, 4, 19, 6, false, false},
    {"equip_screen", "portrait_small_preacher",  BitmapMode.PLANAR, 0x9b04, 1, 32, 32, 4, 19, 7, false, false},
    {"equip_screen", "portrait_small_empty",     BitmapMode.PLANAR, 0x9d04, 1, 32, 32, 4, 19, 2, false, false},

    // Solid bars.
    {"equip_screen", "bar_fat_solid",  BitmapMode.PLANAR, 0x6604, 1, 64, 12, 4, 19, 13, false, false},
    {"equip_screen", "bar_thin_solid", BitmapMode.PLANAR, 0x2fc4, 1, 48, 8,  4, 19, 13, false, false},

    // Colored bars.
    {"equip_screen", "bars_fat",  BitmapMode.PLANAR, 0x6004, 4, 64, 12, 4, 19, 12, false, false},
    {"equip_screen", "bars_thin", BitmapMode.PLANAR, 0x13c4, 4, 64, 8,  4, 19, 12, false, false},

    // Translucency mask.
    {"tranmask.bin", "translucency_mask", BitmapMode.PLANAR, 0x0, 8, 16, 16, 4, PaletteIndex.FLASH_WHITE, 0, true, false},

    // Sprites.
    {"brigand.bin",  "sprite_brigand",        BitmapMode.CHUNKY, 0x0, 48,  32, 32, 4, PaletteIndex.WORLD1, 1,  true, true},
    {"mercenry.bin", "sprite_mercenary",      BitmapMode.CHUNKY, 0x0, 48,  32, 32, 4, PaletteIndex.WORLD1, 5,  true, true},
    {"gentlman.bin", "sprite_gentleman",      BitmapMode.CHUNKY, 0x0, 48,  32, 32, 4, PaletteIndex.WORLD1, 4,  true, true},
    {"navvie.bin",   "sprite_navvie",         BitmapMode.CHUNKY, 0x0, 48,  32, 32, 4, PaletteIndex.WORLD1, 6,  true, true},
    {"thug.bin",     "sprite_thug",           BitmapMode.CHUNKY, 0x0, 48,  32, 32, 4, PaletteIndex.WORLD1, 8,  true, true},
    {"preacher.bin", "sprite_preacher",       BitmapMode.CHUNKY, 0x0, 48,  32, 32, 4, PaletteIndex.WORLD1, 7,  true, true},
    {"expl1616.bin", "sprite_expl16",         BitmapMode.PLANAR, 0x0, 103, 16, 16, 4, PaletteIndex.WORLD1, 10, true, true},
    {"nodes.bin",    "sprite_node",           BitmapMode.PLANAR, 0x0, 12,  16, 48, 4, PaletteIndex.WORLD1, 10, true, true},
    {"sp8x8.bin",    "sprite_sp8",            BitmapMode.PLANAR, 0x0, 164, 8,  8,  4, PaletteIndex.WORLD1, 10, true, true},
    {"expl3232.bin", "sprite_expl32",         BitmapMode.CHUNKY, 0x0, 18,  32, 32, 4, PaletteIndex.WORLD1, 10, true, true},
    {"rockman.bin",  "sprite_rockman",        BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD1, 13, true, false},
    {"beetle.bin",   "sprite_beetle",         BitmapMode.PLANAR, 0x0, 25,  16, 16, 4, PaletteIndex.WORLD1, 11, true, false},
    {"compost.bin",  "sprite_compost",        BitmapMode.CHUNKY, 0x0, 4,   32, 32, 4, PaletteIndex.WORLD1, 12, true, false},
    {"frogger.bin",  "sprite_frogger",        BitmapMode.CHUNKY, 0x0, 40,  32, 32, 4, PaletteIndex.WORLD1, 14, true, false},
    {"lizman.bin",   "sprite_lizardman",      BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD1, 15, true, false},
    {"thumper.bin",  "sprite_thumper",        BitmapMode.PLANAR, 0x0, 11,  16, 16, 4, PaletteIndex.WORLD1, 15, true, true},
    {"blob.bin",     "sprite_blob",           BitmapMode.PLANAR, 0x0, 9,   16, 32, 4, PaletteIndex.WORLD2, 14, true, false},
    {"guard.bin",    "sprite_guard",          BitmapMode.CHUNKY, 0x0, 28,  32, 32, 4, PaletteIndex.WORLD2, 13, true, false},
    {"beast.bin",    "sprite_beast",          BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD2, 11, true, false},
    {"dhturret.bin", "sprite_dhturret",       BitmapMode.CHUNKY, 0x0, 2,   32, 32, 4, PaletteIndex.WORLD2, 12, true, false},
    {"dustdevl.bin", "sprite_dustdevil",      BitmapMode.CHUNKY, 0x0, 20,  32, 32, 4, PaletteIndex.WORLD2, 12, true, false},
    {"sewer.bin",    "sprite_sewer",          BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD2, 14, true, false},
    {"steamjet.bin", "sprite_steamjet",       BitmapMode.PLANAR, 0x0, 28,  16, 16, 4, PaletteIndex.WORLD2, 12, true, false},
    {"kangaroo.bin", "sprite_kangaroo",       BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD2, 13, true, false},
    {"fire_man.bin", "sprite_fireman",        BitmapMode.PLANAR, 0x0, 32,  16, 16, 4, PaletteIndex.WORLD2, 15, true, false},
    {"hand.bin",     "sprite_hand",           BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD3, 12, true, false},
    {"stonewat.bin", "sprite_stonewatcher",   BitmapMode.CHUNKY, 0x0, 9,   32, 32, 4, PaletteIndex.WORLD3, 15, true, false},
    {"cocoon.bin",   "sprite_cocoon",         BitmapMode.CHUNKY, 0x0, 5,   32, 32, 4, PaletteIndex.WORLD3, 11, true, false},
    {"spider.bin",   "sprite_spider",         BitmapMode.PLANAR, 0x0, 25,  16, 16, 4, PaletteIndex.WORLD3, 14, true, false},
    {"lobber.bin",   "sprite_lobber",         BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD3, 11, true, false},
    {"misslink.bin", "sprite_missinglink",    BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD3, 13, true, false},
    {"slug.bin",     "sprite_slug",           BitmapMode.PLANAR, 0x0, 32,  16, 16, 4, PaletteIndex.WORLD3, 14, true, false},
    {"mace.bin",     "sprite_mace",           BitmapMode.CHUNKY, 0x0, 16,  32, 32, 4, PaletteIndex.WORLD3, 15, true, false},
    {"emplacmt.bin", "sprite_emplacement",    BitmapMode.CHUNKY, 0x0, 16,  32, 48, 4, PaletteIndex.WORLD4, 11, true, false},
    {"emplgun.bin",  "sprite_emplacementgun", BitmapMode.PLANAR, 0x0, 24,  16, 16, 4, PaletteIndex.WORLD4, 11, true, false},
    {"robot.bin",    "sprite_robot",          BitmapMode.CHUNKY, 0x0, 40,  32, 32, 4, PaletteIndex.WORLD4, 14, true, false},
    {"revdome.bin",  "sprite_revvingdome",    BitmapMode.PLANAR, 0x0, 15,  16, 16, 4, PaletteIndex.WORLD4, 12, true, false},
    {"gyro_big.bin", "sprite_gyro",           BitmapMode.CHUNKY, 0x0, 16,  32, 32, 4, PaletteIndex.WORLD4, 12, true, false},
    {"rat.bin",      "sprite_rat",            BitmapMode.PLANAR, 0x0, 32,  16, 16, 4, PaletteIndex.WORLD4, 12, true, false},
    {"halftrak.bin", "sprite_halftrack",      BitmapMode.CHUNKY, 0x0, 32,  32, 32, 4, PaletteIndex.WORLD4, 13, true, false},
    {"mechanic.bin", "sprite_mechanic",       BitmapMode.PLANAR, 0x0, 32,  16, 16, 4, PaletteIndex.WORLD4, 12, true, false},
    {"engyball.bin", "sprite_energyball",     BitmapMode.CHUNKY, 0x0, 17,  32, 32, 4, PaletteIndex.WORLD4, 12, true, false},
    {"thebaron.bin", "sprite_thebaron",       BitmapMode.CHUNKY, 0x0, 10,  32, 32, 4, PaletteIndex.WORLD4, 15, true, false},
    {"barongun.bin", "sprite_thebarongun",    BitmapMode.PLANAR, 0x0, 20,  16, 16, 4, PaletteIndex.WORLD4, 15, true, false},
];