module game.pickup;

import std.stdio;

import game.tilemap;
import game.level;

import data.anims;

import util.filesystem;


final class Pickup {
    private int mX;
    private int mY;

    private Tile mTileBase;
    private Tile mTileItem;


    public void readFrom(CEFile input) {
       this.mX = input.getUShort();
        this.mY = input.getUShort();

        TileMap temp = new TileMap(1, 1);

        temp.readFrom(input);
        this.mTileBase = *temp.getTile(0, 0);

        temp.readFrom(input);
        this.mTileItem = *temp.getTile(0, 0);
    }

    public bool positionMatches(const int x, const int y) {
        return (this.mX == x && this.mY == y);
    }

    public void place(TileMap tileMap) {
        this.mTileBase = *tileMap.getTile(this.mX, this.mY);
        tileMap.setTile(this.mX, this.mY, &this.mTileItem);
    }

    public void remove(TileMap tileMap) {
        tileMap.setTile(this.mX, this.mY, &this.mTileBase);
    }
}