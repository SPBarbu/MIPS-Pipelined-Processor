--program counter
library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_pc is
    port(
        clk : in std_logic;
        reset : in std_logic;
        input : in std_logic_vector(31 downto 0);
        output : out std_logic_vector(31 downto 0) := (others => '0')
    );
end if_pc;


architecture arch of pc is

process (clk, reset)
begin
    if rising_edge(clk) then
        if reset = '1' then
            output <= (others => '0');
        else
            output <= input;
        end if;
    end if;

end arch;
