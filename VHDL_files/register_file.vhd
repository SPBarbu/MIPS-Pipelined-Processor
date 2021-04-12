library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity register_file is
    generic(
        REG_NUM : integer := 32;
    );
    port(
        read_register_1 : in std_logic_vector(4 downto 0); --register rs from instruction
        read_register_2 : in std_logic_vector(4 downto 0); --register rt from instruction
        write_bit : in std_logic; --if 1 there is data to write, if 0 no data to write
        write_register : in std_logic_vector(4 downto 0); --register rd from instruction
        write_data : in std_logic_vector(31 downto 0); --contents to write back to register rd
        --instruction_type : in std_logic; --bit to determine if register or immediate instruction, 0 for r, 1 for I
        --should there be a reset bit to zero out the register.txt
        read_data_1 : out std_logic_vector(31 downto 0); --contents from register rs
        read_data_2 : out std_logic_vector(31 downto 0); --contents from register rt
        --for writing back to file
        regwritetotext : in std_logic
    );
end register_file;

--scenarios:
--register instruction, both read registers are needed, the write register is also needed
--immediate instruction, both read registers are needed, no write register
--jump instruction, needs no registers

--immediate and jump addresses should be handled in instruction_decode.vhd 
--jump should never need to touch register_file.vhd

--!!!!not sure if using processes correctly!!!!
--!!!!unsure how to handle writing back!!!!
--!!!should there be a means of zeroing all the registers!!!

--right now this only attempts to implement reading
--but maybe status bit for writing? also how will the timing of writing work

architecture arch of register_file is
  --similar implementation to memory in cache project
  type reg_file is array (REG_NUM-1 downto 0) of std_logic_vector(31 downto 0);
  signal reg_block : reg_file;

	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	--for write back to file
	file text_file : text open write_mode is "registers.txt";

begin

  --main process for register file depends on clock
  process(clock)
  begin
    if (rising_edge(clock)) then
      --if doing write operation, write to the corresponding reg_block
      if (write_bit = '1') then
        reg_block(to_integer(unsigned(write_register))) <= write_data;
      end if;
      --read data from rs and rt, convert rs and rt to int for access to reg_block
      read_data_1 <= reg_block(to_integer(unsigned(read_register_1)));
      read_data_2 <= reg_block(to_integer(unsigned(read_register_2)));
    end if;
  end process;


    -- --get read registers regardless of register type, if the register type is r, also get the write register
    -- retrieve_read_registers : process
    --     file register_content : text open read_mode is REGISTERS;
    --     variable line_value : line;
    --     variable line_vector : std_logic_vector (31 downto 0);
    --     variable line_count : integer range 0 to REG_NUM-1;
    --     variable iterator : integer := 0;

        

    -- begin
      
    --   --file_open(register_content, REGISTERS, read_mode);
    --   iterator := 0;
      
    --   --find register for read register 1
    --   while (iterator <= to_integer(unsigned(read_register_1))) loop
    --     readline(register_content, line_value);
    --     read(line_value, line_vector);
    --     if (iterator = to_integer(unsigned(read_register_1))) then
    --       read_data_1 <= line_vector(31 downto 0);
    --     end if;
    --     iterator := iterator + 1;
    --   end loop;
      
    --   iterator := 0;
      
    --   --find register for read register 2
    --   while (iterator <= to_integer(unsigned(read_register_2))) loop
    --     readline(register_content, line_value);
    --     read(line_value, line_vector);
    --     if (iterator = to_integer(unsigned(read_register_2))) then
    --       read_data_2 <= line_vector(31 downto 0);
    --     end if;
    --     iterator := iterator + 1;
    --   end loop;
      
    --   wait; --not sure about this, did this to get rid of a compiler warning since no sensitivity list for process
      
    --   if (write_bit = '1') then
    --     iterator := 0;
        
    --     while (iterator <= to_integer(unsigned(write_register))) loop
    --       if (iterator = to_integer(unsigned(write_register))) then
    --         write(line_value, write_data);
    --         writeline(register_content, line_value);
    --       end if;
    --       iterator := iterator + 1;
    --     end loop;
    --   end if;
      
    -- end process;

    --writing back
    --need the register from some previous instruction to know where to write as well as the data to write
    --if the process for reading works, iterate until you find the correct line and use write function
    process(regwritetotext)
    variable row : line;
    begin
      if (regwritetotext = '1') then
      --iterate for every reg  
      for I in 0 to 31 loop
        --write the contents of the row at I to the line variable
        write(row, reg_block(I));
        --write the line to the text file
        writeline(text_file, row);
      end loop;
        end if;
    end process;


    


end arch;