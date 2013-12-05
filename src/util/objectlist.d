module util.objectlist;


public final class ObjectList(ObjectType) {
    private ObjectType[] mObjects;

    private float mGrowFactor;
    private uint mListEnd;

    private alias bool delegate(uint, ObjectType) IterateFilterFunc;
    private alias bool delegate(uint, ObjectType) IterateFunc;


    this (ObjectType[] initialObjects, const float growFactor) {
        initialize(growFactor, initialObjects);
        this.mListEnd = initialObjects.length;
    }

    this (const int initialSize, const float growFactor) {
        initialize(growFactor, new ObjectType[initialSize]);

        // Create new instances.
        for (uint index; index < this.mObjects.length; index++) {
            this.mObjects[index] = new ObjectType();
        }
    }

    private void initialize(float growFactor, ObjectType[] objects) pure {
        if (growFactor <= 1.0f) {
            throw new Exception("Object list grow factor must be bigger than 1.0.");
        }

        this.mGrowFactor = growFactor;
        this.mObjects = objects;
    }

    public ObjectType getObject() {
        if (this.mListEnd == this.mObjects.length) {
            expand();
        }
        
        this.mListEnd += 1;

        return this.mObjects[this.mListEnd - 1];
    }

    private void expand() {
        uint newSize = cast(uint)(this.mObjects.length * this.mGrowFactor);
        if (newSize == this.mObjects.length) {
            newSize += 1;
        }
        this.mObjects.length = newSize;

        // Create new instances in the expanded array area.
        for (uint index = this.mListEnd; index < this.mObjects.length; index++) {
            this.mObjects[index] = new ObjectType();
        }
    }

    public void removeObject(const uint index) pure nothrow {
        // Swap the object being removed and the object at the end of the used list.
        // If the object is at the end of the used list, don't swap it.
        if (index < this.mListEnd - 1) {
            ObjectType temp = this.mObjects[index];
            this.mObjects[index] = this.mObjects[this.mListEnd - 1];
            this.mObjects[this.mListEnd - 1] = temp;
        }

        this.mListEnd -= 1;
     }

    public void iterateFilter(IterateFilterFunc func) {
        int index = 0;
        for (;;) {
            if (index == this.mListEnd) {
                break;
            }

            if (func(index, this.mObjects[index]) == true) {
                removeObject(index);
            } else {
                index++;
            }
        }
    }

    public void iterate(IterateFunc func) {
        int index = 0;
        for (;;) {
            if (index == this.mListEnd) {
                break;
            }
            if (func(index, this.mObjects[index]) == true) {
                break;
            }
            index++;
        }
    }

    public void iterateFilterReverse(IterateFilterFunc func) {
        int index = this.mListEnd - 1;
        for (;;) {
            if (func(index, this.mObjects[index]) == true) {
                removeObject(index);
            }

            if (index == 0) {
                break;
            }
            index--;
        }
    }

    public void iterateReverse(IterateFunc func) {
        int index = this.mListEnd - 1;
        for (;;) {
            if (func(index, this.mObjects[index]) == true) {
                break;
            }

            if (index == 0) {
                break;
            }
            index--;
        }
    }
}