--to simplify synchronization of instruction memory, o_waitrequest only suggests the data return is valid
--data is instantaneously read from memory, as allowed from the project instructions:
--"You may alter the memory model as you see fit (e.g., set the memory delay to 1 clock cycle, if it makes your life easier)."
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity instruction_memory is
    generic (
        RAM_SIZE : integer := 32768;
        INSTRUCTIONS_FILE_NAME : string := "program.txt"
    );
    port (
        i_address : in integer range 0 to RAM_SIZE - 1;
        o_readdata : out std_logic_vector (31 downto 0)
    );
end instruction_memory;

architecture arch of instruction_memory is
    type memory is array(RAM_SIZE - 1 downto 0) of std_logic_vector(7 downto 0);
    signal instructions_ram_block : memory := (others => (others => '0'));
begin
    --process reads from file the instructions once at the start of the execution
    populate_instructions_process : process
        file instructions_file : text open read_mode is INSTRUCTIONS_FILE_NAME;
        variable line_value : line;
        variable line_vector : std_logic_vector (31 downto 0);
        variable line_count : integer range 0 to RAM_SIZE/4 - 1 := 0;
    begin
        --open file
        file_open(instructions_file, INSTRUCTIONS_FILE_NAME, read_mode);
        --until reach end of file
        while not endfile(instructions_file) loop
            --read line from file
            readline(instructions_file, line_value);
            --convert line to std_logic_vector
            read(line_value, line_vector);
            --each mem cell is 8bits since byte addressability
            --write 4 x 8bits to each memory cell in big endian
            instructions_ram_block(4 * line_count) <= line_vector(31 downto 24);
            instructions_ram_block(4 * line_count + 1) <= line_vector(23 downto 16);
            instructions_ram_block(4 * line_count + 2) <= line_vector(15 downto 8);
            instructions_ram_block(4 * line_count + 3) <= line_vector(7 downto 0);
            --go to next line
            line_count := line_count + 1;
        end loop;
        --wait infinitely
        wait;
    end process;

    --build 32bit read data by concatenating 4 1-byte cells from memory
    o_readdata <= instructions_ram_block(i_address) & instructions_ram_block(i_address + 1) & instructions_ram_block(i_address + 2) & instructions_ram_block(i_address + 3);

end arch;