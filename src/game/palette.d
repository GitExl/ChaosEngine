module game.palette;

import std.stdio;
import std.string;

import util.filesystem;


final class Palette {
    private ubyte[] mData;
    private int mSize;


    this(const int size) {
        this.mData = new ubyte[size * 3];
        this.mSize = size;
    }

    public void readFrom(CEFile input) {
        this.mData = input.getBytes(this.mData.length);
    }

    public void getColorSlice(ubyte[] dest, const int index) {
        if (index >= this.mSize) {
            throw new Exception(format("Palette index %d is out of range (%d).", index, this.mSize));
        }

        dest[0] = this.mData[index * 3 + 0];
        dest[1] = this.mData[index * 3 + 1];
        dest[2] = this.mData[index * 3 + 2];
    }
}