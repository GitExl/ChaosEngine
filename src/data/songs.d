module data.songs;


struct SongInfo {
    string name;
    
    string fileName;
    string[] sampleFiles;
}

static const SongInfo[] SONGS_INFO = [
    {"world0", "music_world0", ["lev9.ins", "lev1.ins"]},
    {"world1", "music_world1", ["lev9.ins", "lev2.ins"]},
    {"world2", "music_world2", ["lev9.ins", "lev3.ins"]},
    {"world3", "music_world3", ["lev9.ins", "lev4.ins"]},
    {"shop",   "music_shop",   ["shop.ins"]},
    {"outro",  "shop1.sng",    ["shop.ins", "shop1.ins"]},
];

static const ubyte SUBSONG_MAPPINGS[][] = [
    [18, 14, 5, 13, 7, 4, 16, 10, 10, 16, 15, 6, 6, 9, 9, 8],
    [4, 5, 10, 11, 14, 14, 14, 14, 4, 5, 10, 11, 14, 14, 14, 14],
    [7, 4, 11, 16, 27, 16, 16, 16, 7, 4, 11, 16, 27, 16, 16, 16],
    [4, 5, 7, 8, 11, 12, 16, 17, 30, 5, 7, 8, 11, 12, 16, 17],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 5, 7, 3],
];