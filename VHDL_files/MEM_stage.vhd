LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
--added file io for write to memory.txt
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY MEM_stage IS
    GENERIC (
        ram_size : INTEGER := 8192; -- 8192 lines of 32 bit words
        mem_delay : TIME := 0.5 ns;
        clock_period : TIME := 1 ns
    );
    PORT (
        clock : IN STD_LOGIC;
        --instruction to execute currently
        current_instruction : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        --address for memory or data to be written back to register
        immediate_data_mem_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        --for store value
        immediate_data_mem_in_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        --data to be written back to register
        immediate_data_mem_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
        --for writing back to txt file
        memwritetotext : IN STD_LOGIC
    );
END MEM_stage;

ARCHITECTURE behavior OF MEM_stage IS

    SIGNAL instruction_next_stage_buffer : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');-- initialize to stall
    SIGNAL immediate_data_mem_out_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');-- initialize to stall
    SIGNAL register_reference_next_stage_buffer : STD_LOGIC_VECTOR (4 DOWNTO 0) := (OTHERS => '0');-- initialize to stall

    --variables for memory
    TYPE MEM IS ARRAY(ram_size - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    --This is the main section of the SRAM model
    mem_process : PROCESS (clock)
        VARIABLE row : line;
        VARIABLE ram_block : MEM := (OTHERS => (OTHERS => '0')); --all ram initialized to 0
        --for write back to file
        FILE text_file : text OPEN write_mode IS "memory.txt";
    BEGIN
        --This is the actual synthesizable SRAM block
        IF (rising_edge(clock)) THEN
            --if we need to write back to memory/txt
            IF (memwritetotext = '1') THEN
                --iterate for every ram block 
                FOR I IN 0 TO 8191 LOOP
                    --write the contents of the row at I to the line variable
                    write(row, ram_block(I));
                    --write the line to the text file
                    writeline(text_file, row);
                END LOOP;
                file_close(text_file);
            END IF;
            --propagate unchanged values to next stage
            instruction_next_stage_buffer <= current_instruction;
            register_reference_next_stage_buffer <= register_reference_current;
            --if not mem operation, just pass alu output
            IF (current_instruction = "100000") OR (current_instruction = "100010") OR (current_instruction = "001000") OR (current_instruction = "011000") OR (current_instruction = "011010") OR (current_instruction = "101010") OR
                (current_instruction = "001010") OR (current_instruction = "100100") OR (current_instruction = "100101") OR (current_instruction = "100111") OR (current_instruction = "101000") OR (current_instruction = "001100") OR
                (current_instruction = "001101") OR (current_instruction = "001110") OR (current_instruction = "010000") OR (current_instruction = "010010") OR (current_instruction = "001111") OR (current_instruction = "000000") OR
                (current_instruction = "000010") OR (current_instruction = "000011")
                THEN
                immediate_data_mem_out_buffer <= immediate_data_mem_in;
                --sw, mem operation
            ELSIF (current_instruction = "101011") THEN
                ram_block(to_integer(unsigned(immediate_data_mem_in))) := immediate_data_mem_in_2;
                --lw, mem operation
            ELSIF (current_instruction = "100011") THEN
                immediate_data_mem_out_buffer <= ram_block(to_integer(unsigned(immediate_data_mem_in)));
            ELSE
                --set output to 32 X
                immediate_data_mem_out_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            END IF;
        END IF;
    END PROCESS;

    instruction_next_stage <= instruction_next_stage_buffer;
    immediate_data_mem_out <= immediate_data_mem_out_buffer;
    register_reference_next_stage <= register_reference_next_stage_buffer;

END;