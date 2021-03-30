library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ID_stage is
    port (
        clock : in std_logic;
        --raw instruction data to decode
        instruction_data : in std_logic_vector(31 downto 0);
        --data to be written to register
        immediate_data_wb : in std_logic_vector(31 downto 0);
        --register reference to write to
        register_reference_wb : in std_logic_vector (4 downto 0);
        --indicate that register value should be overwritten
        write_register : in std_logic;
        ------------------------------------------------------------------------------
        --opcode of the instruction
        instruction_decoded : out std_logic_vector(5 downto 0);
        --data for alu operations, or address for memory
        immediate_data_1 : out std_logic_vector(31 downto 0);
        immediate_data_2 : out std_logic_vector(31 downto 0);
        --register reference for writeback
        register_reference : out std_logic_vector (4 downto 0)
    );
end ID_stage;

architecture behavior of ID_stage is
    --buffer signals to be written to at the end of the stage for the next stage
    signal instruction_decoded_buffer : std_logic_vector(5 downto 0) := (others => '0'); --TODO initialize to stall
    signal immediate_data_1_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal immediate_data_2_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal register_reference_buffer : std_logic_vector (4 downto 0) := (others => '0'); --TODO initialize to stall
begin
    ID_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            --propagate opcode to next stage
            instruction_decoded_buffer <= instruction_data(31 downto 26);
            -- TODO logic for the ID stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to EX on the next clock cycle only
        end if;
    end process;

    instruction_decoded <= instruction_decoded_buffer;
    immediate_data_1 <= immediate_data_1_buffer;
    immediate_data_2 <= immediate_data_2_buffer;
    register_reference <= register_reference_buffer;

end;