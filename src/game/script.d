module game.script;

import std.stdio;

import util.filesystem;


public enum InstructionType : int {
    SET_DELAY = 0,
    SPAWN = 2,
    REWIND = 4,
    TERMINATE = 6,
    SET_TEMPLATE = 8,
    DECREASE_REWIND = 10,
    RUN = 12,
    TRIGGER_SCRIPT_LINK = 14,
    SET_TEMPLATE_FADE = 16,
    SPAWN_POP = 18,
    SPAWN_EXPLOSION = 20,
    PLAY_SOUND = 22,
    DESTROY_NODE = 24
}

public struct Instruction {
    InstructionType type;
    int parameter;
}


final class Script {
    private Instruction[] mInstructions;

    
    public void readFrom(CEFile input) {
        for(;;) {
            Instruction instruction;
            
            instruction.type = cast(InstructionType)input.getUByte();

            // Instructions with parameters.
            if (instruction.type == InstructionType.SET_DELAY ||
                instruction.type == InstructionType.SET_TEMPLATE ||
                instruction.type == InstructionType.SET_TEMPLATE_FADE ||
                instruction.type == InstructionType.SPAWN_EXPLOSION ||
                instruction.type == InstructionType.PLAY_SOUND
            ) {
                instruction.parameter = input.getUByte();
            }

            this.mInstructions.length += 1;
            this.mInstructions[this.mInstructions.length - 1] = instruction;

            // Instructions that signify the end of the script.
            if (instruction.type == InstructionType.REWIND ||
                instruction.type == InstructionType.TERMINATE ||
                instruction.type == InstructionType.DECREASE_REWIND ||
                instruction.type == InstructionType.RUN
            ) {
                break;
            }
        }
    }

    public int getInstructionCount() {
        return this.mInstructions.length;
    }

    public ref Instruction getInstruction(const int index) {
        return this.mInstructions[index];
    }
}