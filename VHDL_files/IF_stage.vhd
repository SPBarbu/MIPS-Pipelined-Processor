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
    signal count : integer range 0 to 63 := 0;
begin
    --set the upcode with the random data
    instruction_data <= std_logic_vector(to_unsigned(count, 6)) & "00000000000000000000000000";
    --populate the pipeline with random data until connecting with instruction memory
    random_populate_instructions : process (clock)
    begin
        if (rising_edge(clock)) then
            report "IF instruction: " & integer'image(count);
            if count = 63 then
                count <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;
end;