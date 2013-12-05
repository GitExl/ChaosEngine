module game.trigger;

import util.filesystem;


public final class Trigger {
    private int mX;
    private int mY;

    private int mLink;

    private int mSpawnSpotUses;
    private int mSpawnSpotIndex;


    public void readFrom(CEFile input) {
        this.mX = input.getUShort();
        this.mY = input.getUShort();
        this.mLink = input.getUShort();

        // Expand spawnspot activation data.
        ushort spawnSpot = input.getUShort();
        if (spawnSpot > 0) {
            if (spawnSpot > 8) {
                this.mSpawnSpotUses = (spawnSpot % 8) - 1;
                this.mSpawnSpotIndex = spawnSpot / 8;
            } else {
                this.mSpawnSpotUses = 1;
                this.mSpawnSpotIndex = spawnSpot - 1;
            }
        }
    }

    public bool canActivate(const int x, const int y) {
        return (x == this.mX && y == this.mY && this.mLink != 0 && this.mSpawnSpotUses <= 0);
    }

    public int canActivateSpawnSpot(const int x1, const int y1, const int x2, const int y2, const int spawnSpotIndex) {
        if (this.mLink == 0) {
            return false;
        }

        if (this.mSpawnSpotUses <= 0) {
            return false;
        }

        if (spawnSpotIndex != this.mSpawnSpotIndex) {
            return false;
        }

        if (this.mX < x1 || this.mY < y1 || this.mX > x2 || this.mY > y2) {
            return false;
        }
        
        this.mSpawnSpotUses -= 1;
        return (this.mSpawnSpotUses <= 0);
    }

    public void markUsed(const int link) {
        if (link == this.mLink) {
            this.mLink = 0;
        }
    }

    public bool isUsed() {
        return (this.mLink == 0);
    }

    public int getLink() {
        return this.mLink;
    }
}