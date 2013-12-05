module game.specialpower;

import game.bitmap;

import util.filesystem;


final class SpecialPower {
    private string mName;
    private int mPrice;


    this (string name) {
        this.mName = name;
    }

    public void setPrice(const int price) {
        this.mPrice = price;
    }

    public string getName() {
        return this.mName;
    }

    public int getPrice() {
        return this.mPrice;
    }
}