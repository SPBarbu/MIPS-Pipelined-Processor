library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--TAKEN FROM GIVEN CODE FOR MEMORY of CACHE, added file io for mem
USE STD.textio.all;
USE ieee.std_logic_textio.all;

entity MEM_stage is
    GENERIC(
		ram_size : INTEGER := 8192; -- 8192 lines of 32 bit words
		mem_delay : time := 0.5 ns;
		clock_period : time := 1 ns
	);
    port (
        clock : in std_logic;
        --instruction to execute currently
        current_instruction : in std_logic_vector(5 downto 0);
        --address for memory or data to be written back to register
        immediate_data_mem_in : in std_logic_vector(31 downto 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : out std_logic_vector(5 downto 0);
        --data to be written back to register
        immediate_data_mem_out : out std_logic_vector(31 downto 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : out std_logic_vector (4 downto 0);

        --memory inputs and outputs
        writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		--for writing back to txt file
		memwritetotext: IN STD_LOGIC
    );
end MEM_stage;

architecture behavior of MEM_stage is

    signal instruction_next_stage_buffer : std_logic_vector(5 downto 0) := (others => '0');--TODO initialize to stall
    signal immediate_data_mem_out_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
    signal register_reference_next_stage_buffer : std_logic_vector (4 downto 0) := (others => '0');--TODO initialize to stall

    --signals for memory
    TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ram_block: MEM;
	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	--for write back to file
	file text_file : text open write_mode is "memory.txt";

begin

    MEM_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            --propagate unchanged values to next stage
            instruction_next_stage_buffer <= current_instruction;
            register_reference_next_stage_buffer <= register_reference_current;
            -- TODO logic for the MEM stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to WB on the next clock cycle only
        end if;
    end process;

    --This is the main section of the SRAM model
	mem_process: PROCESS (clock)
	BEGIN
		--This is a cheap trick to initialize the SRAM in simulation
		IF(now < 1 ps)THEN
			For i in 0 to ram_size-1 LOOP
				ram_block(i) <= std_logic_vector(to_unsigned(i,32));
			END LOOP;
		end if;

		--This is the actual synthesizable SRAM block
		IF (clock'event AND clock = '1') THEN
            --only SW writes to the memory
			IF (current_instruction = "101011") THEN
				ram_block(address) <= writedata;
			END IF;
		read_address_reg <= address;
		END IF;
	END PROCESS;
	readdata <= ram_block(read_address_reg);

	--process for writing back to text file
    writetotext_process: PROCESS (memwritetotext)
    variable row : line;
	begin
        if (memwritetotext = '1') then
			--iterate for every ram block 
			for I in 0 to 8191 loop
				--write the contents of the row at I to the line variable
				write(row, ram_block(I));
				--write the line to the text file
				writeline(text_file, row);
			end loop;
        end if;
    end process;

    instruction_next_stage <= instruction_next_stage_buffer;
    immediate_data_mem_out <= immediate_data_mem_out_buffer;
    register_reference_next_stage <= register_reference_next_stage_buffer;

end;