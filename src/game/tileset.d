module game.tileset;

import game.bitmap;
import game.palette;
import game.tilemap;

import data.palettes;

import util.filesystem;


final class TileSet {
    private string mName;

    private Bitmap[] mTiles;
    private Bitmap mCombinedTiles;

    private ubyte[] mTileColors;

    private PaletteIndex mPaletteIndex;


    this(string name) {
        this.mName = name;
    }

    public void readTilesFrom(CEFile input, const PaletteIndex paletteIndex, const int subPaletteIndex) {
        Bitmap image;
        int startIndex;

        input.reset();

        // Calculate how many tiles are in the file.
        const uint count = cast(uint)(input.getSize() / ((TILE_SIZE * TILE_SIZE * 4) / 8));
        
        // Create or expand the tiles array.
        if (this.mTiles is null) {
            startIndex = 0;
            this.mTiles = new Bitmap[count];
        } else {
            startIndex = this.mTiles.length;
            this.mTiles.length = this.mTiles.length + count;
        }
        
        // Read each tile bitmap.
        for (int index; index < count; index++) {
            image = new Bitmap(TILE_SIZE, TILE_SIZE, 4, paletteIndex, subPaletteIndex);
            image.readPlanarFrom(input);
            image.setMaskMode(MaskMode.NONE);
            
            this.mTiles[index + startIndex] = image;
        }

        this.mPaletteIndex = paletteIndex;
    }

    public void readColorsFrom(CEFile input) {
        this.mTileColors = input.getBytes(this.mTiles.length);
    }

    public string getName() {
        return this.mName;
    }

    public Bitmap[] getTiles() {
        return this.mTiles;
    }

    public PaletteIndex getPaletteIndex() {
        return this.mPaletteIndex;
    }
}