module game.scriptgroup;

import game.script;

import util.filesystem;


public enum ScriptType : int {
    INIT,
    RUN,
    ABORT,
    END
}


final class ScriptGroup {
    private Script[4] mScripts;
    private uint[4] mScriptOffsets;


    public void readOffsetsFrom(CEFile input) {
        foreach (ref uint offset; this.mScriptOffsets) {
            offset = input.getUInt();
        }
    }

    public void readScriptsFrom(CEFile input) {
        foreach (int index, ref Script script; this.mScripts) {
            input.seekTo(this.mScriptOffsets[index]);
            
            script = new Script();
            script.readFrom(input);
        }
    }

    public Script getScript(const ScriptType type) {
        return this.mScripts[type];
    }
}