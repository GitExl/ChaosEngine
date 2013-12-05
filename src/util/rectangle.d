module util.rectangle;

public struct Rectangle {
    int x1;
    int y1;
    int x2;
    int y2;

    bool intersects(in Rectangle other) {
        return !(other.x1 > this.x2 || other.x2 < this.x1 || other.y1 > this.y2 || other.y2 < this.y1);
    }

    bool intersects(const int x1, const int y1, const int x2, const int y2) {
        return !(x1 > this.x2 || x2 < this.x1 || y1 > this.y2 || y2 < this.y1);
    }
}