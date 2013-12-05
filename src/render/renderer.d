module render.renderer;

import std.stdio;
import std.string;
import std.math;
import std.algorithm;

import derelict.sdl2.sdl;

import game.tileset;
import game.tilemap;
import game.bitmap;
import game.palette;
import game.actor;
import game.level;
import game.cover;

import data.textures;

import render.camera;
import render.texture;
import render.texturemanager;


immutable uint VIEWPORT_WIDTH = 320;
immutable uint VIEWPORT_HEIGHT = 200;

immutable uint SCALE = 4;

immutable int SPRITEQUEUE_DEFAULT_SIZE = 48;
immutable int SPRITEQUEUE_EXPANSION_SIZE = 16;


private struct SpriteJob {
    TextureRef* textureRef;
    int x;
    int y;
    int frameIndex;
    uint sortValue;
    ubyte alpha;
    
    bool colorMod;
    ubyte modR;
    ubyte modG;
    ubyte modB;
}

public struct TextureRef {
    string textureName;
    Texture texture;

    this(string newTextureName) {
        this.textureName = newTextureName;
    }
}


final class Renderer {
    // SDL render objects.
    private SDL_Window* mWindow;
    private SDL_Renderer* mRenderer;
    private SDL_Texture* mTargetTexture;

    // Fullscreen texture rectangles.
    private SDL_Rect mViewportSource;
    private SDL_Rect mRenderTargetDest;

    // Currently active camera to render through.
    private Camera mActiveCamera;

    // Default camera object.
    private Camera mDefaultCamera;

    // Texture manager.
    private TextureManager mTextures;

    // Queued sprites to sort and render.
    private SpriteJob[] mSpriteQueue;
    private int mSpriteQueueSize;


    this() {
        initialize();
    }

    public void initialize() {
        // Create window.
        this.mWindow = SDL_CreateWindow(
            "The Chaos Engine",
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            VIEWPORT_WIDTH * SCALE, VIEWPORT_HEIGHT * SCALE,
            SDL_WINDOW_SHOWN
        );
        if (this.mWindow == null) {
            throw new Exception(format("Could not create window: %s", SDL_GetError()));
        }

        // Create renderer.
        this.mRenderer = SDL_CreateRenderer(
            this.mWindow,
            -1,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE
        );
        if (this.mRenderer == null) {
            throw new Exception(format("Could not create renderer: %s", SDL_GetError()));
        }

        // Create target texture.
        this.mTargetTexture = SDL_CreateTexture(
            this.mRenderer,
            SDL_PIXELFORMAT_RGBA8888,
            SDL_TEXTUREACCESS_TARGET,
            VIEWPORT_WIDTH, VIEWPORT_HEIGHT
        );
        if (this.mTargetTexture == null) {
            throw new Exception(format("Could not create target texture: %s", SDL_GetError()));
        }

        // Set viewport rectangles for rendering.
        mViewportSource.x = 0;
        mViewportSource.y = 0;
        mViewportSource.w = VIEWPORT_WIDTH;
        mViewportSource.h = VIEWPORT_HEIGHT;

        mRenderTargetDest.x = 0;
        mRenderTargetDest.y = 0;
        mRenderTargetDest.w = VIEWPORT_WIDTH * SCALE;
        mRenderTargetDest.h = VIEWPORT_HEIGHT * SCALE;

        // Create a default camera that spans just the screen.
        this.mDefaultCamera = new Camera(VIEWPORT_WIDTH, VIEWPORT_HEIGHT, VIEWPORT_WIDTH, VIEWPORT_HEIGHT);
        this.mActiveCamera = this.mDefaultCamera;

        // Texture manager.
        this.mTextures = new TextureManager();
        
        // Default dummy texture for missing textures.
        Texture dummy = new Texture("dummy");
        dummy.readFromFile(this.mRenderer, "dummy.bmp");
        this.mTextures.setDummyTexture(dummy);

        // Initial sprite queue size.
        this.mSpriteQueue = new SpriteJob[SPRITEQUEUE_DEFAULT_SIZE];
        this.mSpriteQueueSize = 0;
    }

    public void destroy() {
        this.mTextures.clear();

        SDL_DestroyTexture(this.mTargetTexture);
        SDL_DestroyRenderer(this.mRenderer);
        SDL_DestroyWindow(this.mWindow);
    }

    public void renderStart() {
        SDL_SetRenderTarget(this.mRenderer, this.mTargetTexture);
    }

    public void renderEnd() {
        // Scale target texture to window.
        SDL_SetRenderTarget(this.mRenderer, null);
        SDL_RenderCopy(this.mRenderer, this.mTargetTexture, &this.mViewportSource, &this.mRenderTargetDest);

        // Present render output.
        SDL_RenderPresent(this.mRenderer);
    }

    public void generateTextures(TileSet[] tileSets, Bitmap[][string] graphics, Palette[] palettes) {
        Texture texture;
        
        this.mTextures.clear();

        // Build tileset textures.
        foreach (ref TileSet tileSet; tileSets) {
            texture = new Texture(tileSet.getName());
            texture.combineFromBitmaps(this.mRenderer, tileSet.getTiles(), palettes, false);
            this.mTextures.put(texture);
        }

        // Build texture list textures.
        foreach (const TextureFileInfo textureInfo; TEXTURE_FILES) {
            Bitmap[] bitmaps = graphics[textureInfo.textureName];

            if (textureInfo.worldVersions == true) {
                foreach (ref TileSet tileSet; tileSets) {
                    // Set bitmap palettes.
                    foreach (ref Bitmap bitmap; bitmaps) {
                        bitmap.setPaletteIndex(tileSet.getPaletteIndex());
                    }

                    // New texture name has it's palette index appended.
                    string textureName = format("%s_%d", toLower(textureInfo.textureName), tileSet.getPaletteIndex());
                    if (this.mTextures.exists(textureName) == true) {
                        continue;
                    }

                    texture = new Texture(textureName);
                    texture.combineFromBitmaps(this.mRenderer, bitmaps, palettes, textureInfo.masked);
                    this.mTextures.put(texture);
                }
            } else {
                texture = new Texture(textureInfo.textureName);
                texture.combineFromBitmaps(this.mRenderer, bitmaps, palettes, textureInfo.masked);
                this.mTextures.put(texture);
            }
        }

        //this.mTextures.dump();
    }

    public void setWorldTextures(TileSet tileSet) {
        Texture texture;
        string textureName;

        foreach (const ref TextureFileInfo textureInfo; TEXTURE_FILES) {
            if (textureInfo.worldVersions == false) {
                continue;
            }

            textureName = format("%s_%d", toLower(textureInfo.textureName), tileSet.getPaletteIndex());
            texture = this.mTextures.get(textureName);
            this.mTextures.put(textureInfo.textureName, texture);
        }
    }

    public void renderTileMap(TileMap tileMap, TileSet tileSet, const int x, const int y, const ubyte alpha) {
        int cameraX = cast(int)this.mActiveCamera.getX();
        int cameraY = cast(int)this.mActiveCamera.getY();

        int startX = (cameraX - x) / TILE_SIZE;
        int startY = (cameraY - y) / TILE_SIZE;
        int endX = cast(int)ceil((cameraX - x + VIEWPORT_WIDTH) / cast(float)TILE_SIZE);
        int endY = cast(int)ceil((cameraY - y + VIEWPORT_HEIGHT) / cast(float)TILE_SIZE);
        
        Tile[] tileData = tileMap.getTiles();
        int mapWidth = tileMap.getWidth();
        int mapHeight = tileMap.getHeight();

        // Clip tiles to render to viewport.
        if (startX >= mapWidth || startY >= mapHeight) {
            return;
        }
        if (endX < 0 || endY < 0) {
            return;
        }
        if (startX < 0) {
            startX = 0;
        }
        if (startY < 0) {
            startY = 0;
        }
        if (endX >= mapWidth) {
            endX = mapWidth;
        }
        if (endY >= mapHeight) {
            endY = mapHeight;
        }

        Texture texture = this.mTextures.get(tileSet.getName());
        SDL_Texture* sdlTexture = texture.getSDLTexture();

        SDL_Rect tileDest;
        tileDest.w = TILE_SIZE;
        tileDest.h = TILE_SIZE;

        if (alpha != 255) {
            SDL_SetTextureBlendMode(sdlTexture, SDL_BLENDMODE_BLEND);
            SDL_SetTextureAlphaMod(sdlTexture, alpha);
        }

        Tile* tile;
        for (int tileX = startX; tileX < endX; tileX++) {
            for (int tileY = startY; tileY < endY; tileY++) {
                tileDest.x = (tileX * TILE_SIZE + x) - cameraX;
                tileDest.y = (tileY * TILE_SIZE + y) - cameraY;
                tile = &tileData[tileX + tileY * mapWidth];

                if ((tile.flags & TileFlags.INVALID) == 0) {
                    SDL_RenderCopy(this.mRenderer, sdlTexture, texture.getRectangle(tile.tileIndex), &tileDest);
                }
            }
        }

        if (alpha != 255) {
            SDL_SetTextureBlendMode(sdlTexture, SDL_BLENDMODE_NONE);
            SDL_SetTextureAlphaMod(sdlTexture, 255);
        }
    }

    public void spriteQueueAdd(TextureRef* textureRef, const int frameIndex, const int x, const int y, const uint sortValue, const ubyte alpha) {
        // Expand queue size if needed.
        if (this.mSpriteQueueSize == this.mSpriteQueue.length) {
            this.mSpriteQueue.length = this.mSpriteQueue.length + SPRITEQUEUE_EXPANSION_SIZE;
        }

        SpriteJob* job = &this.mSpriteQueue[this.mSpriteQueueSize];
        job.textureRef = textureRef;
        job.frameIndex = frameIndex;
        job.x = x;
        job.y = y;
        job.sortValue = sortValue;
        job.alpha = alpha;
        job.colorMod = false;

        this.mSpriteQueueSize += 1;
    }

    public void spriteQueueColorMod(ubyte r, ubyte g, ubyte b) {
        SpriteJob* job = &this.mSpriteQueue[this.mSpriteQueueSize - 1];

        job.colorMod = true;
        job.modR = r;
        job.modG = g;
        job.modB = b;
    }

    public void spriteQueueFlush() {
        SDL_Texture* sdlTexture;

        sort!("a.sortValue < b.sortValue")(this.mSpriteQueue[0..this.mSpriteQueueSize]);

        foreach (ref SpriteJob job; this.mSpriteQueue[0..this.mSpriteQueueSize]) {
            validateTextureRef(job.textureRef);

            if (job.colorMod == true) {
                sdlTexture = job.textureRef.texture.getSDLTexture();
                SDL_SetTextureColorMod(sdlTexture, job.modR, job.modG, job.modB);
            }

            renderTexture(job.textureRef, job.frameIndex, job.x - cast(int)this.mActiveCamera.getX(), job.y - cast(int)this.mActiveCamera.getY(), job.alpha);

            if (job.colorMod == true) {
                SDL_SetTextureColorMod(sdlTexture, 255, 255, 255);
            }
        }

        this.mSpriteQueueSize = 0;
    }

    public void renderTexture(TextureRef* textureRef, const int frameIndex, const int x, const int y, const ubyte alpha) {
        validateTextureRef(textureRef);

        Texture texture = textureRef.texture;
        SDL_Texture* sdlTexture = texture.getSDLTexture();
        SDL_Rect* src = texture.getRectangle(frameIndex);

        // Create destination rectangle.
        SDL_Rect dest;
        dest.x = x;
        dest.y = y;
        dest.w = src.w;
        dest.h = src.h;

        if (alpha != 255) {
            SDL_SetTextureAlphaMod(sdlTexture, alpha);
        }

        SDL_RenderCopy(this.mRenderer, sdlTexture, src, &dest);

        if (alpha != 255) {
            SDL_SetTextureAlphaMod(sdlTexture, 255);
        }
    }

    public void renderRect(const int x1, const int y1, const int x2, const int y2, const ubyte r, const ubyte g, const ubyte b, const ubyte a) {
        SDL_Rect rect;

        rect.x = x1;
        rect.y = y1;
        rect.w = x2 - x1;
        rect.h = y2 - y1;

        if (a != 255) {
            SDL_SetRenderDrawBlendMode(this.mRenderer, SDL_BLENDMODE_BLEND);
        }

        SDL_SetRenderDrawColor(this.mRenderer, r, g, b, a);
        SDL_RenderFillRect(this.mRenderer, &rect);

        if (a != 255) {
            SDL_SetRenderDrawBlendMode(this.mRenderer, SDL_BLENDMODE_NONE);
        }
    }

    private void validateTextureRef(TextureRef* textureRef) {
        if (textureRef.texture is null) {
            textureRef.texture = this.mTextures.get(textureRef.textureName);
        }
    }

    public TextureManager getTextures() {
        return this.mTextures;
    }

    public SDL_Renderer* getSDLRenderer() {
        return this.mRenderer;
    }

    public void setActiveCamera(Camera camera) {
        if (camera is null) {
            this.mActiveCamera = this.mDefaultCamera;
        } else {
            this.mActiveCamera = camera;
        }
    }

    public Camera getActiveCamera() {
        return this.mActiveCamera;
    }
}