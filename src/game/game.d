module game.game;

import std.stdio;
import std.string;

import derelict.sdl2.sdl;

import game.gamereader;
import game.level;
import game.palette;
import game.tileset;
import game.specialpower;
import game.scriptgroup;
import game.actor;
import game.bitmap;
import game.tilemap;
import game.rjpsong;
import game.render;
import game.player;

import data.text;
import data.characters;
import data.attacks;
import data.anims;
import data.baseactors;

import audio.mixer;

import behaviour.player;

import util.filesystem;
import util.timer;
import util.objectlist;
import util.rectangle;


enum int FRAMERATE = 25;

enum int PLAYAREA_WIDTH = 320 + 32;
enum int PLAYAREA_HEIGHT = 176 + 32;


final class Game {
    private Level[] mLevels;
    private Palette[] mPalettes;
    private TileSet[] mTileSets;
    private SpecialPower[] mSpecialPowers;
    private ScriptGroup[] mScriptGroups;
    private RJPSong[string] mSongs;
    private Bitmap[][string] mGraphics;

    private Player[] mPlayers;
    private Player* mConsolePlayer;
    
    private Mixer mMixer;
    private Channel*[4] mChannels;
    private RJPSong mCurrentSong;

    private Render mRender;

    private Level mCurrentLevel;
    private Rectangle mPlayArea;

    private GameReader mReader;

    private float mOpacity = 1.0f;
    private float mOpacityStep = 0.0f;
    

    this() {
        this.mPlayers = new Player[2];
        initializePlayer(0, CharacterIndex.GENTLEMAN);
        initializePlayer(1, CharacterIndex.NAVVIE);
        this.mConsolePlayer = &this.mPlayers[0];

        // Initialize sound mixer.
        this.mMixer = new Mixer(2, 44100, 2048);
        this.mChannels[0] = this.mMixer.allocateChannel(ChannelPosition.LEFT);
        this.mChannels[1] = this.mMixer.allocateChannel(ChannelPosition.RIGHT);
        this.mChannels[2] = this.mMixer.allocateChannel(ChannelPosition.RIGHT);
        this.mChannels[3] = this.mMixer.allocateChannel(ChannelPosition.LEFT);
        this.mMixer.setGlobalVolume(0.2f);
        this.mMixer.setCallback(delegate void(Mixer mixer) {
            if (this.mCurrentSong is null) {
                return;
            }
            this.mCurrentSong.update();
        }, RJPSong.UPDATE_INTERVAL);

        // Read all game data.
        this.mReader = new GameReader(this);
        this.mLevels = this.mReader.readLevels();
        this.mPalettes = this.mReader.readPalettes();
        this.mTileSets = this.mReader.readTileSets();
        this.mSpecialPowers = this.mReader.readSpecialPowers();
        this.mScriptGroups = this.mReader.readScriptGroups();
        this.mSongs = this.mReader.readSongs();
        this.mGraphics = this.mReader.readGraphics();

        this.mReader.readLevelData(this.mLevels);

        // Initialize level contents.
        foreach (ref Level level; this.mLevels) {
            level.initialize(this.mTileSets, this.mScriptGroups);
        }

        // Set up sample data.
        foreach (ref RJPSong song; this.mSongs.values) {
            song.prepareSamples(this.mMixer);
        }

        // Initialize renderer.
        patchGraphics();
        this.mRender = new Render(this.mTileSets, this.mGraphics, this.mPalettes);
}

    public void destroy() {
        this.mMixer.destroy();
        this.mRender.destroy();
    }

    private void patchGraphics() {
        // Map font characters over blank expl1616 sprites.
        Bitmap[] text = this.mGraphics["font_large_5_b"];
        Bitmap[] exp16 = this.mGraphics["sprite_expl16"];

        exp16[96] = text[0];
        exp16[97] = text[1];
        exp16[98] = text[2];
        exp16[99] = text[3];
    }

    public void loop() {
        bool keys[320];
        SDL_Event event;
        
        Timer timer = new Timer();
        long tickTime;
        long renderTime;
        long delayTime;

        // Main game loop.
        for (;;) {
            timer.start();
            while(SDL_PollEvent(&event)) {
                switch (event.type) {
                    case SDL_KEYDOWN:
                        keys[event.key.keysym.scancode] = true;
                        break;
                    case SDL_KEYUP:
                        keys[event.key.keysym.scancode] = false;
                        break;
                    case SDL_QUIT:
                        return;
                    default:
                        break;
                }
            }

            if (keys[SDL_SCANCODE_ESCAPE] == true) {
                return;
            }

            PlayerData* data = cast(PlayerData*)this.mConsolePlayer.actor.getDataPtr();
            data.moveY = 0;
            if (keys[SDL_SCANCODE_UP] == true) {
                data.moveY = -1;
            } else if (keys[SDL_SCANCODE_DOWN] == true) {
                data.moveY = 1;
            }
            
            data.moveX = 0;
            if (keys[SDL_SCANCODE_LEFT] == true) {
                data.moveX = -1;
            } else if (keys[SDL_SCANCODE_RIGHT] == true) {
                data.moveX = 1;
            }

            data.isFiring = 0;
            if (keys[SDL_SCANCODE_LCTRL] == true) {
                data.isFiring = true;
            }

            update();
            tickTime = timer.stop();

            timer.start();
            this.mRender.render(this, *this.mConsolePlayer, this.mOpacity);
            renderTime = timer.stop();

            delayTime = cast(long)(1000000.0f / FRAMERATE) - (tickTime + renderTime);
            if (delayTime > 0) {
                timer.wait(delayTime);
            }
        }
    }

    private void update() {
        Actor player = this.mConsolePlayer.actor;

        // Calculate the center of the camera.
        int centerX;
        int centerY;
        player.getCenter(centerX, centerY);
        
        // Expand around the camera center to determine the current active play area.
        // Clip play area to level bounds.
        const int pixelWidth = this.mCurrentLevel.getTiles().getPixelWidth();
        const int pixelHeight = this.mCurrentLevel.getTiles().getPixelHeight();

        this.mPlayArea.x1 = centerX - (PLAYAREA_WIDTH / 2);
        this.mPlayArea.y1 = centerY - (PLAYAREA_HEIGHT / 2);
        if (this.mPlayArea.x1 < 0) {
            this.mPlayArea.x1 = 0;
        }
        if (this.mPlayArea.y1 < 0) {
            this.mPlayArea.y1 = 0;
        }

        this.mPlayArea.x2 = this.mPlayArea.x1 + PLAYAREA_WIDTH;
        this.mPlayArea.y2 = this.mPlayArea.y1 + PLAYAREA_HEIGHT;
        if (this.mPlayArea.x2 >= pixelWidth) {
            this.mPlayArea.x1 = pixelWidth - (this.mPlayArea.x2 - this.mPlayArea.x1);
        }
        if (this.mPlayArea.y2 >= pixelHeight) {
            this.mPlayArea.y1 = pixelHeight - (this.mPlayArea.y2 - this.mPlayArea.y1);
        }
        
        // Update the current level only.
        this.mCurrentLevel.update(this, this.mPlayArea);

        // Update playing subsong.
        const ubyte subSong = cast(ubyte)(this.mCurrentLevel.getSubSongAt(centerX, centerY + 8));
        if (subSong > 0 && subSong != this.mCurrentSong.getCurrentSubSong()) {
            this.mCurrentSong.queueSubSong(subSong);
        }

        // Update fade.
        if (this.mOpacityStep != 0.0f) {
            this.mOpacity += this.mOpacityStep;
            if (this.mOpacityStep < 0.0f && this.mOpacity < 0.0f) {
                this.mOpacity = 0.0f;
                this.mOpacityStep = 0.0f;
            } else if (this.mOpacityStep > 0.0f && this.mOpacity > 1.0f) {
                this.mOpacity = 1.0f;
                this.mOpacityStep = 0.0f;
            }
        }
    }

    public void levelEnter(Actor actor, const int index, const int spawnSpotIndex) {
        Level level = this.mLevels[index];

        if (actor == this.mConsolePlayer.actor) {
            this.mCurrentLevel = level;
        
            const int worldIndex = level.getLevelIndex() / 4;
            const int levelIndex = level.getLevelIndex() % 4;

            writefln(
                "Entering world %d: \"%s\", level %d: \"%s\"",
                worldIndex + 1,
                TEXT_DATA[Text.WORLD_0 + worldIndex],
                levelIndex + 1,
                level.getName()
            );

            // Set new camera bounds.
            this.mRender.setLevel(level);

            // Start level song.
            string songName = format("world%d", worldIndex);
            writefln("Starting song %s", songName);
            startSong(songName, 0);
        }

        // Move all player actors to the new level.
        const SpawnSpot* spot = level.getSpawnSpot(spawnSpotIndex);
        for (int playerIndex; playerIndex < this.mPlayers.length; playerIndex++) {
            if (this.mPlayers[playerIndex].actor !is null) {
                this.mPlayers[playerIndex].actor.remove();
            }
            spawnPlayer(level, playerIndex, spot.x + playerIndex * 32, spot.y);
        }

        // Activate spawnspot links.
        level.activateTriggerSpawnSpot(spawnSpotIndex);
    }

    private void spawnPlayer(Level level, const int playerIndex, const int x, const int y) {
        Player* player = &this.mPlayers[playerIndex];
        
        const CharacterInfo* character = &CHARACTER_INFO[player.characterIndex];
        const SkillLevel* skill = &character.skillLevels[player.skillLevel];

        // Actor init.
        player.actor = level.addActor(&BASEACTOR_INFO[character.baseActorIndex], x, y);
        player.actor.setHealth(skill.health);
        player.actor.setSpeed(skill.speed - 2);
        player.actor.setAngle(AngleType.NORTH);
        player.actor.setFrameIndex(0);

        Attack* attack = player.actor.getAttack();
        attack.type = character.attackIndex;

        // Player actor data init.
        PlayerData* data = cast(PlayerData*)player.actor.getDataPtr();
        data.autoFireDelay = cast(byte)character.autoFireDelay;
    }

    public void fadeOut(int steps) {
        this.mOpacity = 1.0f;
        this.mOpacityStep = -(1.0f / steps);
    }

    public void fadeIn(int steps) {
        this.mOpacity = 0.0f;
        this.mOpacityStep = 1.0f / steps;
    }

    private void startSong(string songName, const ubyte subSongIndex) {
        if (this.mCurrentSong !is null) {
            this.mCurrentSong.stop();
        }

        this.mCurrentSong = this.mSongs[songName];
        this.mCurrentSong.play(this.mMixer);
        this.mCurrentSong.startSubSong(subSongIndex);
    }

    private void initializePlayer(const int playerIndex, const int characterIndex) {
        Player* player = &this.mPlayers[playerIndex];

        player.money = 0;
        player.score = 0;
        player.lives = 3;
        player.selectedSpecial = 0;
        player.specialPowerCount = 0;
        player.weaponLevel = 0;
        player.characterIndex = characterIndex;
        player.skillLevel = 0;
    }

    public Player* getPlayerForActor(Actor actor) {
        foreach (int index, ref Player player; this.mPlayers) {
            if (player.actor == actor) {
                return &this.mPlayers[index];
            }
        }

        return null;
    }

    public Player[] getPlayers() {
        return this.mPlayers;
    }

    public ref Rectangle getPlayArea() {
        return this.mPlayArea;
    }
}