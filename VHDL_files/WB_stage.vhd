LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY WB_stage IS
    PORT (
        clock : IN STD_LOGIC;
        --instruction to execute currently
        current_instruction : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        --data to be written back to register, built in mux, no need for mux component
        immediate_data_mem_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        ------------------------------------------------------------------------------
        --data to be written back to register
        immediate_data_wb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        --register reference of current instruction to writeback
        register_reference_wb : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
        --indicate that register value should be overwritten
        write_register : OUT STD_LOGIC
    );
END WB_stage;

ARCHITECTURE behavior OF WB_stage IS
    SIGNAL immediate_data_wb_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');--TODO initialize to stall
    SIGNAL register_reference_wb_buffer : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');--TODO initialize to stall
    SIGNAL write_register_buffer : STD_LOGIC := '0';--TODO initialize to stall
BEGIN
    WB_logic_process : PROCESS (clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            register_reference_wb_buffer <= register_reference_current;
            immediate_data_wb_buffer <= immediate_data_mem_in;
            -- TODO logic for the WB stage. Write the values for the next stage on the buffer signals.
            --instructions that needs to write to register, toggle write_register to 1
            --without mult and div since they dont return anything
            IF ((current_instruction = "100000") OR (current_instruction = "100010") OR (current_instruction = "001000") OR (current_instruction = "101010") OR
                (current_instruction = "001010") OR (current_instruction = "100100") OR (current_instruction = "100101") OR (current_instruction = "100111") OR (current_instruction = "101000") OR (current_instruction = "001100") OR
                (current_instruction = "001101") OR (current_instruction = "001110") OR (current_instruction = "010000") OR (current_instruction = "010010") OR (current_instruction = "001111") OR (current_instruction = "000000") OR
                (current_instruction = "000010") OR (current_instruction = "000011")) AND register_reference_current /= "00000"
                THEN
                write_register_buffer <= '1';
            ELSE
                write_register_buffer <= '0';
            END IF;
        END IF;
    END PROCESS;

    immediate_data_wb <= immediate_data_wb_buffer;
    register_reference_wb <= register_reference_wb_buffer;
    write_register <= write_register_buffer;

END;