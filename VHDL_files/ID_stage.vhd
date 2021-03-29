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
    signal opcode_buffer : std_logic_vector(5 downto 0) := "000000"; --should be initialized to stall
begin
    instruction_decoded <= opcode_buffer;

    test_propagate_opcode : process (clock)
    begin
        if (rising_edge(clock)) then
            opcode_buffer <= instruction_data(31 downto 26);
            report "ID instruction: " & integer'image(to_integer(unsigned(opcode_buffer)));
        end if;
    end process;
end;