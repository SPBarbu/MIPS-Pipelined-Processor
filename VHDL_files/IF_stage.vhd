LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY IF_stage IS
    GENERIC (RAM_SIZE : INTEGER := 32768);
    PORT (
        clock : IN STD_LOGIC;
        --jump target as returned for branch or jump 
        jump_target : IN INTEGER RANGE 0 TO RAM_SIZE - 1;
        --specifies if the jump target is valid
        valid_jump_target : IN STD_LOGIC;
        --bit for stalling
        if_stall : IN STD_LOGIC;
        ------------------------------------------------------------------------------
        --raw instruction data to decode
        instruction_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        --program counter of next instruction ie pc+4
        pc_next : OUT INTEGER RANGE 0 TO RAM_SIZE - 1
    );
END IF_stage;

ARCHITECTURE behavior OF IF_stage IS
    COMPONENT instruction_memory IS
        PORT (
            i_address : IN INTEGER RANGE 0 TO RAM_SIZE - 1;
            o_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL instruction_data_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');--TODO initialize to stall
    SIGNAL program_counter : INTEGER RANGE 0 TO RAM_SIZE - 1 := 0;
    SIGNAL pc_next_buffer : INTEGER RANGE 0 TO RAM_SIZE - 1 := 0;
BEGIN
    pm_IM : instruction_memory
    PORT MAP(
        --to simplify synchronization of instruction memory, o_waitrequest and i_imread are removed
        --data is instantaneously read from memory, as allowed from the project instructions:
        --"You may alter the memory model as you see fit (e.g., set the memory delay to 1 clock cycle, if it makes your life easier)."
        i_address => program_counter,
        o_readdata => instruction_data_buffer
    );

    IF_logic_process : PROCESS (clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            CASE valid_jump_target IS
                WHEN '1' =>
                    --jump when valid
                    program_counter <= jump_target;
                WHEN OTHERS =>
                    --increment normaly otherwise if no stall
                    IF (if_stall = '1') THEN
                        program_counter <= program_counter;
                    ELSE
                        program_counter <= program_counter + 4;

                    END IF;
            END CASE;

            -- TODO logic for the IF stage. Write the values for the next stage on the buffer signals
            -- Because signal values are only updated at the end of the process, those values will be available to ID on the next clock cycle only
        END IF;
    END PROCESS;

    pc_next <= program_counter + 4;
    instruction_data <= instruction_data_buffer;

END;