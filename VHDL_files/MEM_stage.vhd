library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEM_stage is
    port (
        clock : in std_logic;
        --instruction to execute currently
        current_instruction : in std_logic_vector(5 downto 0);
        --address for memory or data to be written back to register
        immediate_data_mem_in : in std_logic_vector(31 downto 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : out std_logic_vector(5 downto 0);
        --data to be written back to register
        immediate_data_mem_out : out std_logic_vector(31 downto 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : out std_logic_vector (4 downto 0)
    );
end MEM_stage;

architecture behavior of MEM_stage is
    signal opcode_buffer : std_logic_vector(5 downto 0) := "000000"; --should be initialized to stall
begin
    instruction_next_stage <= opcode_buffer;

    test_propagate_opcode : process (clock)
    begin
        if (rising_edge(clock)) then
            opcode_buffer <= current_instruction;
            report "MEM instruction: " & integer'image(to_integer(unsigned(opcode_buffer)));
        end if;
    end process;
end;