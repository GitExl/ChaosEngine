module game.gamereader;

import std.path;
import std.file;
import std.string;
import std.stdio;

import game.game;
import game.bitmap;
import game.scriptgroup;
import game.specialpower;
import game.tileset;
import game.palette;
import game.level;
import game.rjpsong;

import data.archives;
import data.textures;
import data.text;
import data.tilesets;
import data.characters;
import data.baseactors;
import data.songs;
import data.palettes;

import util.filesystem;


private enum Offsets : uint {
    PALETTES = 140024,
    SPRITES = 98206,
    BASEACTORS = 136934,
    SPECIALPOWERS = 410,
}

private enum Sizes : uint {
    PALETTES = 75,
    SPRITES = 47,
    BASEACTORS = 43,
    LEVELS = 16,
    CHARACTERS = 6,
    SPECIALPOWERS = 14,
    SCRIPTS = 61,
}


final class GameReader {
    private Game mGame;
    private CEFileSystem mFileSystem;

    this(Game game) {
        this.mGame = game;
        buildFileSystem();
    }

    public void buildFileSystem() {
        this.mFileSystem = new CEFileSystem();

        string name;
        foreach (DirEntry entry; dirEntries("." ~ dirSeparator ~ "gamedata", SpanMode.shallow)) {
            if (entry.isFile() == false) {
                continue;
            }

            name = toLower(baseName(entry.name));
            if (name == "sngarc.bin") {
                this.mFileSystem.addArchive(entry.name, ARCHIVE_SNGARC);
            } else if (name == "sngarc2.bin") {
                this.mFileSystem.addArchive(entry.name, ARCHIVE_SNGARC2);
            } else if (name == "levsdat.bin") {
                this.mFileSystem.addArchive(entry.name, ARCHIVE_LEVSDAT);
            } else {
                this.mFileSystem.addFile(new CEFile(entry.name));
            }
        }
    }

    public Bitmap[][string] readGraphics() {
        Bitmap[][string] graphics;
        Bitmap[] bitmaps;

        for (int index; index < TEXTURE_FILES.length; index++) {
            TextureFileInfo textureInfo = TEXTURE_FILES[index];

            CEFile input = this.mFileSystem.getFile(textureInfo.fileName);
            input.seekTo(textureInfo.offset);

            bitmaps = new Bitmap[textureInfo.count];
            foreach (ref Bitmap bitmap; bitmaps) {
                bitmap = new Bitmap(
                    textureInfo.width, textureInfo.height, textureInfo.bitPlanes,
                    cast(PaletteIndex)textureInfo.paletteIndex, textureInfo.subPaletteIndex
                );
                if (textureInfo.mode == BitmapMode.CHUNKY) {
                    bitmap.readChunkyFrom(input);
                } else if (textureInfo.mode == BitmapMode.PLANAR) {
                    bitmap.readPlanarFrom(input);
                } else if (textureInfo.mode == BitmapMode.AMIGA) {
                    bitmap.readACBMFrom(input);
                }

                if (textureInfo.masked == true) {
                    bitmap.setMaskMode(MaskMode.INDEX0);
                }
            }

            graphics[textureInfo.textureName] = bitmaps;
        }

        return graphics;
    }

    public ScriptGroup[] readScriptGroups() {
        CEFile input = this.mFileSystem.getFile("scripts");

        // Read scriptgroup script offsets.
        ScriptGroup[] scriptGroups = new ScriptGroup[Sizes.SCRIPTS];
        foreach (ref ScriptGroup scriptGroup; scriptGroups) {
            scriptGroup = new ScriptGroup();
            scriptGroup.readOffsetsFrom(input);
        }

        // Read a scriptgroup's scripts.
        foreach (ref ScriptGroup scriptGroup; scriptGroups) {
            scriptGroup.readScriptsFrom(input);
        }

        return scriptGroups;
    }

    public void readLevelData(Level[] levels) {
        CEFile actorsInput;

        uint[] actorTemplatesOffsets = new uint[levels.length];
        uint[] spawnSpotsOffsets = new uint[levels.length];
        uint[] destinationsOffsets = new uint[levels.length];
        uint[] actorTemplateScoresOffsets = new uint[levels.length];
        uint endOffset;

        CEFile input = this.mFileSystem.getFile("level_data");
        uint baseOffset = input.getOffset();

        uint[] offsets = new uint[levels.length];
        for (int index; index < levels.length; index++) {
            offsets[index] = input.getUInt() - baseOffset;
        }

        // Read all data offsets first.
        for (int index; index < levels.length; index++) {
            input.seekTo(offsets[index]);

            actorTemplatesOffsets[index] = input.getUInt() - baseOffset;
            spawnSpotsOffsets[index] = input.getUInt() - baseOffset;
            destinationsOffsets[index] = input.getUInt() - baseOffset;
            input.getUShort();
            actorTemplateScoresOffsets[index] = input.getUInt() - baseOffset;
        }

        // Read data for individual levels.
        uint endActorTemplates;
        uint endSpawnSpots;
        foreach (int index, ref Level level; levels) {
            actorsInput = this.mFileSystem.getFile("actors_" ~ cast(char)(65 + index));

            if (index == levels.length - 1) {
                endActorTemplates = input.getSize();
            } else {
                endActorTemplates = actorTemplatesOffsets[index + 1];
            }

            if (index == levels.length - 1) {
                endSpawnSpots = actorTemplatesOffsets[0];
            } else {
                endSpawnSpots = spawnSpotsOffsets[index + 1];
            }

            level.readExtraData(
                input, actorsInput,
                [actorTemplatesOffsets[index], spawnSpotsOffsets[index], destinationsOffsets[index], actorTemplateScoresOffsets[index]],
                endActorTemplates, endSpawnSpots
            );
        }
    }

    private void readTileColors(TileSet[] tileSets) {
        CEFile colorsFile = this.mFileSystem.getFile("tile_colors");
        const int setsLength = tileSets.length;

        // Read tileset color offsets.
        uint[] offsets = new uint[setsLength];
        for (int index; index < setsLength; index++) {
            offsets[index] = colorsFile.getUInt();
        }

        // Read actual color data.
        foreach (int index, ref TileSet tileSet; tileSets) {
            colorsFile.seekTo(offsets[index]);
            tileSet.readColorsFrom(colorsFile);
        }
    }

    public SpecialPower[] readSpecialPowers() {
        CEFile tablesFile = this.mFileSystem.getFile("character_tables");
        tablesFile.seekTo(Offsets.SPECIALPOWERS);

        SpecialPower[] specialPowers = new SpecialPower[Sizes.SPECIALPOWERS];
        foreach (int index, ref SpecialPower specialPower; specialPowers) {
            specialPower = new SpecialPower(TEXT_DATA[Text.SPECIALPOWER_0 + index]);
            specialPower.setPrice(tablesFile.getUInt());
        }

        return specialPowers;
    }

    public Level[] readLevels() {
        CEFile levelFile;

        Level[] levels = new Level[Sizes.LEVELS];
        foreach (int index, ref Level level; levels) {
            levelFile = this.mFileSystem.getFile(cast(char)('a' + index) ~ "1chaos.cas");
            level = new Level(TEXT_DATA[Text.LEVEL_0 + index], index, levelFile, this.mGame);
        }

        return levels;
    }

    public TileSet[] readTileSets() {
        TileSet[] tileSets = new TileSet[TILESET_INFO.length];
        foreach (int index, ref TileSet tileSet; tileSets) {
            tileSet = new TileSet(TILESET_INFO[index].name);

            // Read tileset graphics.
            PaletteIndex paletteIndex = TILESET_INFO[index].paletteIndex;
            foreach (string tileFile; TILESET_INFO[index].tileFiles) {
                tileSet.readTilesFrom(this.mFileSystem.getFile(tileFile), paletteIndex, 0);
            }

            // Read pickup tile graphics.
            tileSet.readTilesFrom(this.mFileSystem.getFile(TILESET_INFO[index].itemsFile), paletteIndex, 9);
        }

        return tileSets;
    }

    public Palette[] readPalettes() {
        CEFile input = this.mFileSystem.getFile("ACHAOS");
        input.seekTo(Offsets.PALETTES);

        uint[Sizes.PALETTES] offsets;

        // Read palette offsets.
        Palette[] palettes = new Palette[Sizes.PALETTES];
        for (int index; index < palettes.length; index++) {
            offsets[index] = input.getUInt();
        }

        // Read each palette from it's offset.
        // Palettes with an offset of 0 are not instantiated at all.
        foreach (int index, ref Palette palette; palettes) {
            if (offsets[index] == 0) {
                continue;
            }

            // Read palette length.
            input.seekTo(offsets[index] + 32);
            palette = new Palette(input.getUShort());
            palette.readFrom(input);
        }

        return palettes;
    }

    public RJPSong[string] readSongs() {
        RJPSong[string] songs;

        CEFile[] sampleFiles;
        foreach (const ref SongInfo info; SONGS_INFO) {
            sampleFiles = new CEFile[info.sampleFiles.length];
            foreach (int index, string fileName; info.sampleFiles) {
                sampleFiles[index] = this.mFileSystem.getFile(fileName);
            }

            RJPSong song = new RJPSong(this.mFileSystem.getFile(info.fileName), sampleFiles);
            songs[info.name] = song;
        }

        return songs;
    }
}