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
begin

end;