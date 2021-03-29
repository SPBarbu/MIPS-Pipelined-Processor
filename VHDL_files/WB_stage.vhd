library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WB_stage is
    port (
        clock : in std_logic;
        --instruction to execute currently
        current_instruction : in std_logic_vector(5 downto 0);
        --data to be written back to register
        immediate_data_mem_in : in std_logic_vector(31 downto 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        ------------------------------------------------------------------------------
        --data to be written back to register
        immediate_data_wb : out std_logic_vector(31 downto 0);
        --register reference of current instruction to writeback
        register_reference_wb : out std_logic_vector (4 downto 0);
        --indicate that register value should be overwritten
        write_register : out std_logic
    );
end WB_stage;

architecture behavior of WB_stage is
begin
    test_propagate_opcode : process (clock)
    begin
        if (rising_edge(clock)) then
            report "WB instruction: " & integer'image(to_integer(unsigned(current_instruction)));
        end if;
    end process;
end;