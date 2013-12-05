module game.scriptblock;

import std.stdio;

import game.tilemap;
import game.script;
import game.scriptgroup;
import game.level;
import game.actor;

import data.baseactors;
import data.anims;

import util.filesystem;
import util.rectangle;


public enum ActivationMethod : int {
    IMMEDIATE = 0,
    LINK = 1
}

enum int SCRIPTBLOCK_WIDTH = 3;
enum int SCRIPTBLOCK_HEIGHT = 3;


final class ScriptBlock {
    private int mX;
    private int mY;

    private int mUnknown1;
    private int mUnknown2;

    private int mHealth;

    private int mTemplateIndex;
    
    private int mScriptGroupIndex;
    private int mScriptParameter;

    private int mLinkActivate;
    private int mLinkAbort;
    private int mLinkScript;
    private int mLink;

    private ActivationMethod mActivationMethod;
    private int mActivationDelay;

    private TileMap mTiles;

    private int mRunCount;
    private int mRunDelay;
    private int mDelayCounter;

    private Script mScriptInit;
    private Script mScriptRun;
    private Script mScriptAbort;
    private Script mScriptEnd;

    private Script mCurrentScript;
    private int mCurrentInstruction;

    private bool mIsActive;

    private Level mLevel;


    public bool update() {
        if (this.mIsActive == false) {
            return false;
        }

        if (this.mDelayCounter > 0) {
            this.mDelayCounter -= 1;
            return false;
        }

        bool executing = true;
        while (executing == true) {
            Instruction instruction = this.mCurrentScript.getInstruction(this.mCurrentInstruction);

            switch (instruction.type) {
                // Set the current delay.
                case InstructionType.SET_DELAY:
                    this.mDelayCounter = instruction.parameter;
                    this.mCurrentInstruction += 1;
                    executing = false;
                    break;

                // Spawn an actor at the location of this scriptblock.
                case InstructionType.SPAWN:
                    ActorTemplate* actorTemplate = this.mLevel.getActorTemplate(this.mScriptParameter);
                    Actor actor = this.mLevel.addActor(&BASEACTOR_INFO[actorTemplate.baseActorIndex], 0, 0);
                    actor.initializeFromTemplate(actorTemplate);
                    
                    if (actorTemplate.baseActorIndex == BaseActorIndex.NODE_DORMANT) {
                        this.mLevel.nodeAddDormant();
                    }

                    BaseActor* baseActor = actor.getBaseActor();
                    actor.setPosition(this.mX * TILE_SIZE + baseActor.spawnX, this.mY * TILE_SIZE + baseActor.spawnY);
                    actor.setLink(this.mLinkActivate);

                    if (actor.isStuck() == true) {
                        actor.setFlag(ActorFlags.JUSTSPAWNED);
                    }

                    this.mCurrentInstruction += 1;
                    executing = false;
                    break;

                // Rewinds the current script to the start.
                case InstructionType.REWIND:
                    this.mCurrentInstruction = 0;
                    executing = false;
                    break;

                /// Terminates this scriptblock entirely.
                case InstructionType.TERMINATE:
                    executing = false;
                    return true;

                /// Places tiles on the map.
                case InstructionType.SET_TEMPLATE:
                    // Copy tiles from the map to this scriptblock.
                    if (instruction.parameter == 255) {
                        this.mTiles.copyTo(this.mLevel.getTiles(), 0, 0, this.mX, this.mY, SCRIPTBLOCK_WIDTH, SCRIPTBLOCK_HEIGHT);

                    // Copy tiles from a template to the map.
                    } else {
                        TileMap tileTemplate = this.mLevel.getTileTemplate(instruction.parameter);
                        tileTemplate.copyTo(this.mLevel.getTiles(), 0, 0, this.mX, this.mY, SCRIPTBLOCK_WIDTH, SCRIPTBLOCK_HEIGHT);
                    }
                    
                    if (instruction.parameter < 255) {
                        executing = false;
                    }
                    this.mCurrentInstruction += 1;
                    break;

                // Fades in tiles.
                case InstructionType.SET_TEMPLATE_FADE:
                    // Copy tiles from the map to this scriptblock.
                    if (instruction.parameter == 255) {
                        this.mLevel.addFader(this.mTiles, this, this.mX, this.mY);

                    // Copy tiles from a template to the map.
                    } else {
                        this.mLevel.addFader(instruction.parameter, this, this.mX, this.mY);
                    }

                    this.mCurrentInstruction += 1;
                    this.mIsActive = false;
                    executing = false;
                    break;

                // Starts the run script, delaying executing if necessary.
                case InstructionType.RUN:
                    if (this.mActivationMethod == ActivationMethod.LINK) {
                        if (this.mLink == 0) {
                            startScript(this.mScriptRun);
                        }
                    
                    // Immediate scriptblocks are delayed.
                    } else if (this.mActivationMethod == ActivationMethod.IMMEDIATE) {
                        this.mDelayCounter = this.mActivationDelay;
                        startScript(this.mScriptRun);
                    }
                        
                    executing = false;
                    break;

                // Decrase this scriptblock's run counter if it is > 0 and starts the initialize script.
                case InstructionType.DECREASE_REWIND:
                    if (this.mRunCount > 0) {
                        if (this.mRunCount < 255) {
                            this.mRunCount -= 1;
                        }
                        if (this.mRunCount > 0) {
                            this.mActivationDelay = this.mRunDelay;
                            startScript(this.mScriptInit);
                        }
                    } else {
                        this.mCurrentInstruction += 1;
                    }

                    executing = false;
                    break;

                // Trigger the link defined by this scriptblock.
                case InstructionType.TRIGGER_SCRIPT_LINK:
                    this.mLevel.activateLink(this.mLinkScript);
                    this.mCurrentInstruction += 1;
                    break;

                // Spawn a pop at the location of this scriptblock.
                case InstructionType.SPAWN_POP:                    
                    ActorTemplate* actorTemplate = this.mLevel.getActorTemplate(this.mScriptParameter);
                    BaseActor* baseActor = &BASEACTOR_INFO[actorTemplate.baseActorIndex];

                    const int x = this.mX * TILE_SIZE;
                    const int y = this.mY * TILE_SIZE;

                    // Pop size depends on the baseactor size.
                    if (baseActor.height == 16) {
                        this.mLevel.addAnim(AnimIndex.POP_SMALL, x, y, this.mLevel.getTiles().getPixelZ(x + 8, y + 12), AngleType.NONE);
                    } else if (baseActor.height == 32) {
                        this.mLevel.addAnim(AnimIndex.POP_LARGE, x, y, this.mLevel.getTiles().getPixelZ(x + 16, y + 24), AngleType.NONE);
                    }
                    
                    this.mCurrentInstruction += 1;
                    break;

                // Spawn an explosion at the location of this scriptblock.
                case InstructionType.SPAWN_EXPLOSION:
                    int x = this.mX * TILE_SIZE;
                    int y = this.mY * TILE_SIZE;
                    this.mLevel.addAnim(AnimIndex.EXPLODE_LARGE, x, y, this.mLevel.getTiles().getPixelZ(x, y), AngleType.NONE);

                    this.mCurrentInstruction += 1;
                    break;

                case InstructionType.PLAY_SOUND:
                    // Unimplemented.
                    this.mCurrentInstruction += 1;
                    break;

                // Destroy a node. on this scriptblock's level.
                case InstructionType.DESTROY_NODE:
                    this.mLevel.getActors().iterate(delegate bool(index, actor) {
                        if (actor.getBaseActor() == &BASEACTOR_INFO[BaseActorIndex.NODE_DORMANT]) {
                            actor.damage(255, null, AngleType.NONE);
                            return true;
                        }

                        return false;
                    });
                    this.mCurrentInstruction += 1;
                    break;

                default:
                    writefln("Unknown instruction %d, skipping.", instruction.type);
                    this.mCurrentInstruction += 1;
                    break;
            }

            if (this.mCurrentInstruction == this.mCurrentScript.getInstructionCount()) {
                startScript(this.mScriptEnd);
            }
        }

        return false;
    }

    public void activate() {
        this.mIsActive = true;
        this.mLink = 0;
    }

    public void resume() {
        this.mIsActive = true;
    }

    public void abort() {
        startScript(this.mScriptAbort);
        this.mDelayCounter = 0;
        this.mLink = 0;
        this.mLinkAbort = 0;
    }

    private void startScript(Script script) {
        this.mCurrentScript = script;
        this.mCurrentInstruction = 0;
    }

    public void assignScripts(ScriptGroup[] scriptGroups) {
        this.mScriptInit = scriptGroups[this.mScriptGroupIndex].getScript(ScriptType.INIT);
        this.mScriptRun = scriptGroups[this.mScriptGroupIndex].getScript(ScriptType.RUN);
        this.mScriptAbort = scriptGroups[this.mScriptGroupIndex].getScript(ScriptType.ABORT);
        this.mScriptEnd = scriptGroups[this.mScriptGroupIndex].getScript(ScriptType.END);

        startScript(this.mScriptInit);
        this.mIsActive = true;
    }

    public void readFrom(CEFile input, Level level) {
        this.mLevel = level;

        this.mX = input.getUShort();
        this.mY = input.getUShort();
        
        this.mUnknown1 = input.getShort();
        this.mUnknown2 = input.getShort();
            
        this.mHealth = input.getUShort();

        this.mTemplateIndex = input.getUShort();
        this.mScriptGroupIndex = input.getUShort();
        this.mScriptParameter = input.getUShort();

        this.mLinkActivate = input.getUShort();
        this.mLinkAbort = input.getUShort();
        
        this.mTiles = new TileMap(SCRIPTBLOCK_WIDTH, SCRIPTBLOCK_HEIGHT);
        this.mTiles.readFrom(input);

        // Offsets to scriptgroups, initialized during runtime from the scriptgroup index.
        input.getUInt();
        input.getUInt();
        input.getUInt();
        input.getUInt();
        
        this.mLinkScript = input.getUShort();

        // Expand activation data.
        short activation = input.getShort();
        if (activation < 0) {
            this.mActivationMethod = ActivationMethod.LINK;
            this.mActivationDelay = 0;
            this.mLink = -activation;
        } else {
            this.mActivationMethod = ActivationMethod.IMMEDIATE;
            this.mActivationDelay = activation;
            this.mLink = 0;
        }

        this.mRunCount = input.getUByte();
        this.mRunDelay = input.getUByte();
        this.mDelayCounter = input.getUShort();
    }

    public void damage(const int damage) {
        this.mHealth -= damage;
        if (this.mHealth <= 0) {
            abort();
        }
    }

    public void triggerLink(const int link) {
        if (this.mLink == link) {
            activate();
        }
        if (this.mLinkAbort == link) {
            abort();
        }
    }

    public bool contains(const int tileX, const int tileY) {
        return (tileX >= this.mX && tileX < this.mX + SCRIPTBLOCK_WIDTH && tileY >= this.mY && tileY < this.mY + SCRIPTBLOCK_HEIGHT);
    }

    public bool intersects(ref Rectangle rect) {
        return rect.intersects(
            this.mX * TILE_SIZE,
            this.mY * TILE_SIZE,
            (this.mX + SCRIPTBLOCK_WIDTH) * TILE_SIZE,
            (this.mY + SCRIPTBLOCK_HEIGHT) * TILE_SIZE
        );
    }

    public void storeTiles(TileMap tileMap) {
        tileMap.copyTo(this.mTiles, this.mX, this.mY, 0, 0, SCRIPTBLOCK_WIDTH, SCRIPTBLOCK_HEIGHT);
    }
}