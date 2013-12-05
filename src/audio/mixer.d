module audio.mixer;

import std.stdio;
import std.string;

import derelict.sdl2.sdl;


public enum ChannelPosition : uint {
    LEFT = 0,
    RIGHT = 1,
}

public struct Channel {
    Sample* sample;
    float sampleStep;
    float samplePosition = 0.0f;
    float volume = 1.0f;
    ChannelPosition position = ChannelPosition.LEFT;
    bool active;
    float[] buffer;
}

public struct Sample {
    float[] data;
    
    bool loops;
    uint loopStart;
    uint loopEnd;


    public void setData(ubyte[] data) {
        this.data = new float[data.length];

        for (int index; index < data.length; index++) {
            this.data[index] = cast(float)(cast(byte)data[index]) * (1.0f / 128.0f);
        }
    }

    public void setLoop(const uint startSample, const uint endSample) {
        this.loops = true;
        this.loopStart = startSample;
        this.loopEnd = endSample;
    }
}

public alias void delegate(Mixer mixer) MixerCallbackFunc;


extern(C) void audioCallback(void *userData, ubyte* data, int length) {
    Mixer mixer = cast(Mixer)userData;
    mixer.mix(cast(float[])data[0 .. length]);
}


class Mixer {
    private uint mSampleRate;
    private uint mBufferSamples;
    private uint mChannelCount;

    private float mVolume;

    private Sample*[] mSamples;
    private Channel*[] mChannels;

    private MixerCallbackFunc mCallback;
    private uint mCallbackCounter;
    
    // Interval between callback calls, in samples.
    private uint mCallbackInterval;


    this(const uint channelCount, const uint sampleRate, const uint bufferSamples) {
        if (SDL_AudioInit(SDL_GetAudioDriver(0)) != 0) {
            throw new Exception(format("Could not initialize SDL audio. %s", SDL_GetError()));
        }

        SDL_AudioSpec desired;
        SDL_AudioSpec obtained;

        desired.freq = sampleRate;
        desired.format = AUDIO_F32SYS;
        desired.channels = cast(ubyte)channelCount;
        desired.samples = cast(ushort)bufferSamples;
        desired.callback = &audioCallback;
        desired.userdata = cast(void*)this;

        if (SDL_OpenAudio(&desired, &obtained) < 0) {
            throw new Exception(format("Could not open audio device for playback. %s", SDL_GetError()));
        }

        writefln("Initialized sound mixer. %d Hz, %d channels, %d samples in buffer.", obtained.freq, obtained.channels, obtained.samples);

        this.mVolume = 1.0f;

        this.mChannelCount = obtained.channels;
        this.mSampleRate = obtained.freq;
        this.mBufferSamples = obtained.samples;

        SDL_PauseAudio(0);
    }

    public void destroy() {
        SDL_CloseAudio();
    }

    public void setCallback(MixerCallbackFunc callback, float interval) {
        this.mCallback = callback;
        this.mCallbackInterval = cast(uint)(this.mSampleRate * interval);
        writefln("Set mixer callback at %d samples.", this.mCallbackInterval);
    }

    public void mix(float[] output) {
        float bufferSample;
        float sample;

        output[] = 0.0f;

        for (uint sampleIndex = 0; sampleIndex < this.mBufferSamples; sampleIndex++) {
            if (this.mCallback !is null) {
                this.mCallbackCounter += 1;
                if (this.mCallbackCounter >= this.mCallbackInterval) {
                    this.mCallback(this);
                    this.mCallbackCounter = 0;
                }
            }

            foreach (int channelIndex, Channel* channel; this.mChannels) {
                if (channel.active == false || channel.sample is null) {
                    continue;
                }

                sample = channel.sample.data[cast(uint)channel.samplePosition] * channel.volume;
                bufferSample = output[sampleIndex * this.mChannelCount + channel.position];
                output[sampleIndex * this.mChannelCount + channel.position] = (bufferSample + sample) - (bufferSample * sample);
            
                channel.samplePosition += channel.sampleStep;
                if (channel.sample.loops == true && channel.samplePosition > channel.sample.loopEnd) {
                    channel.samplePosition = channel.sample.loopStart;
                }
                if (channel.samplePosition >= channel.sample.data.length) {
                    channel.active = false;
                    continue;
                }
            }
        }

        for (uint sampleIndex = 0; sampleIndex < output.length; sampleIndex++) {
            output[sampleIndex] *= this.mVolume;
        }
    }

    public void playSample(const uint channelIndex, Sample* sample, const uint sampleRate) {
        this.mChannels[channelIndex].sample = sample;
        this.mChannels[channelIndex].samplePosition = 0.0f;
        this.mChannels[channelIndex].sampleStep = cast(float)sampleRate / this.mSampleRate;
        this.mChannels[channelIndex].active = true;
    }

    public void pause(const uint channelIndex) {
        this.mChannels[channelIndex].active = false;
    }

    public void stop(const uint channelIndex) {
        this.mChannels[channelIndex].active = false;
        this.mChannels[channelIndex].sample = null;
        this.mChannels[channelIndex].samplePosition = 0.0f;
    }

    public void resume(const uint channelIndex) {
        this.mChannels[channelIndex].active = true;
    }

    public void setVolume(const uint channelIndex, const float volume) {
        if (volume < 0.0f) {
            this.mChannels[channelIndex].volume = 0.0f;
        } else if (volume > 1.0f) {
            this.mChannels[channelIndex].volume = 1.0f;
        } else {
            this.mChannels[channelIndex].volume = volume;
        }
    }

    public ChannelPosition getPosition(const uint channelIndex) {
        return this.mChannels[channelIndex].position;
    }

    public void setGlobalVolume(const float volume) {
        if (volume < 0.0f) {
            this.mVolume = 0.0f;
        } else if (volume > 1.0f) {
            this.mVolume = 1.0f;
        } else {
            this.mVolume = volume;
        }     
    }

    public Sample* allocateSample() {
        Sample* sample = new Sample();

        this.mSamples.length += 1;
        this.mSamples[this.mSamples.length - 1] = sample;

        return sample;
    }

    public Channel* allocateChannel(ChannelPosition position) {
        Channel* channel = new Channel();
        channel.position = position;
        channel.buffer = new float[this.mBufferSamples];

        this.mChannels.length += 1;
        this.mChannels[this.mChannels.length - 1] = channel;

        return channel;
    }
}