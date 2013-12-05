module game.tilemap;

import std.stdio;

import util.filesystem;


public enum TileFlags : uint {
	NONE = 0,
    UNWALKABLE = 1,
	SPECIAL = 2,
	WARP = 4,
	TRIGGER = 8,
    INVALID = 16,
}

private enum PackedTileMask : ushort {
	TILE = 0x01FF,
    Z = 0x003,
    FLAGS = 0x001F
}

private enum PackedTileShift : int {
	TILE = 0,
    Z = 9,
    FLAGS = 11
}


public struct Tile {
	int tileIndex;
	int z;
	TileFlags flags = TileFlags.INVALID;
}

// Size of a single tile.
public immutable int TILE_SIZE = 16;


alias void delegate(Tile* tile, const int tileX, const int tileY) TileIterateFunc;


final class TileMap {
	private Tile mTiles[];

	private int mWidth;
	private int mHeight;

    private int mPixelWidth;
    private int mPixelHeight;


	this(const int width, const int height) {
		resize(width, height);
	}

	public void resize(const int width, const int height) {
		assert(width > 0 && height > 0);

        this.mTiles.length = width * height;

		this.mWidth = width;
		this.mHeight = height;

        this.mPixelWidth = width * TILE_SIZE;
        this.mPixelHeight = height * TILE_SIZE;
	}

	public void readFrom(CEFile input) {
        ushort data;
        foreach (ref Tile tile; this.mTiles) {
            data = input.getUShort();

            // Unpack tile information.
            tile.tileIndex = (data >> PackedTileShift.TILE) & PackedTileMask.TILE;
            tile.z = (data >> PackedTileShift.Z) & PackedTileMask.Z;
            tile.flags = cast(TileFlags)((data >> PackedTileShift.FLAGS) & PackedTileMask.FLAGS);
        }
	}

    public void iterateRegion(const int startX, const int startY, const int endX, const int endY, TileIterateFunc func) {
        for (int x = startX; x <= endX; x++) {
            for (int y = startY; y <= endY; y++) {
                func(&this.mTiles[x + y * this.mWidth], x, y);
            }
        }
    }

	public void copyTo(TileMap dest, int srcX, int srcY, int destX, int destY, int width, int height) {
		Tile[] destTiles = dest.getTiles();
		
        const int destWidth = dest.getWidth();
        const int destHeight = dest.getHeight();

        // Clip source rectangle.
        if (srcX < 0) {
            width += srcX;
            srcX = 0;
        }
        if (srcY < 0) {
            height += srcY;
            srcY = 0;
        }

        if (srcX + width >= this.mWidth) {
            width = this.mWidth - srcX;
        }
        if (srcY + height >= this.mHeight) {
            height = this.mHeight - srcY;
        }

        if (width <= 0 || height <= 0) {
            return;
        }

        // Clip destination rectangle.
        if (destX < 0) {
            width += destX;
            destX = 0;
        }
        if (destY < 0) {
            height += destY;
            destY = 0;
        }
        
        if (destX + width >= destWidth) {
            width = destWidth - destX;
        }
        if (destY + height >= destHeight) {
            height = destHeight - destY;
        }

        if (width <= 0 || height <= 0) {
            return;
        }

		Tile* srcTile;
		for (int x; x < width; x++) {
            for (int y; y < height; y++) {
            	srcTile = &this.mTiles[x + srcX + (y + srcY) * this.mWidth];
				if ((srcTile.flags & TileFlags.INVALID) == 0) {
		            destTiles[destX + x + (destY + y) * destWidth] = *srcTile;
				}
			}
		}
	}

    public void markInvalid(TileMap source) {
        Tile[] sourceTiles = source.getTiles();
        const int sourceWidth = source.getWidth();

		for (int x; x < this.mWidth; x++) {
            for (int y; y < this.mHeight; y++) {
                // TODO: simplify
				if ((sourceTiles[x + (y * sourceWidth)].flags & TileFlags.INVALID) != 0) {
		            this.mTiles[x + (y * this.mWidth)].flags |= TileFlags.INVALID;
                } else {
                    this.mTiles[x + (y * this.mWidth)].flags &= ~TileFlags.INVALID;
				}
			}
		}
    }

    public Tile* getTile(const int x, const int y) {
        return &this.mTiles[x + y * this.mWidth];
    }

    public void setTile(const int x, const int y, const Tile* tile) {
        this.mTiles[x + y * this.mWidth] = *tile;
    }

	public Tile[] getTiles() {
		return this.mTiles;
	}

	public int getWidth() {
		return this.mWidth;
	}

	public int getHeight() {
		return this.mHeight;
	}

    public int getPixelWidth() {
		return this.mPixelWidth;
	}

	public int getPixelHeight() {
		return this.mPixelHeight;
	}

    public int getPixelZ(const int pixelX, const int pixelY) {
        return getTile(pixelX / TILE_SIZE, pixelY / TILE_SIZE).z;
    }
}