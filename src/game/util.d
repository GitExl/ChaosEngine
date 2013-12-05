module game.util;

import std.math;

import game.actor;


public void angleToAxes(const int angle, const int distance, ref int x, ref int y) {
    x = 0;
    y = 0;

    if (angle == 0) {
        return;
    }

    if (angle == 1) {
        y -= distance;
    } else if (angle == 2) {
        x += distance;
        y -= distance;
    } else if (angle == 3) {
        x += distance;
    } else if (angle == 4) {
        x += distance;
        y += distance;
    } else if (angle == 5) {
        y += distance;
    } else if (angle == 6) {
        x -= distance;
        y += distance;
    } else if (angle == 7) {
        x -= distance;
    } else if (angle == 8) {
        x -= distance;
        y -= distance;
    }
}

public void faceActor(Actor actor, Actor faceTo) {
    int centerX1 = actor.getX() + (actor.getWidth() / 2);
    int centerY1 = actor.getY() + (actor.getHeight() / 2);

    int centerX2 = faceTo.getX() + (faceTo.getWidth() / 2);
    int centerY2 = faceTo.getY() + (faceTo.getHeight() / 2);

    int deltaX = centerX2 - centerX1;
    int deltaY = centerY2 - centerY1;

    int angle = (cast(int)(atan2(cast(float)deltaY, cast(float)deltaX) * 180 / PI) + 90) % 360;
    if (angle >= 338 || angle < 23) {
        angle = AngleType.NORTH;
    } else if (angle >= 23 && angle < 68) {
        angle = AngleType.NORTHEAST;
    } else if (angle >= 68 && angle < 113) {
        angle = AngleType.EAST;
    } else if (angle >= 113 && angle < 158) {
        angle = AngleType.SOUTHEAST;
    } else if (angle >= 158 && angle < 203) {
        angle = AngleType.SOUTH;
    } else if (angle >= 203 && angle < 248) {
        angle = AngleType.SOUTHWEST;
    } else if (angle >= 248 && angle < 293) {
        angle = AngleType.WEST;
    } else if (angle >= 293 && angle < 338) {
        angle = AngleType.NORTHWEST;
    }

    actor.setAngle(cast(AngleType)angle);
}