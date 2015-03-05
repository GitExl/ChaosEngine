module render.texturemanager;

import std.stdio;
import std.file;

import derelict.sdl2.sdl;

import render.texture;


final class TextureManager {
    private Texture mDummy;
    private Texture[string] mTextures;


    public Texture get(string name) {
        Texture texture = this.mTextures.get(name, null);
        if (texture is null) {
            writefln("WARNING: cannot find texture %s. Returning dummy.", name);
            return this.mDummy;
        }
        return texture;
    }

    public void put(Texture texture) {
        this.mTextures[texture.getName()] = texture;
    }

    public void put(string name, Texture texture) {
        this.mTextures[name] = texture;
    }

    public bool exists(string name) {
        if (name in this.mTextures) {
            return true;
        }

        return false;
    }

    public void clear() {
        writefln("Clearing texture list.");

        foreach(Texture texture; this.mTextures.values) {
            SDL_DestroyTexture(texture.getSDLTexture());
        }

        this.mTextures = (Texture[string]).init;
    }

    public void dump() {
        if (!exists("textures")) {
            mkdir("textures");
        }
        
        foreach (ref Texture texture; this.mTextures.values) {
            texture.writeTo("textures/" ~ texture.getName() ~ ".bmp");
        }
    }

    public Texture[] getTextures() {
        return this.mTextures.values();
    }

    public void setDummyTexture(Texture dummy) {
        this.mDummy = dummy;
    }
}