library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IF_stage is
    port (
        clock : in std_logic;
        ------------------------------------------------------------------------------
        --raw instruction data to decode
        instruction_data : out std_logic_vector(31 downto 0)
    );
end IF_stage;

architecture behavior of IF_stage is
    signal instruction_data_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
begin
    IF_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            -- TODO logic for the IF stage. Write the values for the next stage on the buffer signals
            -- Because signal values are only updated at the end of the process, those values will be available to ID on the next clock cycle only
        end if;
    end process;

    instruction_data <= instruction_data_buffer;

end;