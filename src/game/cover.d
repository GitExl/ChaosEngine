module game.cover;

import std.stdio;

import game.tilemap;
import game.level;
import game.actor;

import data.anims;

import util.filesystem;


public enum EffectType : ubyte {
    NONE,
    FADE,
    POP_SMALL,
    POP_LARGE
}

public enum EffectPosition : ubyte {
    TOP_LEFT,
    TOP_CENTER,
    TOP_RIGHT,

    CENTER_LEFT,
    CENTER,
    CENTER_RIGHT,

    BOTTOM_LEFT,
    BOTTOM_CENTER,
    BOTTOM_RIGHT
}

public enum CoverType : ubyte {
    WARP,
    LINK
}


enum int COVER_WIDTH = 3;
enum int COVER_HEIGHT = 3;


final class Cover {
    private int mX;
    private int mY;

    private int mUnknown1;
    private int mUnknown2;

    private TileMap mTiles;

    private CoverType mType;

    private bool mDestinationOpened;
    private int mDestinationIndex;
    private int mDestinationLevelIndex;

    private int mActivationLink;
    private int mActivationNodeCount;
    
    private EffectType mEffectType;
    private EffectPosition mEffectPosition;

    private int mTemplateIndex;
    private bool mIsVisible;

    private Level mLevel;


    public void readFrom(CEFile input, Level level) {
        this.mLevel = level;

        this.mX = input.getUShort();
        this.mY = input.getUShort();

        this.mUnknown1 = input.getUShort();
        this.mUnknown2 = input.getUShort();

        this.mTiles = new TileMap(3, 3);
        this.mTiles.readFrom(input);

        // Expand type and possible warp destination data.
        const byte destination = input.getByte();
        if (destination < 0) {
            this.mDestinationIndex = destination + 128;
            this.mType = CoverType.WARP;
        } else {
            this.mDestinationIndex = 0;
            this.mType = CoverType.LINK;
        }
        this.mDestinationOpened = !cast(bool)((destination >> 7) & 0x1);

        // Expand activation data.
        const byte activation = input.getUByte();
        if (activation < 0) {
            this.mActivationLink = -activation;
            this.mActivationNodeCount = 0;
        } else {
            this.mActivationLink = 0;
            this.mActivationNodeCount = activation;
        }

        // Expand tile effect data.
        const byte effect = input.getUByte();
            
        // No effect at all.
        if (effect == 0) {
            this.mEffectType = EffectType.NONE;

        // Fade effect.
        } else if (effect < 0) {
            this.mEffectType = EffectType.FADE;
            
        // Pop effects.
        } else {
            this.mEffectPosition = cast(EffectPosition)((effect & 0xF) - 1);
            if ((effect & 0x10) == 0) {
                this.mEffectType = EffectType.POP_SMALL;
            } else {
                this.mEffectType = EffectType.POP_LARGE;
            }
        }

        // Expand template data.
        const byte templateIndex = input.getByte();
        if (templateIndex < 0) {
            this.mTemplateIndex = -templateIndex;
            this.mIsVisible = false;
        } else {
            this.mTemplateIndex = templateIndex;
            this.mIsVisible = true;
        }
    }

    public void setDestinationData(Destination[] destinations) {
        this.mDestinationLevelIndex = destinations[this.mDestinationIndex].levelIndex;
    }

    public void activate() {
        if (this.mIsVisible == true) {
            if (this.mEffectType == EffectType.FADE) {
                this.mLevel.addFader(this.mTiles, null, this.mX, this.mY);
            } else {
                this.mTiles.copyTo(this.mLevel.getTiles(), 0, 0, this.mX, this.mY, COVER_WIDTH, COVER_HEIGHT);
                spawnEffect();
            }
            this.mIsVisible = false;

        } else {
            if (this.mEffectType == EffectType.FADE) {
                this.mLevel.addFader(this.mTemplateIndex, null, this.mX, this.mY);
            } else {
                TileMap tileTemplate = this.mLevel.getTileTemplate(this.mTemplateIndex);
                tileTemplate.copyTo(this.mLevel.getTiles(), 0, 0, this.mX, this.mY, COVER_WIDTH, COVER_HEIGHT);
                spawnEffect();
            }
            this.mIsVisible = true;
        }

        if (this.mType == CoverType.WARP && this.mDestinationOpened == false) {
            this.mDestinationOpened = true;

            if (this.mDestinationLevelIndex != this.mLevel.getLevelIndex()) {
                writefln("Exit opened.");
            }
        }
    }

    private void spawnEffect() {
        int x;
        int y;
        int animIndex;

        if (this.mEffectType == EffectType.POP_SMALL) {
            animIndex = AnimIndex.POP_SMALL;
        } else if (this.mEffectType == EffectType.POP_LARGE) {
            animIndex = AnimIndex.POP_LARGE;
            x -= 8;
            y -= 8;
        } else {
            return;
        }

        x += (this.mX + (this.mEffectPosition % 3)) * TILE_SIZE;
        y += (this.mY + (this.mEffectPosition / 3)) * TILE_SIZE;

        this.mLevel.addAnim(animIndex, x, y, this.mLevel.getTiles().getPixelZ(x, y), AngleType.NONE);
    }

    public void triggerLink(const int link) {
        if (this.mType != CoverType.LINK) {
            return;
        }

        if (this.mActivationLink == link) {
            activate();
            this.mActivationLink = 0;
        }
    }

    public int getMinimumWarpNodeCount(const int minimumCount) {
        if (this.mType != CoverType.WARP) {
            return minimumCount;
        }
        
        if (this.mDestinationLevelIndex != this.mLevel.getLevelIndex() && this.mActivationNodeCount > 0 && this.mActivationNodeCount < minimumCount) {
            return this.mActivationNodeCount;
        }

        return minimumCount;
    }

    public bool canWarp(const int tileX, const int tileY) {
        if (this.mType != CoverType.WARP) {
            return false;
        }
        
        if (tileX < this.mX || tileY < this.mY || tileX >= this.mX + COVER_WIDTH || tileY >= this.mY + COVER_HEIGHT) {
            return false;
        }

        return true;
    }

    public int getDestinationIndex() {
        return this.mDestinationIndex;
    }

    public bool nodeActivated(const int activatedNodes) {
        return (this.mType == CoverType.WARP && activatedNodes == this.mActivationNodeCount);
    }

    public void place() {
        if (this.mIsVisible == false) {
            return;
        }

        TileMap tileTemplate = this.mLevel.getTileTemplate(this.mTemplateIndex);
        tileTemplate.copyTo(this.mLevel.getTiles(), 0, 0, this.mX, this.mY, COVER_WIDTH, COVER_HEIGHT);

        this.mTiles.markInvalid(tileTemplate);
    }

    public void store() {
        this.mLevel.getTiles().copyTo(this.mTiles, this.mX, this.mY, 0, 0, COVER_WIDTH, COVER_HEIGHT);
    }
}