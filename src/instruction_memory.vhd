library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity instruction_memory is
    generic (
        RAM_SIZE : integer := 32768;
        MEM_DELAY : time := 1 ns;
        CLOCK_PERIOD : time := 1 ns;
        INSTRUCTIONS_FILE_NAME : string := "program.txt"
    );
    port (
        i_clock : in std_logic;
        i_address : in integer range 0 to RAM_SIZE - 1;
        i_memread : in std_logic;
        o_readdata : out std_logic_vector (31 downto 0);
        o_waitrequest : out std_logic
    );
end instruction_memory;

architecture arch of instruction_memory is
    type memory is array(RAM_SIZE - 1 downto 0) of std_logic_vector(7 downto 0);
    signal instructions_ram_block : memory;
    signal read_waitreq_reg : std_logic;
begin
    populate_instructions_process : process
        file instructions_file : text open read_mode is INSTRUCTIONS_FILE_NAME;
        variable line_value : line;
        variable line_vector : std_logic_vector (31 downto 0);
        variable line_count : integer range 0 to RAM_SIZE/4 - 1 := 0;
    begin
        file_open(instructions_file, INSTRUCTIONS_FILE_NAME, read_mode);
        while not endfile(instructions_file) loop
            readline(instructions_file, line_value);
            read(line_value, line_vector);
            instructions_ram_block(4 * line_count) <= line_vector(31 downto 24);
            instructions_ram_block(4 * line_count + 1) <= line_vector(23 downto 16);
            instructions_ram_block(4 * line_count + 2) <= line_vector(15 downto 8);
            instructions_ram_block(4 * line_count + 3) <= line_vector(7 downto 0);
            line_count := line_count + 1;
        end loop;
        wait;
    end process;

end arch;