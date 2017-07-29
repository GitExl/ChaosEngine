module game.rjpsong;

import std.stdio;
import std.string;
import std.array;
import std.math;

import audio.mixer;

import util.filesystem;


// Note frequencies for 3 octaves.
immutable ushort[] NOTE_FREQUENCIES = [
    0x01c5, 0x01e0, 0x01fc, 0x021a, 0x023a, 0x025c, 0x0280, 0x02a6, 0x02d0, 0x02fa, 0x0328, 0x0358,
    0x00e2, 0x00f0, 0x00fe, 0x010d, 0x011d, 0x012e, 0x0140, 0x0153, 0x0168, 0x017d, 0x0194, 0x01ac,
    0x0071, 0x0078, 0x007f, 0x0087, 0x008f, 0x0097, 0x00a0, 0x00aa, 0x00b4, 0x00be, 0x00ca, 0x00d6,
];


public struct Instrument {
    uint offsetSampleData;
    uint offsetVibratoData;
    uint offsetTremoloData;

    // Vibrato.
    uint vibratoStart;
    uint vibratoLength;
    ubyte[] vibratoData;

    // Tremolo.
    uint tremoloStart;
    uint tremoloLength;
    ubyte[] tremoloData;

    // Playback volume, 0.0 to 1.0.
    float volume;

    // Volume ramp data.
    uint volumeOffset;
    float volume1;
    ushort volume1len;
    float volume2;
    ushort volume2len;
    float volume3;
    ushort volume3len;

    // Sample size. Why is this stored in these two values?
    uint sampleSizeAdd;
    uint sampleSize;

    // Loop data.
    uint loopStart;
    uint loopLength;

    // Mixer sample.
    Sample* sample;
    ubyte[] sampleData;
}

private struct SubSong {
    ubyte[4] sequences;
}

private struct Sequence {
    uint offset;
    ubyte[] patternIndices;
}

private struct Pattern {
    uint offset;
    Command[] commands;
}

private struct Command {
    byte instruction;
    byte parameter;
    uint pointer;
}

private struct ChannelState {
    bool active;

    uint sequenceIndex;
    uint sequencePatternIndex;

    uint patternIndex;
    int commandIndex;
    uint instrumentIndex;
    
    byte tempo = 6;
    byte tempo2 = 0;

    byte counter = 1;
    byte counter2 = 1;
}


class RJPSong {
    private Instrument[] mInstruments;
    private ubyte[] mSampleData;
    private byte[] mVolumeData;
    private SubSong[] mSubSongs;
    private Sequence[] mSequences;
    private Pattern[] mPatterns;

    private Mixer mMixer;
    private ChannelState[4] mChannelStates;

    private ubyte mCurrentSubSong;
    private ubyte mNextSubSong;

    public static float UPDATE_INTERVAL = 0.02003019542444870795442210722336;


    this(CEFile song, CEFile[] sampleData) {
        int blockSize;
        int baseOffset;

        // Combine sample data.
        foreach (ref CEFile sampleFile; sampleData) {
            sampleFile.reset();
            this.mSampleData ~= sampleFile.getBytes(sampleFile.getSize());
        }
        
        // Strip "RJP1" from head.
        this.mSampleData = this.mSampleData[4 .. $];

        song.reset();

        string id = cast(string)song.getBytes(3);
        if (id != "RJP" && id != "RJP") {
            throw new Exception(format("%s is an invalid Richard Joseph song file.", song.getName()));
        }
        song.getBytes(5);

        // Instruments block.
        blockSize = song.getUInt();
        this.mInstruments = new Instrument[blockSize / 32];
        foreach (ref Instrument instrument; this.mInstruments) {
            instrument.offsetSampleData = song.getUInt();
            instrument.offsetVibratoData = song.getUInt();
            instrument.offsetTremoloData = song.getUInt();
            
            instrument.volumeOffset = song.getUShort();
            instrument.volume = shortToVolume(song.getUShort());

            instrument.sampleSizeAdd = song.getUShort() * 2;
            instrument.sampleSize = song.getUShort() * 2;

            instrument.loopStart = song.getUShort() * 2;
            instrument.loopLength = song.getUShort() * 2;

            instrument.vibratoStart = song.getUShort() * 2;
            instrument.vibratoLength = song.getUShort() * 2;

            instrument.tremoloStart = song.getUShort() * 2;
            instrument.tremoloLength = song.getUShort() * 2;
        }

        // Volume data block.
        blockSize = song.getUInt();
        this.mVolumeData = cast(byte[])song.getBytes(blockSize);

        // Read volume data.
        foreach (ref Instrument instrument; this.mInstruments) {
            instrument.volume1 = byteToVolume(this.mVolumeData[instrument.volumeOffset]);
            instrument.volume1len = this.mVolumeData[instrument.volumeOffset + 2];
            
            instrument.volume2 = byteToVolume(this.mVolumeData[instrument.volumeOffset + 1]);
            instrument.volume2len = this.mVolumeData[instrument.volumeOffset + 4];
            
            instrument.volume3 = byteToVolume(this.mVolumeData[instrument.volumeOffset + 3]);
            instrument.volume3len = this.mVolumeData[instrument.volumeOffset + 5];
        }

        // Extract data from sample data.
        foreach (ref Instrument instrument; this.mInstruments) {
            instrument.sampleData = this.mSampleData[instrument.offsetSampleData .. instrument.offsetSampleData + instrument.sampleSize + instrument.sampleSizeAdd];
            instrument.vibratoData = this.mSampleData[instrument.offsetVibratoData .. instrument.offsetVibratoData + instrument.vibratoLength];
            instrument.tremoloData = this.mSampleData[instrument.offsetTremoloData .. instrument.offsetTremoloData + instrument.tremoloLength];
        }
        
        // Subsongs.
        blockSize = song.getUInt();
        this.mSubSongs = new SubSong[blockSize / 4];
        foreach (int index, ref SubSong subsong; this.mSubSongs) {
            subsong.sequences[0] = song.getUByte();
            subsong.sequences[1] = song.getUByte();
            subsong.sequences[2] = song.getUByte();
            subsong.sequences[3] = song.getUByte();
        }

        // Sequence data pointers.
        blockSize = song.getUInt();
        this.mSequences = new Sequence[blockSize / 4];
        foreach (ref Sequence sequence; this.mSequences) {
            sequence.offset = song.getUInt();
        }

        // Pattern data pointers.
        blockSize = song.getUInt();
        this.mPatterns = new Pattern[blockSize / 4];
        foreach (ref Pattern pattern; this.mPatterns) {
            pattern.offset = song.getUInt();
        }

        // Sequence data.
        blockSize = song.getUInt();
        baseOffset = song.getPosition();
        foreach (ref Sequence sequence; this.mSequences) {
            song.seekTo(baseOffset + sequence.offset);

            ubyte patternIndex;
            for(;;) {
                patternIndex = song.getUByte();
                if (patternIndex == 0) {
                    break;
                }

                sequence.patternIndices.length += 1;
                sequence.patternIndices[sequence.patternIndices.length - 1] = patternIndex;
            }
        }
        song.seekTo(baseOffset + blockSize);

        // Pattern data.
        blockSize = song.getUInt();
        baseOffset = song.getPosition();
       
        byte data;
        Command* command;
        bool patternEnd;
        foreach (int index, ref Pattern pattern; this.mPatterns) {
            if (baseOffset + pattern.offset == song.getSize()) {
                continue;
            }

            song.seekTo(baseOffset + pattern.offset);

            patternEnd = false;
            for (;;) {
                pattern.commands.length += 1;
                command = &pattern.commands[pattern.commands.length - 1];

                data = song.getByte();
                command.instruction = data;
                
                if (data < 0) {
                    // Some commands have parameters.
                    switch (data + 0x80) {
                        case 2, 3, 4, 5:
                            command.parameter = song.getUByte();
                            break;
                        case 0, 1, 7:
                            patternEnd = true;
                            break;
                        case 6:
                            command.parameter = song.getUByte();
                            command.pointer = song.getUInt();
                            break;
                        default:
                            writefln("Unknown pattern command %d", data);
                    }
                }

                if (patternEnd == true) {
                    break;
                }
            }
        }
    }

    private float byteToVolume(const ubyte volume) nothrow {
        return cast(float)volume * (1.0f / 64.0f);
    }

    private float shortToVolume(const ushort volume) nothrow {
        return cast(float)volume * (1.0f / 64.0f);
    }

    public void queueSubSong(const ubyte index) nothrow {
        this.mNextSubSong = index;
    }

    public void prepareSamples(Mixer mixer) {
        foreach (int index, ref Instrument instrument; this.mInstruments) {
            instrument.sample = mixer.allocateSample();
            instrument.sample.setData(instrument.sampleData);
            if (instrument.loopLength > 2) {
                instrument.sample.setLoop(instrument.loopStart, instrument.loopStart + instrument.loopLength);
            }

            // Clear the no longer needed sample data.
            instrument.sampleData = null;
        }
    }

    public void startSubSong(const ubyte index) nothrow {
        if (index < 0 || index >= this.mSubSongs.length) {
            //writefln("Invalid subsong index %d.", index);
        }

        stop();

        this.mCurrentSubSong = index;
        this.mNextSubSong = index;

        startSequence(0, this.mSubSongs[index].sequences[0]);
        startSequence(1, this.mSubSongs[index].sequences[1]);
        startSequence(2, this.mSubSongs[index].sequences[2]);
        startSequence(3, this.mSubSongs[index].sequences[3]);
    }

    private void startSequence(const int channel, const int index) nothrow {
        // Null sequence, silence channel.
        if (index == 0) {
            this.mChannelStates[channel].active = false;
        
        // Invalid sequence.
        } else if (index < 0 || index >= this.mSequences.length) {
            //writefln("Invalid sequence index %d.", index);
            
            this.mChannelStates[channel].sequenceIndex = 0;
            this.mChannelStates[channel].sequencePatternIndex = 0;
            this.mChannelStates[channel].active = true;

            setChannelPattern(channel, this.mSequences[0].patternIndices[0]);

        // Valid sequence, acivate channel.
        } else {
            this.mChannelStates[channel].sequenceIndex = index;
            this.mChannelStates[channel].sequencePatternIndex = 0;
            this.mChannelStates[channel].active = true;

            setChannelPattern(channel, this.mSequences[index].patternIndices[0]);
        }
    }

    private void setChannelPattern(const int index, const int patternIndex) nothrow {
        this.mChannelStates[index].patternIndex = patternIndex;
        this.mChannelStates[index].commandIndex = 0;

        this.mChannelStates[index].counter = 1;
        this.mChannelStates[index].counter2 = 1;
    }

    public void play(Mixer mixer) nothrow {
        this.mMixer = mixer;
    }

    public void stop() nothrow {
        for (int index; index < 4; index++) {
            this.mMixer.stop(index);
        }
    }

    public void update() nothrow {
        foreach (int channelIndex, ref ChannelState channelState; this.mChannelStates) {
            if (channelState.active == false) {
                continue;
            }

            channelState.counter -= 1;
            if (channelState.counter != 0) {
                continue;
            }

            channelState.counter2 -= 1;
            if (channelState.counter2 != 0) {
                channelState.counter = channelState.tempo;
                continue;
            }

            runCommands(channelState, channelIndex);

            channelState.counter = channelState.tempo;
            channelState.counter2 = channelState.tempo2;
        }
    }

    private void runCommands(ref ChannelState channelState, int channelIndex) nothrow {
        Command* command;
        bool executing;

        executing = true;
        while (executing == true) {
            command = &this.mPatterns[channelState.patternIndex].commands[channelState.commandIndex];
            
            channelState.commandIndex += 1;
            if (channelState.commandIndex >= this.mPatterns[channelState.patternIndex].commands.length) {
                channelState.commandIndex = 0;
            }

            // Play note.
            if (command.instruction >= 0) {
                Instrument* instrument = &this.mInstruments[channelState.instrumentIndex];
                const ubyte note = (cast(ubyte)command.instruction) / 2;
                const uint sampleRate = cast(uint)(8000 * (cast(float)NOTE_FREQUENCIES[0] / cast(float)NOTE_FREQUENCIES[note]));
                this.mMixer.playSample(channelIndex, instrument.sample, sampleRate);
                
                //writefln("%d: Play %d at note %d", channelIndex, channelState.instrumentIndex, note);
                executing = false;
                        
            } else {
                switch(command.instruction + 0x80) {
                    // End.
                    case 7:
                        //writefln("%d: End.", channelIndex);
                        executing = false;
                        break;

                    // Volume slide.
                    case 6:
                        //writefln("%d: Slide with value %d and data %d", channelIndex, command.parameter, command.pointer);
                        break;

                    // Set volume.
                    case 5:
                        this.mMixer.setVolume(channelIndex, byteToVolume(command.parameter));
                        //writefln("%d: set volume to %d", channelIndex, command.parameter);
                        break;

                    // Set instrument.
                    case 4:
                        if (command.parameter != 0) {
                            channelState.instrumentIndex = command.parameter;

                            Instrument* instrument = &this.mInstruments[channelState.instrumentIndex];
                            this.mMixer.setVolume(channelIndex, instrument.volume);
                        }
                        //writefln("%d: Set instrument %d", channelIndex, command.parameter);
                        break;
                        
                    // Set tempo 2.
                    case 3:
                        channelState.tempo2 = command.parameter;
                        //writefln("%d: Set tempo2 %d", channelIndex, command.parameter);
                        break;

                    // Set tempo.
                    case 2:
                        channelState.tempo = command.parameter;
                        //writefln("%d: Set tempo %d", channelIndex, command.parameter);
                        break;

                    // Stop note.
                    case 1:
                        this.mMixer.stop(channelIndex);
                        //writefln("%d: Stop note.", channelIndex);
                        executing = false;
                        break;

                    // Pattern end.
                    case 0:
                        //writefln("%d: Pattern end.", channelIndex);

                        // Start new subsong if one is queued.
                        if (this.mCurrentSubSong != this.mNextSubSong) {
                            //writefln("%d: Starting subsong %d.", channelIndex, this.mNextSubSong);
                            startSubSong(this.mNextSubSong);
                        
                        } else {
                            channelState.sequencePatternIndex += 1;
                            if (channelState.sequencePatternIndex >= this.mSequences[channelState.sequenceIndex].patternIndices.length) {
                                channelState.sequencePatternIndex = 0;
                                //writefln("%d: End of pattern list. Looping.", channelIndex);
                            }
                            setChannelPattern(channelIndex, this.mSequences[channelState.sequenceIndex].patternIndices[channelState.sequencePatternIndex]);
                        }
                        channelState.tempo2 = 1;

                        break;

                    default:
                        //writefln("Unknown pattern command %d", command.instruction);break;
                }
            }
        }
    }

    public ubyte getCurrentSubSong() {
        return this.mCurrentSubSong;
    }
}