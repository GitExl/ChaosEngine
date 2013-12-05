module game.level;

import std.stdio;
import std.math;

import game.tilemap;
import game.scriptblock;
import game.cover;
import game.pickup;
import game.actor;
import game.tileset;
import game.scriptgroup;
import game.game;
import game.trigger;
import game.levelreader;
import game.player;

import data.anims;
import data.attacks;
import data.baseactors;
import data.tilesets;
import data.songs;

import behaviour.anim;

import util.filesystem;
import util.rectangle;
import util.objectlist;


public enum DestinationFlags : int {
    FADE = 1
}

public struct SpawnSpot {
    int x;
    int y;
}

public struct Destination {
    int levelIndex;
    int spawnSpotIndex;
    DestinationFlags flags;
}

public class Fader {
    public {
        int alpha;
        TileMap tiles;
        ScriptBlock scriptBlock;
        int x;
        int y;
    }
}

public struct ActorTemplate {
    int baseActorIndex;

    int health;
    int speed;
    AngleType angle;
    int score;
    
    int attackRange;
    Attack attack;
}


final class Level {
    private LevelReader mReader;

    private TileMap mTiles;
    private TileMap[] mTileTemplates;
    private Cover[] mCovers;
    private ubyte[] mMusicMap;
    private ActorTemplate[] mActorTemplates;
    private SpawnSpot[] mSpawnSpots;
    private Destination[] mDestinations;

    private ObjectList!ScriptBlock mScriptBlocks;
    private ObjectList!Trigger mTriggers;
    private ObjectList!Actor mActors;
    private ObjectList!Fader mFaders;
    private ObjectList!Pickup mPickups;

    private string mName;

    private int mTileSetIndex;

    private int mLevelIndex;

    private int mNodesDormant;
    private int mNodesActive;
    private int mNodesMinimal;

    private TileSet mTileSet;

    private Game mGame;


    this(string name, const int levelIndex, CEFile input, Game game) {
        this.mGame = game;

        this.mName = name;
        this.mLevelIndex = levelIndex;

        this.mFaders = new ObjectList!Fader(8, 1.5f);
        
        this.mReader = new LevelReader(input, this);
        
        this.mTiles = this.mReader.readMap();
        this.mTileTemplates = this.mReader.readTileTemplates();
        this.mCovers = this.mReader.readCovers();
        this.mMusicMap = this.mReader.readMusicMap();

        this.mScriptBlocks = new ObjectList!ScriptBlock(this.mReader.readScriptBlocks(), 1.1f);
        this.mTriggers = new ObjectList!Trigger(this.mReader.readTriggers(), 1.1f);
        this.mPickups = new ObjectList!Pickup(this.mReader.readPickups(), 1.1f);
    }

    public void readExtraData(CEFile input, CEFile actorsInput, uint[4] offsets, uint endSpawnSpots, uint endDestinations) {
        this.mActorTemplates = this.mReader.readActorTemplatesFrom(input, offsets[0]);
        this.mSpawnSpots = this.mReader.readSpawnSpotsFrom(input, offsets[1], endSpawnSpots);
        this.mDestinations = this.mReader.readDestinationsFrom(input, offsets[2], endDestinations);

        this.mReader.readActorTemplateScoresFrom(input, offsets[3], this.mActorTemplates);

        this.mActors = new ObjectList!Actor(this.mReader.readActorsFrom(actorsInput, this.mActorTemplates), 1.5f);
    }

    public Actor addActor(BaseActor* baseActor, const int x, const int y) {
        return addActor(baseActor, x, y, this.mTiles.getPixelZ(x, y));
    }

    public Actor addActor(BaseActor* baseActor, const int x, const int y, const int z) {
        Actor actor = this.mActors.getObject();

        actor.reset();
        actor.setLevel(this);
        actor.setBaseActor(baseActor);
        actor.setPosition(x, y);

        return actor;
    }

    public Actor addAnim(const int infoIndex, const int x, const int y, const int z, const AngleType angle) {
        BaseActor* baseActor;
        Anim* anim = &ANIM_INFO[infoIndex];

        if (anim.size == 8) {
            baseActor = &BASEACTOR_INFO[BaseActorIndex.ANIM8];
        } else if (anim.size == 16) {
            baseActor = &BASEACTOR_INFO[BaseActorIndex.ANIM16];
        } else if (anim.size == 32) {
            baseActor = &BASEACTOR_INFO[BaseActorIndex.ANIM32];
        }

        Actor actor = addActor(baseActor, x, y, z);
        actor.setAngle(angle);

        if (anim.hasRotations == true) {
            actor.setFrameIndex(anim.frameIndex + angle - 1);
        } else {
            actor.setFrameIndex(anim.frameIndex);
        }

        AnimData* data = cast(AnimData*)actor.getDataPtr();
        data.anim = anim;
        data.counter = anim.speed;
        data.currentFrame = anim.frameIndex;

        return actor;
    }

    public void addFader(TileMap tiles, ScriptBlock scriptBlock, const int x, const int y) {
        Fader fader = this.mFaders.getObject();
        fader.alpha = 0;
        fader.scriptBlock = scriptBlock;
        fader.x = x;
        fader.y = y;

        fader.tiles = new TileMap(3, 3);
        this.mTiles.copyTo(fader.tiles, fader.x, fader.y, 0, 0, 3, 3);

        tiles.copyTo(this.mTiles, 0, 0, fader.x, fader.y, 3, 3);
    }

    public void addFader(const int templateIndex, ScriptBlock scriptBlock, const int x, const int y) {
        addFader(this.mTileTemplates[templateIndex], scriptBlock, x, y);
    }

    public void update(Game game, ref Rectangle playArea) {
        updateScriptBlocks(playArea);
        updateActors(game, playArea);
        updateFaders();
    }

    private void updateScriptBlocks(ref Rectangle playArea) {
        this.mScriptBlocks.iterateFilter(delegate bool(index, scriptBlock) {
            if (scriptBlock.intersects(playArea) == true) {
                return scriptBlock.update();
            }

            return false;
        });
    }

    public ubyte getSubSongAt(const int x, const int y) {
        const int index = x / 64 + ((y / 64) * (this.mTiles.getPixelWidth() / 64));
        if (index < 0 || index >= this.mMusicMap.length) {
            return 0;
        }

        ubyte subSongIndex = 0;
        const ubyte value = this.mMusicMap[index];
        if (value > 0) {
            subSongIndex = SUBSONG_MAPPINGS[this.mLevelIndex / 4][value - 1];
        }

        return subSongIndex;
    }

    private void updateActors(Game game, ref Rectangle playArea) {
        Rectangle rect;

        this.mActors.iterateFilterReverse(delegate bool(index, actorA) {
            if (actorA.intersects(playArea) == false) {
                if (actorA.getFlag(ActorFlags.DISAPPEARS) == true) {
                    return true;
                }
                return false;
            }

            actorA.update(game);

            if (actorA.getFlag(ActorFlags.NOCOLLIDE) == false) {
                this.mActors.iterate(delegate bool(index, actorB) {
                    if (actorB == this) {
                        return false;
                    }

                    if (actorA.canCollide(actorB) == true) {
                        actorB.getRect(rect);
                        if (actorA.intersects(rect) == true) {
                            actorA.collideWith(actorB);
                        }
                    }

                    return false;
                });
            }

            return actorA.remove();
        });
    }

    private void updateFaders() {
        this.mFaders.iterateFilter(delegate bool(index, fader) {
            fader.alpha += 16;
            if (fader.alpha >= 255) {
                if (fader.scriptBlock !is null) {
                    fader.scriptBlock.resume();
                }
                return true;
            }

            return false;
        });
    }

    public void warpActorTo(Actor actor, int destinationIndex) {
        Destination* dest = &this.mDestinations[destinationIndex];

        // Warp to current level.
        if (dest.levelIndex == this.mLevelIndex) {
            const SpawnSpot* spot = &this.mSpawnSpots[dest.spawnSpotIndex];
            actor.setPosition(spot.x, spot.y);

            // Activate spawnspot triggers.
            activateTriggerSpawnSpot(dest.spawnSpotIndex);
                
        // Warp to another level.
        } else {
            this.mGame.levelEnter(actor, dest.levelIndex, dest.spawnSpotIndex);

        }
    }

    public void warpActor(Actor actor, const int tileX, const int tileY) {
        foreach (ref Cover cover; this.mCovers) {
            if (cover.canWarp(tileX, tileY) == false) {
                continue;
            }

            const int destinationIndex = cover.getDestinationIndex();
            Destination* destination = &this.mDestinations[destinationIndex];
            actor.warpStart((destination.flags & DestinationFlags.FADE) != 0, destinationIndex);
            break;
        }
    }

    public void initialize(TileSet[] tileSets, ScriptGroup[] scriptGroups) {
        // Place pickup tiles.
        this.mPickups.iterate(delegate bool(index, pickup) {
            pickup.place(this.mTiles);
            return false;
        });

        // Store scriptblock tiles.
        this.mScriptBlocks.iterate(delegate bool(index, scriptBlock) {
            scriptBlock.storeTiles(this.mTiles);
            return false;
        });

        // Copy level tiles to cover backup tiles.
        this.mNodesMinimal = 0xff;
        foreach (ref Cover cover; this.mCovers) {
            cover.setDestinationData(this.mDestinations);
            cover.store();

            this.mNodesMinimal = cover.getMinimumWarpNodeCount(this.mNodesMinimal);
        }

        // Place cover tiles in level.
        foreach (ref Cover cover; this.mCovers) {
            cover.place();
        }

        // Set tileset reference.
        this.mTileSet = tileSets[this.mTileSetIndex];

        // Assign scriptgroup scripts.
        this.mScriptBlocks.iterate(delegate bool(index, scriptBlock) {
            scriptBlock.assignScripts(scriptGroups);
            return false;
        });

        // Count nodes.
        this.mActors.iterate(delegate bool(index, actor) {
            actor.setLevel(this);

            // Count dormant nodes.
            if (actor.getBaseActor() == &BASEACTOR_INFO[BaseActorIndex.NODE_DORMANT]) {
                this.mNodesDormant += 1;
            }

            return false;
        });
    }

    public void damageTile(int tileX, int tileY, int damage) {
        this.mScriptBlocks.iterate(delegate bool(index, scriptBlock) {
            if (scriptBlock.contains(tileX, tileY) == false) {
                return false;
            }
            
            Tile* tile = this.mTiles.getTile(tileX, tileY);
            if ((tile.flags & TileFlags.SPECIAL)) {
                scriptBlock.damage(damage);
            }

            return false;
        });
    }

    public void activateTrigger(const int x, const int y) {
        this.mTriggers.iterate(delegate bool(index, trigger) {
            if (trigger.canActivate(x, y) == true) {
                activateLink(trigger.getLink());
                return true;
            }
            return false;
        });

        cleanTriggers();
    }

    public void activateTriggerSpawnSpot(const int spawnSpotIndex) {
        SpawnSpot* spot = &this.mSpawnSpots[spawnSpotIndex];
        const int x1 = spot.x / TILE_SIZE;
        const int y1 = spot.y / TILE_SIZE;
        const int x2 = (spot.x + 64) / TILE_SIZE;
        const int y2 = (spot.y + 32) / TILE_SIZE;

        this.mTriggers.iterateFilter(delegate bool(index, trigger) {
            if (trigger.canActivateSpawnSpot(x1, y1, x2, y2, spawnSpotIndex) == true) {
                activateLink(trigger.getLink());
                return true;
            }

            return false;
        });

        cleanTriggers();
   }

    private void cleanTriggers() {
        this.mTriggers.iterateFilter(delegate bool(index, trigger) {
            return trigger.isUsed();
        });
    }

    public void activateLink(const int link) {
        if (link == 0) {
            return;
        }

        this.mScriptBlocks.iterate(delegate bool(index, scriptBlock) {
            scriptBlock.triggerLink(link);
            return false;
        });

        foreach (ref Cover cover; this.mCovers) {
            if (cover is null) {
                continue;
            }
            cover.triggerLink(link);
        }

        this.mActors.iterate(delegate bool(index, actor) {
            actor.triggerLink(link);
            return false;
        });

        this.mTriggers.iterate(delegate bool(index, trigger) {
            trigger.markUsed(link);
            return false;
        });
    }

    public void doPickup(Actor actor, const int x, const int y, const int pickupIndex) {
        this.mPickups.iterateFilter(delegate bool(index, pickup) {
            if (pickup.positionMatches(x, y) == false) {
                return false;
            }

            pickup.remove(this.mTiles);

            int animX = x * TILE_SIZE;
            int animY = y * TILE_SIZE;
            addAnim(AnimIndex.POP_SMALL, animX, animY, this.mTiles.getPixelZ(animX, animY), AngleType.NONE);
            // TODO: Tile is replaced 2 (or 3?) frames after pickup effect is visible.

            immutable PickupType* pickupType = &TILESET_INFO[this.mTileSetIndex].pickups[pickupIndex];
                
            Player* player = this.mGame.getPlayerForActor(actor);
            if (player !is null) {
                player.score += pickupType.score;
                if (pickupType.func !is null) {
                    pickupType.func(this.mGame, player);
                }
            }

            return true;
        });
    }

    public void nodeAddDormant() {
        this.mNodesDormant += 1;
        writefln("Added new node. %d nodes actived, %d left.", this.mNodesActive, this.mNodesDormant);
    }

    public void nodeActivate() {
        this.mNodesDormant -= 1;
        this.mNodesActive += 1;
        if (this.mNodesMinimal > 0) {
            this.mNodesMinimal -= 1;
        }

        writefln("%d nodes activated, %d left", this.mNodesActive, this.mNodesDormant);

        // Activate warp covers.
        foreach (ref Cover cover; this.mCovers) {
            if (cover.nodeActivated(mNodesActive) == true) {
                cover.activate();
            }
        }
    }

    public string getName() {
        return this.mName;
    }

    public int getNodesLeft() {
        return this.mNodesMinimal;
    }

    public TileMap getTiles() {
        return this.mTiles;
    }

    public int getLevelIndex() {
        return this.mLevelIndex;
    }

    public TileSet getTileSet() {
        return this.mTileSet;
    }

    public void setTileSetIndex(const int tileSetIndex) {
        this.mTileSetIndex = tileSetIndex;
    }

    public ActorTemplate* getActorTemplate(const int index) {
        return &this.mActorTemplates[index];
    }

    public SpawnSpot* getSpawnSpot(const int index) {
        return &this.mSpawnSpots[index];
    }

    public TileMap getTileTemplate(const int index) {
        return this.mTileTemplates[index];
    }

    public ObjectList!Fader getFaders() {
        return this.mFaders;
    }

    public Game getGame() {
        return this.mGame;
    }

    public ObjectList!Actor getActors() {
        return this.mActors;
    }
}
