module game.actor;

import std.stdio;
import std.string;
import std.random;

import game.level;
import game.game;
import game.tilemap;
import game.util;
import game.player;

import data.baseactors;
import data.attacks;
import data.anims;
import data.collision;
import data.characters;

import behaviour.player;

import util.filesystem;
import util.rectangle;
import util.objectlist;


enum int FOOTPRINT_SIZE = TILE_SIZE;


enum AngleType : ubyte {
    NONE = 0,
    NORTH = 1,
    NORTHEAST = 2,
    EAST = 3,
    SOUTHEAST = 4,
    SOUTH = 5,
    SOUTHWEST = 6,
    WEST = 7,
    NORTHWEST = 8,
}

enum WarpState : ubyte {
    NONE,
    WAIT_FOR_PLAYERS,
    FADE_SCREEN_OUT,
    FADE_SCREEN_IN,
    FADE_ACTOR_OUT,
    FADE_ACTOR_IN,
}

enum uint WARP_STATE_DURATION = 20;

enum ActorFlags : ushort {
    NONE = 0,

    // Can interact with tiles such as pickups.
    INTERACTS = 1,

    // Behaves like a projectile.
    PROJECTILE = 2,

    // Is currently hurt.
    HURT = 4,

    // As a projectile, will not explode when hitting another actor.
    PENETRATES = 8,

    // Can push other actors to death, taking damage itself.
    PUSHDEATH = 16,

    // Is not pushed around by projectile impacts.
    IMMOBILE = 32,

    // Actor has just spawned from a scriptblock.
    JUSTSPAWNED = 64,

    // Can collide with players.
    SOLID = 128,

    // Draw on top of anything else.
    ONTOP = 256,

    // Dissappears when it leaves the play area.
    DISAPPEARS = 512,

    // Does not move.
    FROZEN = 1024,

    // Disable collision detection.
    NOCOLLIDE = 2048,
}


public final class Actor {
    // Position.
    private int mX;
    private int mY;
    private int mZ;

    // Render.
    private int mFrameIndex;
    private ubyte mOpacity;

    // Health.
    private int mHealth;
    private DeathType mDeathType;
    
    // Movement.
    private AngleType mAngle;
    private int mSpeed;
    private int mVelX;
    private int mVelY;

    // Warping.    
    private uint mWarpCounter;
    private WarpState mWarpState;
    private int mWarpDestinationIndex;

    // Attack.
    private Attack mAttack;
    private int mAttackRange;

    // Link.
    private int mLink;
    private int mLinkDeath;

    // Collision.
    private int mWidth;
    private int mHeight;
    private ubyte mCollisionGroup;
    private Level mLevel;

    // Projectile.
    private Actor mSource;
    private ubyte mPenetrateDelay;

    // ???
    private int mScore;
    private BaseActor* mBaseActor;
    private uint mFlags;
    private bool mRemove;
    private ubyte[16] mData;


    public void readFrom(CEFile input, ActorTemplate[] actorTemplates) {
        this.mX = input.getShort();
        this.mY = input.getShort();
        this.mHealth = input.getByte();
        this.mSpeed = input.getByte();
        this.mAttackRange = input.getByte();

        // Unknown
        input.getByte();

        this.mLinkDeath = input.getByte();
        this.mAngle = cast(AngleType)input.getUByte();

        this.mFrameIndex = input.getByte();

        ActorTemplate* actorTemplate = &actorTemplates[input.getByte()];
        setBaseActor(&BASEACTOR_INFO[actorTemplate.baseActorIndex]);
        this.mAttackRange = actorTemplate.attackRange;
        this.mScore = actorTemplate.score;

        this.mAttack.type = cast(AttackIndex)input.getByte();
        this.mAttack.delay = input.getByte();
        this.mAttack.speed = input.getByte();
        this.mAttack.distance = input.getByte();
        this.mAttack.damage = input.getByte();
        
        this.mLink = input.getByte();

        // Unknown
        input.getUShort();
    }

    public void reset() {
        this.mX = 0;
        this.mY = 0;
        this.mZ = 0;

        this.mWidth = 32;
        this.mHeight = 32;

        this.mHealth = 1;
        this.mSpeed = 1;
        
        this.mAttackRange = 0;
        this.mLinkDeath = 0;

        this.mAngle = AngleType.NONE;
        this.mVelX = 0;
        this.mVelY = 0;

        this.mFrameIndex = 0;
        this.mOpacity = 255;
        this.mScore = 0;

        this.mWarpCounter = 0;
        this.mWarpState = WarpState.NONE;
        this.mWarpDestinationIndex = 0;
        
        this.mAttack.type = AttackIndex.NONE;
        this.mAttack.delay = 0;
        this.mAttack.speed = 0;
        this.mAttack.distance = 0;
        this.mAttack.damage = 0;

        this.mLink = 0;

        this.mLevel = null;
        this.mBaseActor = null;

        this.mFlags = ActorFlags.NONE;
        this.mDeathType = DeathType.NONE;

        this.mCollisionGroup = CollideIndex.EMPTY;
        this.mSource = null;
        this.mPenetrateDelay = 0;

        this.mRemove = false;
        this.mData[] = 0;
    }

    public Actor throwProjectile(const AnimIndex animIndex, const int offsetX, const int offsetY) {
        const int offsetIndex = this.mBaseActor.projectileOffsetIndex;
        const int angleIndex = (getAngle() - 1) * 2;

        const int x = (this.mWidth / 2 - 4) + PROJECTILE_OFFSETS[offsetIndex][angleIndex];
        const int y = (this.mHeight / 2 - 4) + PROJECTILE_OFFSETS[offsetIndex][angleIndex + 1];

        Actor actorAnim = this.mLevel.addAnim(animIndex, this.mX + x + offsetX, this.mY + y + offsetY, this.mZ, this.mAngle);

        Attack* attack = actorAnim.getAttack();
        attack.damage = this.mAttack.damage;
        attack.distance = this.mAttack.distance;

        actorAnim.setSpeed(this.mAttack.speed);
        actorAnim.setFlag(ActorFlags.PROJECTILE);
        actorAnim.setFlag(ActorFlags.DISAPPEARS);
        actorAnim.setSource(this);
        actorAnim.setCollisionGroup(CollideIndex.PROJECTILES);
        actorAnim.setDeathType(DeathType.POP_SMALL);

        return actorAnim;
    }

    public Actor throwProjectile(const AnimIndex animIndex) {
        return throwProjectile(animIndex, 0, 0);
    }

    public bool canCollide(Actor other) {
        return (((1 << other.getCollisionGroup()) & COLLISION_MASKS[this.mCollisionGroup]) != 0) && (this.mZ == other.getZ());
    }

    public bool collideWith(Actor other) {
        // Damage other.
        if ((this.mFlags & ActorFlags.PROJECTILE) != 0 && this.mSource != other) {
            int damage = this.mAttack.damage;

            // This projectile penetrates the other actor.
            if ((this.mFlags & ActorFlags.PENETRATES) != 0) {
                if (this.mPenetrateDelay == 0) {
                    this.mLevel.addAnim(AnimIndex.POP_SMALL, this.mX - 4, this.mY - 4, this.mZ, AngleType.NONE);
                    this.mPenetrateDelay = 2;
                } else {
                    damage = 0;
                }

            // Die normally.
            } else {
                this.die(null);
            }

            if (damage > 0) {
                other.damage(damage, this.mSource, this.mAngle);
            }
            return true;
        
        // Push actors to death, whilst taking damage.
        } else if ((this.mFlags & ActorFlags.PUSHDEATH) != 0) {
            // TODO: how much to damage the player?
            this.damage(0, other, AngleType.NONE);
            other.damage(255, this, AngleType.NONE);
            return true;
       }

        return false;
    }

    public void damage(const int amount, Actor source, const AngleType angle) {
        if ((this.mFlags & ActorFlags.IMMOBILE) == 0 && angle != 0) {
            this.moveForward(angle, 5);
        }

        this.mFlags |= ActorFlags.HURT;

        this.mHealth -= amount;
        if (this.mHealth < 0) {
            this.die(source);
            this.mLevel.activateLink(this.mLink);
            this.mLink = 0;
        }
    }

    public void update(Game game) {
        // Actor penetration.
        if (this.mPenetrateDelay > 0) {
            this.mPenetrateDelay -= 1;
        }

        warpStateUpdate();
            
        if (this.mBaseActor.behaviourFuncUpdate !is null) {
            this.mBaseActor.behaviourFuncUpdate(this, game);
        }
    }

    private void warpStateEnter(const WarpState state) {
        this.mWarpState = state;
        this.mWarpCounter = WARP_STATE_DURATION;

        switch (state) {
            case WarpState.FADE_SCREEN_IN:
                this.mLevel.warpActorTo(this, this.mWarpDestinationIndex);
                this.mLevel.getGame().fadeIn(WARP_STATE_DURATION);
                this.mAngle = AngleType.NORTH;
                this.setFrameIndex(0);
                break;

            case WarpState.FADE_SCREEN_OUT:
                this.mLevel.getGame().fadeOut(WARP_STATE_DURATION);
                break;

            case WarpState.NONE:
                this.mOpacity = 255;
                this.mFlags &= ~ActorFlags.FROZEN;
                this.mFlags &= ~ActorFlags.NOCOLLIDE;
                break;

            case WarpState.WAIT_FOR_PLAYERS:
                this.mOpacity = 0;
                break;

            default:
                break;
        }
    }

    private void warpStateUpdate() {
        if (this.mWarpState == WarpState.NONE) {
            return;
        }

        this.mWarpCounter -= 1;
        if (this.mWarpCounter == 0) {
            // Advance to next warp state.
            switch (this.mWarpState) {
                case WarpState.FADE_SCREEN_IN:
                    warpStateEnter(WarpState.FADE_ACTOR_IN);
                    break;
                case WarpState.FADE_SCREEN_OUT:
                    warpStateEnter(WarpState.FADE_SCREEN_IN);
                    break;
                case WarpState.WAIT_FOR_PLAYERS:
                    warpStateEnter(WarpState.FADE_SCREEN_OUT);
                    break;
                case WarpState.FADE_ACTOR_IN:
                    warpStateEnter(WarpState.NONE);
                    break;
                case WarpState.FADE_ACTOR_OUT:
                    warpStateEnter(WarpState.WAIT_FOR_PLAYERS);
                    break;
                default:
                    break;
            }
        }

        switch (this.mWarpState) {
            // Fading out.
            case WarpState.FADE_ACTOR_OUT:
                this.mOpacity = cast(ubyte)((cast(float)this.mWarpCounter / WARP_STATE_DURATION) * 255);
                break;

            // Fading in.
            case WarpState.FADE_ACTOR_IN:
                this.mOpacity = cast(ubyte)(255 - (cast(float)this.mWarpCounter / WARP_STATE_DURATION) * 255);
                break;

            default:
                break;
        }
    }

    public void warpStart(bool fade, int warpDestinationIndex) {
        this.mWarpDestinationIndex = warpDestinationIndex;

        // Warp effect.
        if (fade == true) {
            warpStateEnter(WarpState.FADE_ACTOR_OUT);
        } else {
            this.mLevel.addAnim(AnimIndex.POP_LARGE, this.mX, this.mY, this.mZ, AngleType.NONE);
            warpStateEnter(WarpState.WAIT_FOR_PLAYERS);
        }

        this.mFlags |= ActorFlags.FROZEN;
        this.mFlags |= ActorFlags.NOCOLLIDE;
    }

    public void moveForward() {
        moveVelocity(this.mVelX, this.mVelY);
    }

    public void moveForward(const AngleType angle) {
        int velX;
        int velY;
        angleToAxes(angle, this.mSpeed, velX, velY);
        moveVelocity(velX, velY);
    }

    public void moveForward(const AngleType angle, const int distance) {
        int velX;
        int velY;
        angleToAxes(angle, distance, velX, velY);
        moveVelocity(velX, velY);
    }

    private void moveVelocity(const int velX, const int velY) {
        // TODO: Actor collides with dormant nodes. No nudging is performed in game. Might not even need to be performed here.

        // Projectile movement.
        if ((this.mFlags & ActorFlags.PROJECTILE) != 0) {
            if (this.mAttack.delay > 0) {
                this.mAttack.delay--;
                return;
            }

            this.mX += velX;
            this.mY += velY;

            if (clipToMapBounds() == true) {
                this.die(null);

            } else {
                const int tileX = (this.mX + this.mWidth / 2) / TILE_SIZE;
                const int tileY = (this.mY + this.mHeight / 2) / TILE_SIZE;

                this.mAttack.distance -= 1;
                if (this.mAttack.distance == 0) {
                    this.die(null);

                } else if (collidesWithTile(tileX, tileY) == true) {
                    this.mLevel.damageTile(tileX, tileY, this.mAttack.damage);
                    this.die(null);
                }
            }
        
        // Normal movement. Determine what axes to move in based on the current angle.
        } else {
            if (velX != 0 && move(velX, 0) == true && velY == 0) {
                const int nudge = (this.mY % TILE_SIZE) == 1 ? 1 : 3;

                // Nudge actor towards tiles to the left of this actor.
                if (velX < 0) {
                    // Left top tile.
                    if (collidesWithTile((this.mX - 1) / TILE_SIZE, (this.mY + this.mHeight - FOOTPRINT_SIZE - 1) / TILE_SIZE) == false) {
                        move(0, -nudge);

                    // Left bottom tile.
                    } else if (collidesWithTile((this.mX - 1) / TILE_SIZE, (this.mY + this.mHeight) / TILE_SIZE) == false) {
                        move(0, nudge);
                    }

                // Nudge actor towards tiles to the right of this actor.
                } else if (velX > 0) {
                    // Right top tile.
                    if (collidesWithTile((this.mX + this.mWidth + 1) / TILE_SIZE, (this.mY + this.mHeight - FOOTPRINT_SIZE - 1) / TILE_SIZE) == false) {
                        move(0, -nudge);

                    // Right bottom tile.
                    } else if (collidesWithTile((this.mX + this.mWidth + 1) / TILE_SIZE, (this.mY + this.mHeight) / TILE_SIZE) == false) {
                        move(0, nudge);
                    }
                }
            }

            if (velY != 0 && move(0, velY) == true && velX == 0) {
                const int nudge = (this.mX % TILE_SIZE) == 1 ? 1 : 3;

                // Nudge actor towards tiles above this actor.
                if (velY < 0) {
                    // Top right tile.
                    if (collidesWithTile((this.mX + this.mWidth - 1) / TILE_SIZE, this.mY / TILE_SIZE) == false) {
                        move(nudge, 0);

                    // Top left tile.
                    } else if (collidesWithTile(this.mX / TILE_SIZE, this.mY / TILE_SIZE) == false) {
                        move(-nudge, 0);
                    }

                // Nudge actor towards tiles below this actor.
                } else if (velY > 0) {
                    // Bottom right tile.
                    if (collidesWithTile((this.mX + this.mWidth - 1) / TILE_SIZE, (this.mY + this.mHeight + 1) / TILE_SIZE) == false) {
                        move(nudge, 0);

                    // Bottom left tile.
                    } else if (collidesWithTile(this.mX / TILE_SIZE, (this.mY + this.mHeight + 1) / TILE_SIZE) == false) {
                        move(-nudge, 0);
                    }
                }
            }

            // Track the Z height of the tile the actor is current on top of.
            updateZ();

            // Activate things below the actor.
            if ((this.mFlags & ActorFlags.INTERACTS) != 0) {
                activateFootPrint();
            }
        }
    }

    private bool clipToMapBounds() {
        bool result;

        // Prevent actors from exiting the map bounds.
        if (this.mX < 0) {
            this.mX = 0;
            result = true;
        } else if (this.mX + this.mWidth >= this.mLevel.getTiles().getPixelWidth()) {
            this.mX = this.mLevel.getTiles().getPixelWidth() - this.mWidth;
            result = true;
        }

        if (this.mY < 0) {
            this.mY = 0;
            result = true;
        } else if (this.mY + this.mHeight >= this.mLevel.getTiles().getPixelHeight()) {
            this.mY = this.mLevel.getTiles().getPixelHeight() - this.mHeight;
            result = true;
        }

        return result;
    }

    private void updateZ() {
        const int baseX = (this.mX + (this.mWidth / 2)) / TILE_SIZE;
        const int baseY = (this.mY + this.mHeight - (FOOTPRINT_SIZE / 2)) / TILE_SIZE;
        this.mZ = this.mLevel.getTiles().getTile(baseX, baseY).z;
    }

    private bool move(const int x, const int y) {
        if (x == 0 && y == 0) {
            return false;
        }

        this.mX += x;
        this.mY += y;

        // Detect a collision with tiles under the actor's footprint.
        bool result;
        iterateFootPrint(delegate(tile, tileX, tileY) {
            if (collidesWithTile(tile, tileX, tileY) == false) {
                return;
            }

            // Place this actor up against the tile that was collided with.
            if (x != 0) {
                if (x < 0) {
                    this.mX += ((tileX * TILE_SIZE) + TILE_SIZE) - this.mX;
                } else {
                    this.mX -= (this.mX + this.mWidth) - (tileX * TILE_SIZE);
                }

            } else if (y != 0) {
                if (y < 0) {
                    this.mY += ((tileY * TILE_SIZE) + TILE_SIZE - FOOTPRINT_SIZE) - this.mY;
                } else {
                    this.mY -= (this.mY + this.mHeight) - (tileY * TILE_SIZE);
                }
            }

            result = true;
        });

        if (clipToMapBounds() == true) {
            return true;
        }

        return result;
    }

    private void iterateFootPrint(TileIterateFunc func) {
        this.mLevel.getTiles().iterateRegion(
            (this.mX + 1) / TILE_SIZE,
            (this.mY + this.mHeight - FOOTPRINT_SIZE + 1) / TILE_SIZE,
            (this.mX + this.mWidth - 1) / TILE_SIZE,
            (this.mY + this.mHeight - 1) / TILE_SIZE,
            func
        );
    }

    private void activateFootPrint() {
        iterateFootPrint(delegate(Tile* tile, const int tileX, const int tileY) {
            // Pickup.
            if (tile.tileIndex >= 380) {
                this.mLevel.doPickup(this, tileX, tileY, tile.tileIndex - 380);
            }

            // Trigger.
            if ((tile.flags & TileFlags.TRIGGER) != 0) {
                this.mLevel.activateTrigger(tileX, tileY);
            }
        });
    }

    private bool collidesWithTile(const int x, const int y) {
        Tile* tile = this.mLevel.getTiles().getTile(x, y);
        return collidesWithTile(tile, x, y);
    }

    private bool collidesWithTile(Tile* tile, const int x, const int y) {
        // Detect warp tiles.
        if ((this.mFlags & ActorFlags.INTERACTS) != 0 && (tile.flags & TileFlags.WARP) != 0) {
            this.mLevel.warpActor(this, x, y);
        }

        // Unwalkable flag means walking is always impossible.
        if ((tile.flags & TileFlags.UNWALKABLE) != 0 && tile.z == this.mZ) {
            return true;
        }

        // Projectiles only care about height level above their current one.
        if ((this.mFlags & ActorFlags.PROJECTILE) != 0) {
            if (tile.z > this.mZ) {
                return true;
            }

        } else {
            // Cannot normally move from one height level to another.
            if (tile.z != this.mZ && (tile.flags & TileFlags.SPECIAL) == 0) {
                return true;
            }
        }
        
        return false;
    }

    public void moveDown() {
        this.mAngle = AngleType.SOUTH;
        this.mY += this.mSpeed;

        this.mAttack.distance -= 1;
        if (this.isStuck() == false) {
            this.removeFlag(ActorFlags.JUSTSPAWNED);
        }
    }

    public bool isStuck() {
        bool result;
        iterateFootPrint(delegate(Tile* tile, const int tileX, const int tileY) {
            if (collidesWithTile(tile, tileX, tileY) == true) {
                result = true;
            }
        });
        return result;
    }

    public void attack() {
        if (this.mAttack.type == 0) {
            return;
        }

        const AttackInfo* info = &ATTACK_INFO[this.mAttack.type];
        if (info.behaviour !is null) {
            info.behaviour(info.animIndex, this);
        }
    }

    public void setPosition(const int x, const int y) {
        this.mX = x;
        this.mY = y;

        clipToMapBounds();
        updateZ();
    }

    public void setPosition(const int x, const int y, const int z) {
        this.mX = x;
        this.mY = y;
        this.mZ = z;
    }

    private void die(Actor source) {
        // Player was the source of the death.
        if (source !is null) {
            Player* player = this.mLevel.getGame().getPlayerForActor(source);
            if (player !is null) {
                player.score += this.mScore;
            }
        }

        if (this.mBaseActor.behaviourFuncDeath !is null) {
            this.mBaseActor.behaviourFuncDeath(this);
            return;
        }

        this.mRemove = true;
        
        int index;
        int x = this.mX + (this.mWidth / 2);
        int y = this.mY + (this.mHeight / 2);
        
        switch (this.mDeathType) {
            case DeathType.POP_TINY:
                index = AnimIndex.POP_TINY;
                x -= 8;
                y -= 8;
                break;
            case DeathType.POP_SMALL:
                index = AnimIndex.POP_SMALL;
                x -= 8;
                y -= 8;
                break;
            case DeathType.EXPLODE_SMALL:
                index = AnimIndex.EXPLODE_SMALL;
                x -= 8;
                y -= 8;
                break;
            case DeathType.EXPLODE_BIG:
                index = AnimIndex.EXPLODE_LARGE;
                x -= 16;
                y -= 16;
                break;
            default:
                index = -1;
                break;
        }

        if (index != -1) {
            Actor anim = this.mLevel.addAnim(index, x, y, this.mZ + 1, AngleType.NONE);
            anim.setFlags(ActorFlags.NONE);
            anim.setCollisionGroup(CollideIndex.EMPTY);
        }
    }

    public void setBaseActor(BaseActor* baseActor) {
        this.mBaseActor = baseActor;
        this.mCollisionGroup = baseActor.collisionGroup;
        this.setFrameIndex(baseActor.spawnFrame);
        this.mFlags = baseActor.flags;
        this.mDeathType = baseActor.deathType;
        this.mWidth = baseActor.width;
        this.mHeight = baseActor.height;

        if (baseActor.hasRotations == true && this.mAngle == 0) {
            this.mAngle = AngleType.SOUTH;
        }

        if (baseActor.behaviourFuncInit !is null) {
            baseActor.behaviourFuncInit(this);
        }
    }

    public void triggerLink(const int link) {
        if (this.mLinkDeath == link) {
            damage(255, null, AngleType.NONE);
        }
    }

    public bool intersects(ref Rectangle rect) {
        if ((this.mFlags & ActorFlags.PROJECTILE) != 0) {
            return rect.intersects(
                this.mX,
                this.mY,
                this.mX,
                this.mY
            );
        } else {
            return rect.intersects(
                this.mX,
                this.mY,
                this.mX + this.mWidth,
                this.mY + this.mHeight
            );
        }
    }

    public void getRect(out Rectangle rect) {
        if ((this.mFlags & ActorFlags.PROJECTILE) != 0) {
            rect.x1 = this.mX + this.mWidth / 2;
            rect.y1 = this.mY + this.mHeight / 2;
            rect.x2 = rect.x1;
            rect.y2 = rect.x2;
        } else {
            rect.x1 = this.mX;
            rect.y1 = this.mY;
            rect.x2 = rect.x1 + this.mWidth;
            rect.y2 = rect.y1 + this.mHeight;
        }
    }

    public void initializeFromTemplate(ActorTemplate* actorTemplate) {
        this.mScore = actorTemplate.score;
        this.mHealth = actorTemplate.health;
        this.mSpeed = actorTemplate.speed;
        this.mAngle = actorTemplate.angle;
        this.mAttackRange = actorTemplate.attackRange;
        this.setAttack(actorTemplate.attack);
    }

    public Attack* getAttack() {
        return &this.mAttack;
    }

    public void getVelocity(ref int velX, ref int velY) {
        velX = this.mVelX;
        velY = this.mVelY;
    }

    public void setVelocity(const int velX, const int velY) {
        this.mVelX = velX;
        this.mVelY = velY;
    }

    public void heal(const int amount) {
        this.mHealth += amount;
    }

    public void setOpacity(ubyte opacity) {
        this.mOpacity = opacity;
    }

    public ubyte getOpacity() {
        return this.mOpacity;
    }

    public int getFrameIndex() {
        return this.mFrameIndex;
    }

    public void setFrameIndex(const int index) {
        this.mFrameIndex = index;
    }

    public int getWidth() {
        return this.mWidth;
    }

    public int getHeight() {
        return this.mHeight;
    }

    public int getX() {
        return this.mX;
    }

    public int getY() {
        return this.mY;
    }

    public int getZ() {
        return this.mZ;
    }

    public Level getLevel() {
        return this.mLevel;
    }

    public AngleType getAngle() {
        return this.mAngle;
    }

    public void setAngle(const AngleType angle) {
        this.mAngle = angle;
        angleToAxes(angle, this.mSpeed, this.mVelX, this.mVelY);
    }

    public void setLink(const int link) {
        this.mLink = link;
    }

    public int getHealth() {
        return this.mHealth;
    }

    public uint getFlags() {
        return this.mFlags;
    }

    public void setFlags(const ActorFlags flags) {
        this.mFlags = flags;
    }

    public void setFlag(const ActorFlags mask) {
        this.mFlags |= mask;
    }

    public bool getFlag(const ActorFlags mask) {
        return cast(bool)(this.mFlags & mask);
    }

    public void removeFlag(const ActorFlags mask) {
        this.mFlags &= ~mask;
    }

    public BaseActor* getBaseActor() {
        return this.mBaseActor;
    }

     public void* getDataPtr() {
        return cast(void*)this.mData.ptr;
    }

    public void setLevel(Level level) {
        this.mLevel = level;
        clipToMapBounds();
        this.updateZ();
    }

    public void setSpeed(const int speed) {
        this.mSpeed = speed;
        angleToAxes(this.mAngle, this.mSpeed, this.mVelX, this.mVelY);
    }

    public bool remove() {
        return this.mRemove;
    }

    public void remove(const bool remove) {
        this.mRemove = remove;
    }

    public void getCenter(out int x, out int y) {
        x = this.mX + this.mWidth / 2;
        y = this.mY + this.mHeight / 2;
    }

    public void setAttack(Attack attack) {
        this.mAttack = attack;
    }

    public ubyte getCollisionGroup() {
        return this.mCollisionGroup;
    }

    public void setCollisionGroup(const CollideIndex collisionGroup) {
        this.mCollisionGroup = collisionGroup;
    }

    public void setDeathType(const DeathType type) {
        this.mDeathType = type;
    }

    public void setSource(Actor actor) {
        this.mSource = actor;
    }

    public Actor getSource() {
        return this.mSource;
    }

    public void setHealth(const int health) {
        this.mHealth = health;
    }

    public ubyte getWeaponLevel() {
        Game game = this.mLevel.getGame();
        Player* player = game.getPlayerForActor(this);
        if (player is null) {
            return 1;
        }

        return player.weaponLevel;
    }
}