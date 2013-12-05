module game.bitmap;

import std.stdio;

import game.palette;

import data.palettes;

import util.filesystem;


public enum MaskMode : ubyte {
    NONE = 0,
    INDEX0 = 1
}


final class Bitmap {
    private int mWidth;
    private int mHeight;
    
    private int mBitPlanes;

    private int mPaletteIndex;
    private int mSubPaletteIndex;

    private ubyte[] mData;

    private MaskMode mMaskMode;


    this(const int width, const int height, const int bitPlanes, const PaletteIndex paletteIndex, const int subPaletteIndex) {
        this.mWidth = width;
        this.mHeight = height;
        this.mBitPlanes = bitPlanes;

        this.mPaletteIndex = paletteIndex;
        this.mSubPaletteIndex = subPaletteIndex;

        this.mData = new ubyte[this.mWidth * this.mHeight];
    }

    public void getRGBAPixels(const void* pixelDestination, const uint pitchDestination, const int destX, const int destY, Palette palette) {
        int srcIndex;
        int destIndex;
        ubyte* pixels = cast(ubyte*)pixelDestination;

        // Write bitmap pixels to the surface.
        for (uint x; x < this.mWidth; x++) {
            for (uint y; y < this.mHeight; y++) {
                srcIndex = (x + y * this.mWidth);
                destIndex = (x + destX + ((y + destY) * pitchDestination)) * 4;

                if (mData[srcIndex] == 0 && this.mMaskMode == MaskMode.INDEX0) {
                    pixels[destIndex + 3] = 0;
                    pixels[destIndex + 2] = 0;
                    pixels[destIndex + 1] = 0;
                    pixels[destIndex + 0] = 0;
                } else {
                    pixels[destIndex + 3] = 255;
                    palette.getColorSlice(pixels[destIndex .. destIndex + 3], mData[srcIndex] + this.mSubPaletteIndex * 16);
                }
            }
        }
    }

    public void readChunkyFrom(CEFile input) {
        ubyte[] data = input.getBytes((this.mWidth / 2) * this.mHeight);

        int index;
        for (int y; y < this.mHeight; y++) {
            for (int x; x < this.mWidth; x += 2) {
                this.mData[y * this.mWidth + x] = (data[index] >> 4) & 0x0F;
                this.mData[y * this.mWidth + x + 1] = (data[index] >> 0) & 0x0F;
                index++;
            }
        }
    }

    public void readPlanarFrom(CEFile input) {
        const int dataSize = (this.mWidth * this.mHeight * this.mBitPlanes) / 8;
        if (input.getPosition() + dataSize > input.getSize()) {
            writefln("Warning: did not read %dx%dx%d planar bitmap from %s:%d because it will read out of bounds.", this.mWidth, this.mHeight, this.mBitPlanes, input.getName(), input.getPosition());
            return;
        }

        ubyte[] data = input.getBytes(dataSize);
        const int byteWidth = this.mWidth / 8;

        int index;
        for (int y; y < this.mHeight; y++) {
            for (int plane; plane < this.mBitPlanes; plane++) {
                for (int byteIndex; byteIndex < byteWidth; byteIndex++) {
                    for (int x; x < 8; x++) {                    
                        if ((data[index] & (1 << (7 - x))) != 0) {
                            this.mData[y * this.mWidth + x + (byteIndex * 8)] |= (1 << plane);
                        }
                    }
                    index++;
                }
            }
        }
    }

    // TODO: Fix function names. What is chunky, what is planar, what is Amiga bitmap??
    public void readACBMFrom(CEFile input) {
        const int dataSize = (this.mWidth * this.mHeight * this.mBitPlanes) / 8;
        if (input.getPosition() + dataSize > input.getSize()) {
            writefln("Warning: did not read %dx%dx%d Amiga bitmap from %s:%d because it will read out of bounds.", this.mWidth, this.mHeight, this.mBitPlanes, input.getName(), input.getPosition());
            return;
        }
        
        ubyte[] data = input.getBytes(dataSize);
        const int byteWidth = this.mWidth / 8;

        int index;
        for (int plane; plane < this.mBitPlanes; plane++) {
            for (int y; y < this.mHeight; y++) {
                for (int byteIndex; byteIndex < byteWidth; byteIndex++) {
                    for (int x; x < 8; x++) {                    
                        if ((data[index] & (1 << (7 - x))) != 0) {
                            this.mData[y * this.mWidth + x + (byteIndex * 8)] |= (1 << plane);
                        }
                    }
                    index++;
                }
            }
        }
    }

    public void copyTo(Bitmap destination, const int destinationX, const int destinationY) {
        ubyte[] destData = destination.getData();
        const uint destWidth = destination.getWidth();

        for (int x; x < this.mWidth; x++) {
            for (int y; y < this.mHeight; y++) {
                destData[x + destinationX + (y + destinationY) * destWidth] = this.mData[x + y * this.mWidth];
            }
        }
    }

    public ubyte[] getData() {
        return this.mData;
    }

    public int getWidth() {
        return this.mWidth;
    }

    public int getHeight() {
        return this.mHeight;
    }

    public void setPaletteIndex(const int index) {
        this.mPaletteIndex = index;
    }

    public void setSubPaletteIndex(const int index) {
        this.mSubPaletteIndex = index;
    }

    public int getPaletteIndex() {
        return this.mPaletteIndex;
    }

    public int getSubPaletteIndex() {
        return this.mSubPaletteIndex;
    }

    public void setMaskMode(const MaskMode maskMode) {
        this.mMaskMode = maskMode;
    }
}