module util.timer;

import derelict.sdl2.sdl;


final class Timer {
    private ulong mStartTime;
    private ulong mEndTime;

    private ulong mFudge;
    private ulong mDelayStart;
    private ulong mDelayTime;


    public void start() {
        this.mStartTime = getCounter();
    }

    public ulong stop() {
        this.mEndTime = getCounter();

        return this.mEndTime - this.mStartTime;
    }

    public void wait(const ulong delay) {
        // Suspend thread and measure how long the suspension lasted.
        this.mDelayStart = getCounter();
        SDL_Delay(cast(uint)(delay - this.mFudge) / 1000);
        this.mDelayTime = getCounter() - this.mDelayStart;

        // If the thread was suspended too long, wait less next time.
        if (this.mDelayTime > delay) {
            this.mFudge += 50;
		} else if (this.mDelayTime < delay) {
			this.mFudge -= 25;

        // Busywait the remaining period.
        } else {
            this.mDelayStart = getCounter();
            while(getCounter() - this.mDelayStart < delay - this.mDelayTime) {
				SDL_Delay(0);
			}
        }
    }

    public static ulong getCounter() {
        return cast(ulong)((SDL_GetPerformanceCounter() / cast(float)SDL_GetPerformanceFrequency()) * 1000000);
    }
}