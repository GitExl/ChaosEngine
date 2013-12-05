module render.texture;

import std.stdio;
import std.string;

import derelict.sdl2.sdl;

import game.bitmap;
import game.palette;

import render.renderer;


private enum SurfaceMask : uint {
    RED = 0x000000ff,
    GREEN = 0x0000ff00,
    BLUE = 0x00ff0000,
    ALPHA = 0xff000000
}


class Texture {
    private string mName;

    private SDL_Texture* mTexture;
    private SDL_Surface* mSurface;
    private SDL_Rect[] mRectangles;

    private int mTextureSize;


    this(string name) {
        this.mName = name;
    }

    public void combineFromBitmaps(SDL_Renderer* renderer, Bitmap[] bitmaps, Palette[] palettes, bool blend) {
        // Calculate the maximum bitmap height.
        int maxHeight = 0;
        foreach (ref Bitmap bitmap; bitmaps) {
            if (bitmap.getHeight() > maxHeight) {
                maxHeight = bitmap.getHeight();
            }
        }
        
        // Find the smallest texture size that can fit all bitmaps.
        uint x;
        uint y;
        uint textureSize = 16;
        bool invalid;

        for (;;) {
            invalid = false;

            x = 0;
            y = 0;
            foreach (ref Bitmap bitmap; bitmaps) {
                if (bitmap.getWidth() > textureSize || bitmap.getHeight() > textureSize) {
                    invalid = true;
                    break;
                }

                if (x + bitmap.getWidth() > textureSize) {
                    x = 0;
                    y += maxHeight;
                    if (y + maxHeight > textureSize) {
                        invalid = true;
                        break;
                    }
                }

                x += bitmap.getWidth();
            }

            if (invalid == false) {
                break;
            }

            textureSize *= 2;
            if (textureSize == 4096) {
                break;
            }
        }

        if (invalid == true) {
            throw new Exception("Cannot combine bitmaps, texture size would be too large.");
        }

        this.mTextureSize = textureSize;

        // If a previous texture was already generated, destroy it.
        if (this.mTexture !is null) {
            SDL_DestroyTexture(this.mTexture);
        }

        // Create a new empty surface to hold the bitmap pixels.
        this.mSurface = SDL_CreateRGBSurface(
            0,
            cast(int)textureSize, cast(int)textureSize, 32,
            cast(uint)SurfaceMask.RED, cast(uint)SurfaceMask.GREEN, cast(uint)SurfaceMask.BLUE, cast(uint)SurfaceMask.ALPHA
        );
        if (this.mSurface is null) {
            throw new Exception("Cannot create surface for bitmap.");
        }

        SDL_LockSurface(this.mSurface);

        uint destX;
        uint destY;
        this.mRectangles = new SDL_Rect[bitmaps.length];
        Palette palette;

        // Copy bitmap RGBA pixel data to the surface pixel data.
        foreach (int index, ref Bitmap bitmap; bitmaps) {
            palette = palettes[bitmap.getPaletteIndex()];
            bitmap.getRGBAPixels(this.mSurface.pixels, textureSize, destX, destY, palette);

            SDL_Rect rect;
            rect.x = destX;
            rect.y = destY;
            rect.w = bitmap.getWidth();
            rect.h = bitmap.getHeight();
            this.mRectangles[index] = rect;

            destX += rect.w;
            if (destX + rect.w > textureSize) {
                destX = 0;
                destY += maxHeight;
            }
        }

        SDL_UnlockSurface(this.mSurface);

        // Create new texture from previous surface.
        this.mTexture = SDL_CreateTextureFromSurface(renderer, this.mSurface);
        if (this.mTexture is null) {
            throw new Exception("Cannot create texture for bitmap surface.");
        }

        if (blend == true) {
            SDL_SetTextureBlendMode(this.mTexture, SDL_BLENDMODE_BLEND);
        } else {
            SDL_SetTextureBlendMode(this.mTexture, SDL_BLENDMODE_NONE);
        }

        writefln("Generated texture %s (%dx%d) from %d bitmaps.", this.mName, textureSize, textureSize, bitmaps.length);
    }

    private void createFromBitmap(SDL_Renderer* renderer, Bitmap bitmap, Palette[] palettes, bool blend) {
        Bitmap[1] bitmaps = [bitmap];
        combineFromBitmaps(renderer, bitmaps, palettes, blend);
    }

    public void readFromFile(SDL_Renderer* renderer, string fileName) {
        this.mSurface = SDL_LoadBMP(toStringz(fileName));
        this.mTexture = SDL_CreateTextureFromSurface(renderer, this.mSurface);

        this.mTextureSize = this.mSurface.w;
        this.mRectangles = new SDL_Rect[1];
        this.mRectangles[0].w = this.mTextureSize;
        this.mRectangles[0].h = this.mTextureSize;

        writefln("Read texture %s (%dx%d) from %s.", this.mName, this.mTextureSize, this.mTextureSize, fileName);
    }

    public string getName() {
        return this.mName;
    }

    public SDL_Texture* getSDLTexture() {
        return this.mTexture;
    }

    public SDL_Rect* getRectangle(const int index) {
        if (index >= this.mRectangles.length) {
            if (this.mName != "dummy") {
                writefln("WARNING: rectangle index %d is out of range for texture %s. Returning index 0.", index, this.mName);
            }
            return &this.mRectangles[0];
        }
        return &this.mRectangles[index];
    }

    public void writeTo(string fileName) {
        SDL_SaveBMP(this.mSurface, toStringz(fileName));
    }

    public int getSize() {
        return this.mTextureSize;
    }
}