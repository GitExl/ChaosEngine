module util.filesystem;

import std.stdio;
import std.string;
import std.path;
import std.bitmanip;

import util.rnc;


final class CEFileSystem {
    private CEFile[string] mFiles;


    public void addFile(CEFile file) {
        this.mFiles[file.getName()] = file;
    }

    public CEFile getFile(string fileName) {
        string name = toLower(fileName);

        if (name in this.mFiles) {
            return this.mFiles[name];
        } else {
            throw new Exception(format("No file named %s in file system.", fileName));
        }
    }

    public void addArchive(string fileName, string[] fileNameList) {
        CEFile input = new CEFile(fileName);

        // Read offsets.
        uint[] offsets = new uint[fileNameList.length];
        for (int index; index < fileNameList.length; index++) {
            offsets[index] = input.getUInt();
        }

        // Read file data.
        ubyte[] signature;
        ubyte[] data;
        uint dataSize;
        uint nextOffset;
        CEFile file;

        for (int index; index < fileNameList.length; index++) {
            input.seekTo(offsets[index]);
            
            // Read header of compressed RNC data to determine size of packed data to read.
            signature = input.getBytes(4);
            if (signature == "RNC\x01") {
                input.getUInt();
                dataSize = input.getUInt() + 16;
                
            // Read raw data.
            } else {
                // Find the file offset that is closest but after the current offset.
                // Offsets are not stored in ascending order, so we need this next offset to calcualte the size of the data.
                nextOffset = input.getSize() + 1;
                for (int offsetIndex = 0; offsetIndex < fileNameList.length; offsetIndex++) {
                    if (offsets[offsetIndex] > offsets[index] && offsets[offsetIndex] < nextOffset) {
                        nextOffset = offsets[offsetIndex];
                    }
                }

                // If no closer offset was found, use the file size as the next offset to calculate the data size from.
                if (nextOffset == input.getSize() + 1) {
                    nextOffset = input.getSize();
                }

                dataSize = nextOffset - offsets[index];
            }

            // Read data into CEFile.
            input.seekTo(offsets[index]);
            data = input.getBytes(dataSize);
            file = new CEFile(fileNameList[index], data);
            file.setOffset(offsets[index]);

            addFile(file);
        }
    }
}


final class CEFile {
    private string mName;
    private uint mSize;
    private uint mPosition;
    private ubyte[] mData;
    private uint mOffset;


    this(string fileName) {
        this.mName = toLower(baseName(fileName));

        File input = File(fileName, "rb");
        this.mSize = cast(uint)input.size();
        this.mData = new ubyte[this.mSize];
        input.rawRead(this.mData);
        input.close();

        decompress();
    }

    this(string name, ubyte[] data) {
        this.mName = toLower(name);
        this.mSize = data.length;
        this.mData = data;

        decompress();
    }

    public void reset() {
        this.mPosition = 0;
    }

    public void seekTo(uint offset) {
        this.mPosition = offset;
    }

    public ubyte getUByte() {
        ubyte value = this.mData[this.mPosition];
        this.mPosition += 1;

        return value;
    }

    public byte getByte() {
        byte value = cast(byte)this.mData[this.mPosition];
        this.mPosition += 1;

        return value;
    }

    public ushort getUShort() {
        ubyte[2] data = this.mData[this.mPosition..this.mPosition + 2];
        ushort value = bigEndianToNative!ushort(data);
        this.mPosition += 2;

        return value;
    }

    public short getShort() {
        ubyte[2] data = this.mData[this.mPosition..this.mPosition + 2];
        short value = bigEndianToNative!short(data);
        this.mPosition += 2;

        return value;
    }

    public uint getUInt() {
        ubyte[4] data = this.mData[this.mPosition..this.mPosition + 4];
        uint value = bigEndianToNative!uint(data);
        this.mPosition += 4;

        return value;
    }

    public int getInt() {
        ubyte[4] data = this.mData[this.mPosition..this.mPosition + 4];
        int value = bigEndianToNative!int(data);
        this.mPosition += 4;

        return value;
    }

    public ubyte[] getBytes(const int length) {
        ubyte[] value = this.mData[this.mPosition..this.mPosition + length];
        this.mPosition += length;

        return value;
    }

    public string getString() {
        int index = this.mPosition;
        string value;

        while(index < this.mData.length) {
            if (this.mData[index] == 0) {
                value = cast(immutable(char)[])this.mData[this.mPosition..index];
                break;
            }
            index++;
        }

        this.mPosition = index + 1;
        return value;
    }

    private void decompress() {
        int unpackedSize = get_length(this.mData.ptr);
        if (unpackedSize == -1) {
            return;
        }

        ubyte[] unpackedData = new ubyte[unpackedSize];
        int result = unpack(this.mData.ptr, unpackedData.ptr);
        if (result < 0) {
            throw new Exception("Cannot unpack %s: RNC error code %d", this.mName, result);
        }

        this.mData = unpackedData;
        this.mSize = unpackedSize;
    }

    public void writeTo(string fileName) {
        File output = File(fileName, "wb");
        output.rawWrite(this.mData);
        output.close();
    }

    public bool isEOF() {
        return (this.mPosition >= this.mSize);
    }

    public string getName() {
        return this.mName;
    }

    public int getSize() {
        return this.mSize;
    }

    public int getPosition() {
        return this.mPosition;
    }

    public void setOffset(const uint offset) {
        this.mOffset = offset;
    }

    public uint getOffset() {
        return this.mOffset;
    }
}