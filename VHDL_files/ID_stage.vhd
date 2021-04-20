library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity ID_stage is
    generic (
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
        -- --for writing back to file for registers
        regwritetotext : in std_logic;
        --for stalling
        id_stall : in std_logic;
        ------------------------------------------------------------------------------
        --opcode of the instruction in case of immediate or jump, funct of instruction in case of register
        instruction_decoded : out std_logic_vector(5 downto 0);
        --data for alu operations, or address for memory
        immediate_data_1 : out std_logic_vector(31 downto 0);
        immediate_data_2 : out std_logic_vector(31 downto 0);
        --data for store in memory
        immediate_data_3 : out std_logic_vector(31 downto 0);
        --register reference for writeback
        register_reference : out std_logic_vector (4 downto 0);
        --jump target for branch or jump 
        jump_target : out integer range 0 to RAM_SIZE - 1;
        --specifies if the jump target is valid
        valid_jump_target : out std_logic
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
--or   = 100101
--nor  = 001010
--xor  = 100110
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
    signal immediate_data_1_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal immediate_data_2_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal immediate_data_3_buffer : std_logic_vector(31 downto 0) := (others => '0');
    signal register_reference_buffer : std_logic_vector (4 downto 0) := (others => '0'); --TODO initialize to stall
    signal jump_target_buffer : integer range 0 to RAM_SIZE - 1 := 0;
    signal valid_jump_target_buffer : std_logic := '0';

    --signals for registers
    --similar implementation to memory in cache project
    type Reg_Block_Type is array (0 to 31) of std_logic_vector(31 downto 0);

    --for write back to file
    file text_file : text open write_mode is "registers.txt";

begin
    ID_logic_process : process (clock)
        variable ignore_next_instruction : std_logic := '0';
        variable temp : std_logic_vector(31 downto 0);
        variable reg_block : Reg_Block_Type := (others => (others => '0')); --all registers initialized to 0
        variable row : line;
        --for write back to file
        file text_file : text open write_mode is "registers.txt";
    begin
        if (rising_edge(clock)) then
            if (regwritetotext = '1') then
                --iterate for every reg  
                for I in 0 to 31 loop
                    --write the contents of the row at I to the line variable
                    write(row, reg_block(I));
                    --write the line to the text file
                    writeline(text_file, row);
                end loop;
                file_close(text_file);
            end if;
            --propagate opcode to next stage
            --internal_code_buffer <= instruction_data(31 downto 26);
            -- TODO logic for the ID stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to EX on the next clock cycle only

            --default instruction add $r0, $r0, $r0 to stall
            instruction_decoded_buffer <= "100000"; --funct field of the add instruction
            immediate_data_1_buffer <= (others => '0');
            immediate_data_2_buffer <= (others => '0');
            immediate_data_3_buffer <= (others => '0');
            register_reference_buffer <= "00000";

            --write to reg if needed before reading
            if (write_register = '1' and register_reference_wb /= "00000") then
                reg_block(to_integer(unsigned(register_reference_wb))) := immediate_data_wb;
            end if;

            if (ignore_next_instruction = '0') and (id_stall = '0') then
                --register type instruction 
                case instruction_data(31 downto 26) is
                    when "000000" =>
                        case instruction_data(5 downto 0) is
                            when "100000" => --add
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "100010" => --sub
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "011000" => --mult
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "011010" => --div
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "101010" => --slt
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "100100" => --and
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "100101" => --or
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "100111" => --nor
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "100110" => --xor
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "010000" => --mfhi
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "010010" => --mflo
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "000000" => --sll
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "000010" => --srl
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "000011" => --sra
                                instruction_decoded_buffer <= instruction_data(5 downto 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                                register_reference_buffer <= instruction_data(15 downto 11);
                            when "001000" => --jr
                                --set jump target to value in rs
                                jump_target_buffer <= to_integer(unsigned(reg_block(to_integer(unsigned(instruction_data(25 downto 21))))));
                                valid_jump_target_buffer <= '1';
                                ignore_next_instruction := '1';--indicate will ignore next instruction to ID                            
                            when others =>
                                null;
                        end case;
                    when "001000" => --addi
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        if (instruction_data(15 downto 15) = "0") then --if msb is 0, sign extend 0
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                        elsif (instruction_data(15 downto 15) = "1") then --if msb is 1, sign extend 1
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                        end if;
                        register_reference_buffer <= instruction_data(20 downto 16);
                    when "001010" => --slti
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        if (instruction_data(15 downto 15) = "0") then
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                        elsif (instruction_data(15 downto 15) = "1") then
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                        end if;
                        register_reference_buffer <= instruction_data(20 downto 16);
                    when "001100" => --andi
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                        register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16);
                    when "001101" => --ori
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                        register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16);
                    when "001110" => --xori
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                        register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16);
                    when "001111" => --lui
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16);
                    when "100011" => --lw
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        if (instruction_data(15 downto 15) = "0") then
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                        elsif (instruction_data(15 downto 15) = "1") then
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                        end if;
                        --pass register reference
                        register_reference_buffer(4 downto 0) <= instruction_data(20 downto 16);
                    when "101011" => --sw
                        instruction_decoded_buffer <= instruction_data(31 downto 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 downto 21))));
                        if (instruction_data(15 downto 15) = "0") then
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 downto 0);
                        elsif (instruction_data(15 downto 15) = "1") then
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 downto 0);
                        end if;
                        --content of rt
                        immediate_data_3_buffer <= reg_block(to_integer(unsigned(instruction_data(20 downto 16))));
                    when "000101" => --bne
                        --when rs = rt branch, otherwise nothing
                        if reg_block(to_integer(unsigned(instruction_data(25 downto 21)))) /= reg_block(to_integer(unsigned(instruction_data(20 downto 16)))) then
                            if instruction_data(15) = '0' then--sign extend
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(std_logic_vector'("00000000000000" & instruction_data(15 downto 0) & "00")));
                            else
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(std_logic_vector'("11111111111111" & instruction_data(15 downto 0) & "00")));
                            end if;
                            valid_jump_target_buffer <= '1';
                            ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                        end if;
                    when "000100" => --beq
                        --when rs = rt branch, otherwise nothing
                        if reg_block(to_integer(unsigned(instruction_data(25 downto 21)))) = reg_block(to_integer(unsigned(instruction_data(20 downto 16)))) then
                            if instruction_data(15) = '0' then--sign extend
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(std_logic_vector'("00000000000000" & instruction_data(15 downto 0) & "00")));
                            else
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(std_logic_vector'("11111111111111" & instruction_data(15 downto 0) & "00")));
                            end if;
                            valid_jump_target_buffer <= '1';
                            ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                        end if;
                    when "000010" => --j
                        --set jump target to pc+4[31,28]|address|00
                        temp := std_logic_vector(to_unsigned(pc_next, 32));
                        jump_target_buffer <= to_integer(unsigned(std_logic_vector'(temp(31 downto 28) & instruction_data(25 downto 0) & "00")));
                        valid_jump_target_buffer <= '1';
                        ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                    when "000011" => --jal
                        reg_block(31) := std_logic_vector(to_unsigned(pc_next + 4, 32));--save pc+8 to register 31
                        --set jump target to pc+4[31,28]|address|00
                        temp := std_logic_vector(to_unsigned(pc_next, 32));
                        jump_target_buffer <= to_integer(unsigned(std_logic_vector'(temp(31 downto 28) & instruction_data(25 downto 0) & "00")));
                        valid_jump_target_buffer <= '1';
                        ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                    when others =>
                        null;
                end case;
            else
                valid_jump_target_buffer <= '0';
                ignore_next_instruction := '0';
            end if;
        end if;
    end process;

    instruction_decoded <= instruction_decoded_buffer;
    immediate_data_1 <= immediate_data_1_buffer;
    immediate_data_2 <= immediate_data_2_buffer;
    immediate_data_3 <= immediate_data_3_buffer;
    register_reference <= register_reference_buffer;
    jump_target <= jump_target_buffer;
    valid_jump_target <= valid_jump_target_buffer;
end;