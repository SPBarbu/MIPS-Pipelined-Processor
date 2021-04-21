--to simplify synchronization of instruction memory, o_waitrequest only suggests the data return is valid
--data is instantaneously read from memory, as allowed from the project instructions:
--"You may alter the memory model as you see fit (e.g., set the memory delay to 1 clock cycle, if it makes your life easier)."
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY instruction_memory IS
    GENERIC (
        RAM_SIZE : INTEGER := 32768;
        INSTRUCTIONS_FILE_NAME : STRING := "program.txt"
    );
    PORT (
        i_address : IN INTEGER RANGE 0 TO RAM_SIZE - 1;
        o_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
    );
END instruction_memory;

ARCHITECTURE arch OF instruction_memory IS
    TYPE memory IS ARRAY(RAM_SIZE - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL instructions_ram_block : memory := (OTHERS => (OTHERS => '0'));
BEGIN
    --process reads from file the instructions once at the start of the execution
    populate_instructions_process : PROCESS
        FILE instructions_file : text OPEN read_mode IS INSTRUCTIONS_FILE_NAME;
        VARIABLE line_value : line;
        VARIABLE line_vector : STD_LOGIC_VECTOR (31 DOWNTO 0);
        VARIABLE line_count : INTEGER RANGE 0 TO RAM_SIZE/4 - 1 := 0;
    BEGIN
        --until reach end of file
        WHILE NOT endfile(instructions_file) LOOP
            --read line from file
            readline(instructions_file, line_value);
            --convert line to std_logic_vector
            read(line_value, line_vector);
            --each mem cell is 8bits since byte addressability
            --write 4 x 8bits to each memory cell in big endian
            instructions_ram_block(4 * line_count) <= line_vector(31 DOWNTO 24);
            instructions_ram_block(4 * line_count + 1) <= line_vector(23 DOWNTO 16);
            instructions_ram_block(4 * line_count + 2) <= line_vector(15 DOWNTO 8);
            instructions_ram_block(4 * line_count + 3) <= line_vector(7 DOWNTO 0);
            --go to next line
            line_count := line_count + 1;
        END LOOP;
        file_close(instructions_file);
        --wait infinitely
        WAIT;
    END PROCESS;

    --build 32bit read data by concatenating 4 1-byte cells from memory
    o_readdata <= instructions_ram_block(i_address) & instructions_ram_block(i_address + 1) & instructions_ram_block(i_address + 2) & instructions_ram_block(i_address + 3);

END arch;