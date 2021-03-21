--Simple adder
library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
port(
    add_input0 : in std_logic_vector(31 downto 0);
    add_input1 : in std_logic_vector(31 downto 0);
    add_output : out std_logic_vector(31 downto 0)
);
end adder;

architecture arch of adder is
begin
    --adding two inputs together and outputting
    add_output <= std_logic_vector(unsigned(add_input0) + unsigned(add_input1));
end arch;