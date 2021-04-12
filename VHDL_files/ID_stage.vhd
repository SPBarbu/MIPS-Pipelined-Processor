library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ID_stage is
    generic(
        REG_NUM : integer := 32;
        RAM_SIZE : integer := 32768
    );
    port (
        clock : in std_logic;
        --raw instruction data to decode
        instruction_data : in std_logic_vector(31 downto 0);
        --data to be written to register
        immediate_data_wb : in std_logic_vector(31 downto 0);
        --register reference to write to
        register_reference_wb : in std_logic_vector (4 downto 0);
        --bit for when register should be written 
        write_register : in std_logic;
        --program counter of next instruction ie pc+4
        pc_next : in integer range 0 to RAM_SIZE - 1;
        ------------------------------------------------------------------------------
        --opcode of the instruction in case of immediate or jump, funct of instruction in case of register
        instruction_decoded : out std_logic_vector(5 downto 0);
        --data for alu operations, or address for memory
        immediate_data_1 : out std_logic_vector(31 downto 0);
        immediate_data_2 : out std_logic_vector(31 downto 0);
        --register reference for writeback
        register_reference : out std_logic_vector (4 downto 0);
        --jump target for branch or jump 
        jump_target : out integer range 0 to RAM_SIZE - 1;
        --specifies if the jump target is valid
        valid_jump_targer : out std_logic;

        --for writing back to file for registers
        regwritetotext : in std_logic
        --for pc of next instruction to ex stage
        pc_next_ex : out integer range 0 to RAM_SIZE -1;
    );
end ID_stage;

--we set all instructions to an internal code in the instruction_decoded signal
--add  = 000001
--sub  = 000010
--addi = 000011
--mult = 000100
--div  = 000101
--slt  = 000110
--slti = 000111
--and  = 001000
--or   = 001001
--nor  = 001010
--xor  = 001011
--andi = 001100
--ori  = 001101
--xori = 001110
--mfhi = 001111
--mflo = 010000
--lui  = 010001
--sll  = 010010
--srl  = 010011
--sra  = 010100
--lw   = 010101
--sw   = 010110
--beq  = 010111
--bne  = 011000
--j    = 011001
--jr   = 011010
--jal  = 011011

architecture behavior of ID_stage is
  
    
    --buffer signals to be written to at the end of the stage for the next stage
    signal instruction_decoded_buffer : std_logic_vector(5 downto 0) := (others => '0'); --TODO initialize to stall
	  signal internal_code_buffer : std_logic_vector(5 downto 0) := (others => '0');
    signal immediate_data_1_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal immediate_data_2_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal register_reference_buffer : std_logic_vector (4 downto 0) := (others => '0'); --TODO initialize to stall
    signal jump_target_buffer : integer range 0 to RAM_SIZE - 1 := 0;
    signal valid_jump_targer_buffer : std_logic := '0';

    --signals for registers
    --similar implementation to memory in cache project
    type reg_file is array (REG_NUM-1 downto 0) of std_logic_vector(31 downto 0);
    signal reg_block : reg_file;

	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	--for write back to file
	file text_file : text open write_mode is "registers.txt";

begin
    ID_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            --propagate opcode to next stage
            --internal_code_buffer <= instruction_data(31 downto 26);
            -- TODO logic for the ID stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to EX on the next clock cycle only

            --default instruction add $r0, $r0, $r0 to stall
            instruction_decoded_buffer <= "100000"; --funct field of the add instruction
			      internal_code_buffer <= "000001";
            immediate_data_1_buffer <= (others => '0');
            immediate_data_2_buffer <= (others => '0');
            register_reference_buffer <= "00000";
            
            --write to reg if needed before reading
            if (write_register = '1') then
                reg_block(to_integer(unsigned(register_reference_wb))) <= immediate_data_wb;
            end if;

			--register type instruction 
            if instruction_data(31 downto 26) = "000000" then 
			
				instruction_decoded_buffer <= instruction_data(5 downto 0);

                if instruction_data(5 downto 0) = "100000" then --add instruction
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                    
					if instruction_data(15 downto 11) /= "00000" then --destination register cant be r0
						register_reference_buffer <= instruction_data(15 downto 11);
					end if;

                elsif instruction_data(5 downto 0) = "100010" then  --sub
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "011000" then --mult
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));

                elsif instruction_data(5 downto 0) = "011010" then --div
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));

                elsif instruction_data(5 downto 0) = "101010" then  --slt
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "100100" then  --and
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "100101" then  --or
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "100111" then  --nor
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "101000" then  --xor
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "010000" then  --mfhi
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "010010" then  --mflo
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "000000" then  --sll
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "000010" then  --srl
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "000011" then  --sra
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
					if instruction_data(15 downto 11) /= "00000" then
						register_reference_buffer <= instruction_data(15 downto 11); 
					end if;

                elsif instruction_data(5 downto 0) = "001000" then  --jr
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
					
                end if;
            
			--immediate type instruction excluding jumps
            elsif ((instruction_data(31 downto 26) /= "000000") or 
                   (instruction_data(31 downto 26) /= "000010") or 
                   (instruction_data(31 downto 26) /= "000011")) then

				instruction_decoded_buffer <= instruction_data(31 downto 26);


                if instruction_data(31 downto 26) = "001000" then --addi instruction
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    if instruction_data(15) = "0" then --if msb is 0, sign extend 0
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                    elsif instruction_data(15) = "1" then --if msb is 1, sign extend 1
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                    end if;
					if instruction_data(20 downto 16) /= "00000" then 
						register_reference_buffer <= instruction_data(20 downto 16); 
					end if;

                elsif instruction_data(31 downto 26) = "001010" then  --slti
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    if instruction_data(15) = "0" then 
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                    elsif instruction_data(15) = "1" then 
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                    end if;
					if instruction_data(20 downto 16) /= "00000" then 
						register_reference_buffer <= instruction_data(20 downto 16); 
					end if;

                elsif instruction_data(31 downto 26) = "001100" then --andi
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
					if instruction_data(20 downto 16) /= "00000" then 
						register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16); 
					end if;

                elsif instruction_data(31 downto 26) = "011010" then --ori
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                    if instruction_data(20 downto 16) /= "00000" then 
                        register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16); 
                    end if;

                elsif instruction_data(31 downto 26) = "101010" then  --xori
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
					if instruction_data(20 downto 16) /= "00000" then 
						register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16); 
					end if;

                elsif instruction_data(31 downto 26) = "001111" then  --lui
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
					if instruction_data(20 downto 16) /= "00000" then 
						register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16); 
					end if;

                elsif instruction_data(31 downto 26) = "100011" then  --lw
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    if instruction_data(15) = "0" then 
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                    elsif instruction_data(15) = "1" then
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                    end if;

                elsif instruction_data(31 downto 26) = "101011" then  --sw
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    if instruction_data(15) = "0" then 
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                    elsif instruction_data(15) = "1" then 
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                    end if;

				--need to make a comparison between contents of rs and rt, if equal offset by immediate value
				--make the comparison here? and then send 1 to take the offset if rs = rt and 0 to not?
				--similar idea for bne but for rs =/= rt
                elsif instruction_data(31 downto 26) = "000100" then  --beq
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    if instruction_data(15) = "0" then 
                        immediate_data_2_buffer <= "00000000000000" & instruction_data(15 downto 0) & "00";
                    elsif instruction_data(15) = "1" then 
                        immediate_data_2_buffer <= "11111111111111" & instruction_data(15 downto 0) & "00";
                    end if;

                elsif instruction_data(31 downto 26) = "000101" then  --bne
                    immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                    if instruction_data(15) = "0" then 
                        immediate_data_2_buffer <= "00000000000000" & instruction_data(15 downto 0) & "00";
                    elsif instruction_data(15) = "1" then 
                        immediate_data_2_buffer <= "11111111111111" & instruction_data(15 downto 0) & "00";
                    end if;
                end if;
            
            elsif (instruction_data(31 downto 26) = "000010") then --j unconditional jump
                immediate_data_1_buffer (25 downto 0) <= instruction_data(25 downto 0);
				        instruction_decoded_buffer <= "000010";
            
            elsif (instruction_data(31 downto 26) = "000011") then --jal
                immediate_data_1_buffer (25 downto 0) <= instruction_data(25 downto 0);
				        instruction_decoded_buffer <= "000011";
                
            end if;    
        end if;
    end process;
    
     --writing back to file
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
 

    instruction_decoded <= instruction_decoded_buffer;
	internal_code <= internal_code_buffer;
    register_reference <= register_reference_buffer;
    immediate_data_1 <= immediate_data_1_buffer;
    immediate_data_2 <= immediate_data_2_buffer;
    pc_next_ex <= pc_next;

end;