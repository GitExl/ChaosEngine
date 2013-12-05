module game.levelreader;

import std.stdio;

import game.level;
import game.tilemap;
import game.scriptblock;
import game.trigger;
import game.cover;
import game.pickup;
import game.actor;

import data.attacks;

import util.filesystem;


public final class LevelReader {
    private CEFile mFile;
    private Level mLevel;

    private uint mOffsetMap;
    private uint mOffsetTemplates;
    private uint mOffsetScriptBlocks;
    private uint mOffsetTriggers;
    private uint mOffsetCovers;
    private uint mOffsetPickups;
    private uint mOffsetMusicMap;
    
    private uint mFileSize;


    this(CEFile file, Level level) {
        this.mFile = file;
        this.mLevel = level;

        // Read offsets from level file.
        this.mFile.reset();

        this.mOffsetMap = file.getUInt();
        this.mOffsetTemplates = file.getUInt();
        this.mOffsetScriptBlocks = file.getUInt();
        this.mOffsetTriggers = file.getUInt();
        this.mOffsetCovers = file.getUInt();
        this.mOffsetPickups = file.getUInt();
        this.mOffsetMusicMap = file.getUInt();

        this.mFileSize = file.getUInt();
    }

    public TileMap readMap() {
        // Read map data.
        this.mFile.seekTo(this.mOffsetMap);

        // Parse header.
        const ushort width = this.mFile.getUShort();
        const ushort height = this.mFile.getUShort();
        this.mLevel.setTileSetIndex(this.mFile.getUByte() - 1);

        // Palette index, unused here.
        this.mFile.getUByte();

        TileMap tiles = new TileMap(width, height);
        tiles.readFrom(this.mFile);

        return tiles;
    }

    public TileMap[] readTileTemplates() {
        this.mFile.seekTo(this.mOffsetTemplates);

        const ushort templateCount = this.mFile.getUShort();
        TileMap[] tileTemplates = new TileMap[templateCount];

        foreach (ref TileMap tileTemplate; tileTemplates) {
            tileTemplate = new TileMap(3, 3);
            tileTemplate.readFrom(this.mFile);
        }

        return tileTemplates;
    }

    public ScriptBlock[] readScriptBlocks() {
        return readDataType!ScriptBlock(this.mOffsetScriptBlocks);
    }

    public Trigger[] readTriggers() {
        this.mFile.seekTo(this.mOffsetTriggers);

        const ushort itemCount = this.mFile.getUShort();
        this.mFile.getUShort();

        Trigger[] triggers = new Trigger[itemCount];
        foreach (ref Trigger trigger; triggers) {
            trigger = new Trigger();
            trigger.readFrom(this.mFile);
        }

        return triggers;
    }

    public Cover[] readCovers() {
        return readDataType!Cover(this.mOffsetCovers);
    }

    public Pickup[] readPickups() {
        this.mFile.seekTo(this.mOffsetPickups);

        const ushort pickupCount = this.mFile.getUShort();
        this.mFile.getUShort();

        Pickup[] pickups = new Pickup[pickupCount];
        foreach (ref Pickup pickup; pickups) {
            pickup = new Pickup();
            pickup.readFrom(this.mFile);
        }

        return pickups;
    }

    public ubyte[] readMusicMap() {
        this.mFile.seekTo(this.mOffsetMusicMap);
        
        const int musicBlockCount = this.mFileSize - this.mOffsetMusicMap;
        return this.mFile.getBytes(musicBlockCount);
    }

    public ActorTemplate[] readActorTemplatesFrom(CEFile input, uint offset) {
        input.seekTo(offset);

        ActorTemplate[] actorTemplates = new ActorTemplate[0];
        ActorTemplate* actor;

        for (;;) {
            actorTemplates.length += 1;
            actor = &actorTemplates[actorTemplates.length - 1];

            actor.baseActorIndex = input.getShort();

            actor.health = input.getUShort();
            //actor.isShootable = (actor.health >> 15) & 0x1;
            actor.health = (actor.health & 0x7FFF);

            actor.speed = input.getUShort();

            actor.attack.type = cast(AttackIndex)input.getUShort();
            actor.attack.delay = input.getUShort();
            actor.attack.damage = input.getUShort();
            actor.attack.speed = input.getByte();
            actor.attack.distance = input.getByte();

            actor.attackRange = input.getUShort();
            actor.angle = cast(AngleType)input.getUShort();

            // Unknown.
            input.getUShort();

            if (actor.baseActorIndex == -1) {
                actorTemplates.length -= 1;
                break;
            }
        }

        return actorTemplates;
    }

    public SpawnSpot[] readSpawnSpotsFrom(CEFile input, const uint offset, const uint endOffset) {
        input.seekTo(offset);

        SpawnSpot[] spawnSpots = new SpawnSpot[0];
        SpawnSpot spawnSpot;

        while(input.getPosition() < endOffset) {   
            spawnSpot.x = input.getUShort() - 32;
            spawnSpot.y = input.getUShort() - 24;

            spawnSpots.length += 1;
            spawnSpots[spawnSpots.length - 1] = spawnSpot;
        }

        return spawnSpots;
    }

    public Destination[] readDestinationsFrom(CEFile input, const uint offset, const uint endOffset) {
        input.seekTo(offset);

        Destination[] destinations = new Destination[0];
        Destination destination;

        while(input.getPosition() < endOffset) {
            destination.levelIndex = cast(short)(input.getShort() - 65);
            destination.spawnSpotIndex = input.getShort();
            destination.flags = cast(DestinationFlags)input.getUShort();

            if (destination.levelIndex < 0 || destination.flags > 1) {
                break;
            }

            destinations.length = destinations.length + 1;
            destinations[destinations.length - 1] = destination;
        }

        return destinations;
    }

    public void readActorTemplateScoresFrom(CEFile input, const uint offset, ActorTemplate[] actorTemplates) {
        input.seekTo(offset);

        foreach (ref ActorTemplate actor; actorTemplates) {
            actor.score = input.getShort();
        }
    }

    public Actor[] readActorsFrom(CEFile input, ActorTemplate[] actorTemplates) {
        Actor[] actors = new Actor[input.getUShort() / 20];

        foreach (ref Actor actor; actors) {
            actor = new Actor();
            actor.reset();
            actor.readFrom(input, actorTemplates);
        }

        return actors;
    }

    private T[] readDataType(T)(const uint offset) {
        this.mFile.seekTo(offset);

        const ushort itemCount = this.mFile.getUShort();
        this.mFile.getUShort();
        T[] items = new T[itemCount];

        foreach (ref T item; items) {
            item = new T();
            item.readFrom(this.mFile, this.mLevel);
        }

        return items;
    }
}