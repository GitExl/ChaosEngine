module game.render;

import std.conv;

import game.level;
import game.actor;
import game.game;
import game.bitmap;
import game.tileset;
import game.palette;
import game.tilemap;
import game.player;

import data.baseactors;
import data.characters;

import render.renderer;
import render.texture;
import render.camera;
import render.texturemanager;

import util.objectlist;


class Render {
    private Renderer mRenderer;
    private Camera mCamera;

    private Level mLevel;

    private TextureRef mHUDPieces1;
    private TextureRef mHUDPieces2;
    private TextureRef mHUDNumbersS;
    private TextureRef mHUDNumbersL;
    private TextureRef[] mHUDPlayers;
    private TextureRef mHUDSpecials;
    private TextureRef mHUDSpecialsBar;

    private {
        static immutable ubyte COLOR_HEALTHMAX_R = 248;
        static immutable ubyte COLOR_HEALTHMAX_G = 168;
        static immutable ubyte COLOR_HEALTHMAX_B = 0;

        static immutable ubyte COLOR_HEALTH_R = 0;
        static immutable ubyte COLOR_HEALTH_G = 128;
        static immutable ubyte COLOR_HEALTH_B = 0;
    }


    this(TileSet[] tileSets, Bitmap[][string] graphics, Palette[] palettes) {
        this.mRenderer = new Renderer();
        this.mCamera = this.mRenderer.getActiveCamera();
        this.mCamera.setSize(this.mCamera.getViewWidth(), this.mCamera.getViewHeight() - 24);

        // Build all game textures.
        this.mRenderer.generateTextures(tileSets, graphics, palettes);

        // HUD textures.
        this.mHUDPieces1.textureName = "hud_pieces1";
        this.mHUDPieces2.textureName = "hud_pieces2";
        this.mHUDNumbersS.textureName = "hud_numbers_small";
        this.mHUDNumbersL.textureName = "hud_numbers_large";
        this.mHUDSpecials.textureName = "hud_specials";
        this.mHUDSpecialsBar.textureName = "hud_specials_bar";

        // Player portrait HUD textures.
        this.mHUDPlayers = [
            TextureRef("hud_player0"),
            TextureRef("hud_player1"),
            TextureRef("hud_player2"),
            TextureRef("hud_player3"),
            TextureRef("hud_player4"),
            TextureRef("hud_player5"),
        ];
    }

    public void destroy() {
        this.mLevel = null;
        this.mCamera = null;

        this.mRenderer.destroy();
    }

    public void setLevel(Level level) {
        this.mLevel = level;

        // Set camera bounds.
        TileMap tiles = level.getTiles();
        this.mCamera.setBounds(tiles.getPixelWidth(), tiles.getPixelHeight());

        // Assign sprite textures that need the current level's palette.
        this.mRenderer.setWorldTextures(level.getTileSet());
    }

    public void render(Game game, ref Player consolePlayer, float opacity) {
        Renderer renderer = this.mRenderer;
        renderer.renderStart();

        int centerX;
        int centerY;
        consolePlayer.actor.getCenter(centerX, centerY);
        this.mCamera.centerOn(centerX, centerY);

        // Level.
        renderer.renderTileMap(this.mLevel.getTiles(), this.mLevel.getTileSet(), 0, 0, 255);
 
        // Faders.
        ObjectList!Fader faders = this.mLevel.getFaders();
        faders.iterate(delegate bool(index, fader) {
            renderer.renderTileMap(fader.tiles, this.mLevel.getTileSet(), fader.x * TILE_SIZE, fader.y * TILE_SIZE, 255 - cast(ubyte)fader.alpha);
            return false;
        });

        // Actors.
        // Z modifier is the surface area of the level in pixels. For each Z level this surface area is added to the sortable value.
        const uint zModifier = (this.mLevel.getTiles().getWidth() * TILE_SIZE) * (this.mLevel.getTiles().getHeight() * TILE_SIZE);
        uint z;
        ubyte actorOpacity;

        ObjectList!Actor actors = this.mLevel.getActors();
        BaseActor* baseActor;
        actors.iterateReverse(delegate bool(index, actor) {
            BaseActor* baseActor = actor.getBaseActor();

            actorOpacity = actor.getOpacity();
            if (actorOpacity == 0) {
                return false;
            }

            if (this.mCamera.isVisible(actor.getX(), actor.getY(), actor.getWidth(), actor.getHeight()) == false) {
                return false;
            }

            // Calculate Z height for depth sorting.
            z = actor.getY() + actor.getHeight() - 16;
            z += zModifier * actor.getZ();
            if (actor.getFlag(ActorFlags.ONTOP) == true) {
                z = uint.max;
            }

            renderer.spriteQueueAdd(&baseActor.textureRef, actor.getFrameIndex(), actor.getX(), actor.getY(), z, actorOpacity);
            if (actor.getFlag(ActorFlags.HURT) == true) {
                renderer.spriteQueueColorMod(255, 0, 0);
                actor.removeFlag(ActorFlags.HURT);
            }

            return false;
        });
        renderer.spriteQueueFlush();

        // HUD.
        renderer.renderRect(0, 176, 320, 200, 0, 0, 0, 255);

        // Player bars.
        Player[] players = game.getPlayers();
        renderHUDPanel(0, 176, &players[0]);
        renderHUDPanel(200, 176, &players[1]);

        // Center bar.
        for (int index; index < 5; index++) {
            renderer.renderTexture(&this.mHUDPieces1, 6 + index, 120 + index * 16, 176, 255);
        }

        // Center bar text.
        const uint totalMoney = players[0].money + players[1].money;
        renderHUDDigits(&this.mHUDNumbersS, 165, 184, totalMoney, 4, 6);
        renderHUDDigits(&this.mHUDNumbersL, 130, 183, this.mLevel.getNodesLeft(), 2, 7);

        // Fade rectangle.
        if (opacity < 1.0f) {
            renderer.renderRect(0, 0, 320, 200, 0, 0, 0, cast(ubyte)(255 - (255 * opacity)));
        }

        renderer.renderEnd();
    }

    private void renderHUDPanel(const int x, const int y, Player* player) {
        this.mRenderer.renderTexture(&this.mHUDPlayers[player.characterIndex], 0, x, y + 1, 255);

        for (int index; index < 6; index++) {
            this.mRenderer.renderTexture(&this.mHUDPieces1, index, 24 + (index * 16) + x, y, 255);
        }

        this.mRenderer.renderTexture(&this.mHUDPieces2, 0, 88 + x, y, 255);

        // Lives and score.
        renderHUDDigits(&this.mHUDNumbersS, x + 39, y + 6, player.score, 6, 6);
        renderHUDDigits(&this.mHUDNumbersL, x + 17, y + 4, player.lives, 2, 7);

        // Health.
        const CharacterInfo* character = &CHARACTER_INFO[player.characterIndex];
        const SkillLevel* skillLevel = &character.skillLevels[player.skillLevel];
        this.mRenderer.renderRect(x + 33, y + 19, x + 32 + (skillLevel.health / 2), y + 23, COLOR_HEALTHMAX_R, COLOR_HEALTHMAX_G, COLOR_HEALTHMAX_B, 255);
        this.mRenderer.renderRect(x + 33, y + 19, x + 32 + (player.actor.getHealth() / 2), y + 23, COLOR_HEALTH_R, COLOR_HEALTH_G, COLOR_HEALTH_B, 255);

        // Selected special power.
        const int specialIndex = character.specialPowers[player.selectedSpecial];
        this.mRenderer.renderTexture(&this.mHUDSpecials, specialIndex, x + 90, y + 5, 255);

        // Special power bar.
        for (int index; index < player.specialPowerCount; index++) {
            this.mRenderer.renderTexture(&this.mHUDSpecialsBar, 0, x + 110, y + 19 - index * 3, 255);
        }
    }

    private void renderHUDDigits(TextureRef* textureRef, const int x, const int y, const int number, const int length, const int digitSize) {
        string value = to!string(number);

        int currentX = x + length * digitSize;
        int val;
        for (int index; index < length; index++) {
            if (index >= value.length) {
                val = 0;
            } else {
                val = cast(char)(value[value.length - index - 1]) - 48;
            }

            this.mRenderer.renderTexture(textureRef, val, currentX, y, 255);
            currentX -= digitSize;
        }
    }

    public void dumpTextures() {
        this.mRenderer.dumpTextures();
    }
}