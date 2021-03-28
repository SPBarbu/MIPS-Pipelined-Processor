--Simple 2 to 1 mux
library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;


entity if_mux is
port(
    mux_input0 : in std_logic_vector(31 downto 0);
    mux_input1 : in std_logic_vector(31 downto 0);
    mux_select : in std_logic;
    mux_output : out std_logic_vector(31 downto 0)
);
end if_mux;

architecture arch of if_mux is
begin
    -- if select is 0, input 0 is selected, else input1 is selected
    if mux_select = '0' then
        mux_output <= input0;
    else
        mux_output <= input1;
    end if;
end arch;