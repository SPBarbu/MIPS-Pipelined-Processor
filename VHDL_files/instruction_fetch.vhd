library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;


entity instruction_fetch is 
port(
    clk : in std_logic;
    if_mux_input1 : in std_logic_vector(31 downto 0);
    if_mux_select : in std_logic := '0';
    instruction_memory_output: out std_logic_vector(31 downto 0);
    if_add_output: out std_logic_vector(31 downto 0) --adder output
);
end instruction_fetch;

architecture arch of instruction_fetch is
--DECLARING COMPONENTS

--adder
component add is
port(
    add_input0 : in std_logic_vector(31 downto 0);
    add_input1 : in std_logic_vector(31 downto 0);
    add_output : out std_logic_vector(31 downto 0)
);
end component;

--2 to 1 multiplexer
component if_mux is
port(
    input0 : in std_logic_vector(31 downto 0);
    input1 : in std_logic_vector(31 downto 0);
    select : in std_logic;
    output : out std_logic_vector(31 downto 0)
);
end component;

--program counter
component if_pc is
port(
    clk : in std_logic;
    reset : in std_logic;
    input : in std_logic_vector(31 downto 0);
    output : out std_logic_vector(31 downto 0) := (others => '0')
);
end component;

--instruction memory
component instruction_memory is
port(
    i_clock : in std_logic;
    i_address : in integer range 0 to RAM_SIZE - 1;
    i_memread : in std_logic;
    o_readdata : out std_logic_vector (31 downto 0);
    o_waitrequest : out std_logic
);
end component;


--Declaring signals for port mapping that have not been declared in the entity
--adder signals
signal if_add_input0 : std_logic_vector(to_unsigned(4, 32)); --integer 4 for adder


--2 to 1 mux signals
signal if_mux_input0 : std_logic_vector(31 downto 0);
signal if_mux_output : std_logic_vector(31 downto 0);

--program counter signals
signal if_pc_reset : std_logic := '0';
signal if_pc_input : std_logic_vector(31 downto 0);
signal if_pc_output : std_logic_vector(31 downto 0);


begin

    adder : add
    port map(
        add_input0 => if_add_input0,
        add_input1 => if_pc_output,
        add_output => if_add_output
    );

    multiplexer : if_mux
    port map(
        input0 => if_add_output,
        input1 => if_mux_input1,
        select => if_mux_select,
        output => if_pc_input
    );

    program_counter : if_pc
    port map(
        clk => clk,
        reset => if_pc_reset,
        input => if_pc_input,
        output => if_pc_output
    );

end arch;