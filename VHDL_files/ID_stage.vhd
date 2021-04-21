LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY ID_stage IS
    GENERIC (
        RAM_SIZE : INTEGER := 32768
    );
    PORT (
        clock : IN STD_LOGIC;
        --raw instruction data to decode
        instruction_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        --data to be written to register
        immediate_data_wb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        --register reference to write to
        register_reference_wb : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        --bit for when register should be written 
        write_register : IN STD_LOGIC;
        --program counter of next instruction ie pc+4
        pc_next : IN INTEGER RANGE 0 TO RAM_SIZE - 1;
        -- --for writing back to file for registers
        regwritetotext : IN STD_LOGIC;
        --for stalling
        id_stall : IN STD_LOGIC;
        ------------------------------------------------------------------------------
        --opcode of the instruction in case of immediate or jump, funct of instruction in case of register
        instruction_decoded : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        --data for alu operations, or address for memory
        immediate_data_1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_data_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        --data for store in memory
        immediate_data_3 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        --register reference for writeback
        register_reference : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
        --jump target for branch or jump 
        jump_target : OUT INTEGER RANGE 0 TO RAM_SIZE - 1;
        --specifies if the jump target is valid
        valid_jump_target : OUT STD_LOGIC
    );
END ID_stage;

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

ARCHITECTURE behavior OF ID_stage IS
    --buffer signals to be written to at the end of the stage for the next stage
    SIGNAL instruction_decoded_buffer : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0'); --TODO initialize to stall
    SIGNAL immediate_data_1_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0'); --TODO initialize to stall
    SIGNAL immediate_data_2_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0'); --TODO initialize to stall
    SIGNAL immediate_data_3_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL register_reference_buffer : STD_LOGIC_VECTOR (4 DOWNTO 0) := (OTHERS => '0'); --TODO initialize to stall
    SIGNAL jump_target_buffer : INTEGER RANGE 0 TO RAM_SIZE - 1 := 0;
    SIGNAL valid_jump_target_buffer : STD_LOGIC := '0';

    --signals for registers
    --similar implementation to memory in cache project
    TYPE Reg_Block_Type IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(31 DOWNTO 0);

    --for write back to file
    FILE text_file : text OPEN write_mode IS "registers.txt";

BEGIN
    ID_logic_process : PROCESS (clock)
        VARIABLE ignore_next_instruction : STD_LOGIC := '0';
        VARIABLE temp : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE reg_block : Reg_Block_Type := (OTHERS => (OTHERS => '0')); --all registers initialized to 0
        VARIABLE row : line;
        --for write back to file
        FILE text_file : text OPEN write_mode IS "registers.txt";
    BEGIN
        IF (rising_edge(clock)) THEN
            IF (regwritetotext = '1') THEN
                --iterate for every reg  
                FOR I IN 0 TO 31 LOOP
                    --write the contents of the row at I to the line variable
                    write(row, reg_block(I));
                    --write the line to the text file
                    writeline(text_file, row);
                END LOOP;
                file_close(text_file);
            END IF;
            --propagate opcode to next stage
            --internal_code_buffer <= instruction_data(31 downto 26);
            -- TODO logic for the ID stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to EX on the next clock cycle only

            --default instruction add $r0, $r0, $r0 to stall
            instruction_decoded_buffer <= "100000"; --funct field of the add instruction
            immediate_data_1_buffer <= (OTHERS => '0');
            immediate_data_2_buffer <= (OTHERS => '0');
            immediate_data_3_buffer <= (OTHERS => '0');
            register_reference_buffer <= "00000";

            --write to reg if needed before reading
            IF (write_register = '1' AND register_reference_wb /= "00000") THEN
                reg_block(to_integer(unsigned(register_reference_wb))) := immediate_data_wb;
            END IF;

            IF (ignore_next_instruction = '0') AND (id_stall = '0') THEN
                --register type instruction 
                CASE instruction_data(31 DOWNTO 26) IS
                    WHEN "000000" =>
                        CASE instruction_data(5 DOWNTO 0) IS
                            WHEN "100000" => --add
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "100010" => --sub
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "011000" => --mult
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "011010" => --div
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "101010" => --slt
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "100100" => --and
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "100101" => --or
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "100111" => --nor
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "101000" => --xor
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                                immediate_data_2_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "010000" => --mfhi
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "010010" => --mflo
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "000000" => --sll
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                immediate_data_2_buffer <= "000000000000000000000000000" & instruction_data(10 DOWNTO 6);
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "000010" => --srl
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                immediate_data_2_buffer <= "000000000000000000000000000" & instruction_data(10 DOWNTO 6);
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "000011" => --sra
                                instruction_decoded_buffer <= instruction_data(5 DOWNTO 0);
                                immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                                immediate_data_2_buffer <= "000000000000000000000000000" & instruction_data(10 DOWNTO 6);
                                register_reference_buffer <= instruction_data(15 DOWNTO 11);
                            WHEN "001000" => --jr
                                --set jump target to value in rs
                                jump_target_buffer <= to_integer(unsigned(reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))))));
                                valid_jump_target_buffer <= '1';
                                ignore_next_instruction := '1';--indicate will ignore next instruction to ID                            
                            WHEN OTHERS =>
                                NULL;
                        END CASE;
                    WHEN "001000" => --addi
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                        IF (instruction_data(15 DOWNTO 15) = "0") THEN --if msb is 0, sign extend 0
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        ELSIF (instruction_data(15 DOWNTO 15) = "1") THEN --if msb is 1, sign extend 1
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 DOWNTO 0);
                        END IF;
                        register_reference_buffer <= instruction_data(20 DOWNTO 16);
                    WHEN "001010" => --slti
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                        IF (instruction_data(15 DOWNTO 15) = "0") THEN
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        ELSIF (instruction_data(15 DOWNTO 15) = "1") THEN
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 DOWNTO 0);
                        END IF;
                        register_reference_buffer <= instruction_data(20 DOWNTO 16);
                    WHEN "001100" => --andi
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        register_reference_buffer(4 DOWNTO 0) <= instruction_data(20 DOWNTO 16);
                    WHEN "001101" => --ori
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        register_reference_buffer(4 DOWNTO 0) <= instruction_data(20 DOWNTO 16);
                    WHEN "001110" => --xori
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        register_reference_buffer(4 DOWNTO 0) <= instruction_data(20 DOWNTO 16);
                    WHEN "001111" => --lui
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        register_reference_buffer(4 DOWNTO 0) <= instruction_data(20 DOWNTO 16);
                    WHEN "100011" => --lw
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                        IF (instruction_data(15 DOWNTO 15) = "0") THEN
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        ELSIF (instruction_data(15 DOWNTO 15) = "1") THEN
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 DOWNTO 0);
                        END IF;
                        --pass register reference
                        register_reference_buffer(4 DOWNTO 0) <= instruction_data(20 DOWNTO 16);
                    WHEN "101011" => --sw
                        instruction_decoded_buffer <= instruction_data(31 DOWNTO 26);
                        immediate_data_1_buffer <= reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21))));
                        IF (instruction_data(15 DOWNTO 15) = "0") THEN
                            immediate_data_2_buffer <= "0000000000000000" & instruction_data(15 DOWNTO 0);
                        ELSIF (instruction_data(15 DOWNTO 15) = "1") THEN
                            immediate_data_2_buffer <= "1111111111111111" & instruction_data(15 DOWNTO 0);
                        END IF;
                        --content of rt
                        immediate_data_3_buffer <= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16))));
                    WHEN "000101" => --bne
                        --when rs = rt branch, otherwise nothing
                        IF reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21)))) /= reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16)))) THEN
                            IF instruction_data(15) = '0' THEN--sign extend
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(STD_LOGIC_VECTOR'("00000000000000" & instruction_data(15 DOWNTO 0) & "00")));
                            ELSE
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(STD_LOGIC_VECTOR'("11111111111111" & instruction_data(15 DOWNTO 0) & "00")));
                            END IF;
                            valid_jump_target_buffer <= '1';
                            ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                        END IF;
                    WHEN "000100" => --beq
                        --when rs = rt branch, otherwise nothing
                        IF reg_block(to_integer(unsigned(instruction_data(25 DOWNTO 21)))) = reg_block(to_integer(unsigned(instruction_data(20 DOWNTO 16)))) THEN
                            IF instruction_data(15) = '0' THEN--sign extend
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(STD_LOGIC_VECTOR'("00000000000000" & instruction_data(15 DOWNTO 0) & "00")));
                            ELSE
                                jump_target_buffer <= to_integer(to_unsigned(pc_next, 32) + unsigned(STD_LOGIC_VECTOR'("11111111111111" & instruction_data(15 DOWNTO 0) & "00")));
                            END IF;
                            valid_jump_target_buffer <= '1';
                            ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                        END IF;
                    WHEN "000010" => --j
                        --set jump target to pc+4[31,28]|address|00
                        temp := STD_LOGIC_VECTOR(to_unsigned(pc_next, 32));
                        jump_target_buffer <= to_integer(unsigned(STD_LOGIC_VECTOR'(temp(31 DOWNTO 28) & instruction_data(25 DOWNTO 0) & "00")));
                        valid_jump_target_buffer <= '1';
                        ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                    WHEN "000011" => --jal
                        reg_block(31) := STD_LOGIC_VECTOR(to_unsigned(pc_next + 4, 32));--save pc+8 to register 31
                        --set jump target to pc+4[31,28]|address|00
                        temp := STD_LOGIC_VECTOR(to_unsigned(pc_next, 32));
                        jump_target_buffer <= to_integer(unsigned(STD_LOGIC_VECTOR'(temp(31 DOWNTO 28) & instruction_data(25 DOWNTO 0) & "00")));
                        valid_jump_target_buffer <= '1';
                        ignore_next_instruction := '1';--indicate will ignore next instruction to ID
                    WHEN OTHERS =>
                        NULL;
                END CASE;
            ELSE
                valid_jump_target_buffer <= '0';
                ignore_next_instruction := '0';
            END IF;
        END IF;
    END PROCESS;

    instruction_decoded <= instruction_decoded_buffer;
    immediate_data_1 <= immediate_data_1_buffer;
    immediate_data_2 <= immediate_data_2_buffer;
    immediate_data_3 <= immediate_data_3_buffer;
    register_reference <= register_reference_buffer;
    jump_target <= jump_target_buffer;
    valid_jump_target <= valid_jump_target_buffer;
END;