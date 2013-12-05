module render.camera;

import std.math;


class Camera {
    private float mX = 0;
    private float mY = 0;

    private int mViewWidth;
    private int mViewHeight;

    private int mMaxX;
    private int mMaxY;

    private float mVelX = 0;
    private float mVelY = 0;


    this(const uint viewWidth, const int viewHeight, const int maxX, const int maxY) {
        this.mViewWidth = viewWidth;
        this.mViewHeight = viewHeight;

        this.mMaxX = maxX;
        this.mMaxY = maxY;
    }

    public void setSize(const int width, const int height) {
        this.mViewWidth = width;
        this.mViewHeight = height;

        clip();
    }

    public void setBounds(const int maxX, const int maxY) {
        this.mMaxX = maxX;
        this.mMaxY = maxY;

        clip();
    }

    public void thrust(const float x, const float y) {
        this.mVelX += x;
        this.mVelY += y;
    }

    public bool isVisible(const int x, const int y, const int width, const int height) {
        if (x + width < this.mX || y + height < this.mY) {
            return false;
        }
        if (x > this.mX + this.mViewWidth || y > this.mY + this.mViewHeight) {
            return false;
        }

        return true;
    }

    public void centerOn(const int x, const int y) {
        this.mX = x - (this.mViewWidth / 2);
        this.mY = y - (this.mViewHeight / 2);

        clip();
    }

    public void update() {
        this.mX += this.mVelX;
        this.mY += this.mVelY;

        clip();

        this.mVelX *= 0.9f;
        this.mVelY *= 0.9f;

        if (abs(this.mVelX) < 0.01f) {
            this.mVelX = 0;
        }

        if (abs(this.mVelY) < 0.01f) {
            this.mVelY = 0;
        }
    }

    public void move(const int x, const int y) {
        this.mX += x;
        this.mY += y;

        this.clip();
    }

    private void clip() {
        if (this.mX < 0) {
            this.mX = 0;
        }

        if (this.mY < 0) {
            this.mY = 0;
        }

        if (this.mX + this.mViewWidth >= this.mMaxX) {
            this.mX = this.mMaxX - this.mViewWidth;
        }

        if (this.mY + this.mViewHeight >= this.mMaxY) {
            this.mY = this.mMaxY - this.mViewHeight;
        }
    }

    public int getViewWidth() {
        return this.mViewWidth;
    }

    public int getViewHeight() {
        return this.mViewHeight;
    }

    public float getX() {
        return this.mX;
    }

    public float getY() {
        return this.mY;
    }
}