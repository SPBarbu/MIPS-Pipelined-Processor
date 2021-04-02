library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ID_stage is
    port (
        clock : in std_logic;
        --raw instruction data to decode
        instruction_data : in std_logic_vector(31 downto 0);
        --data to be written to register
        immediate_data_wb : in std_logic_vector(31 downto 0);
        --register reference to write to
        register_reference_wb : in std_logic_vector (4 downto 0);
        --indicate that register value should be overwritten
        write_register : in std_logic;
        ------------------------------------------------------------------------------
        --opcode of the instruction
        instruction_decoded : out std_logic_vector(5 downto 0);
        --data for alu operations, or address for memory
        immediate_data_1 : out std_logic_vector(31 downto 0);
        immediate_data_2 : out std_logic_vector(31 downto 0);
        --register reference for writeback
        register_reference : out std_logic_vector (4 downto 0)
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
--xori = 001101
--mfhi = 001110
--mflo = 001111
--lui  = 010000
--sll  = 010001
--srl  = 010010
--sra  = 010011
--lw   = 010100
--sw   = 010101
--beq  = 010110
--bne  = 010111
--j    = 011000
--jr   = 011001
--jal  = 011010

architecture behavior of ID_stage is
    --buffer signals to be written to at the end of the stage for the next stage
    signal instruction_decoded_buffer : std_logic_vector(5 downto 0) := (others => '0'); --TODO initialize to stall
    signal immediate_data_1_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal immediate_data_2_buffer : std_logic_vector(31 downto 0) := (others => '0'); --TODO initialize to stall
    signal register_reference_buffer : std_logic_vector (4 downto 0) := (others => '0'); --TODO initialize to stall
begin
    ID_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            --propagate opcode to next stage
            instruction_decoded_buffer <= instruction_data(31 downto 26);
            -- TODO logic for the ID stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to EX on the next clock cycle only

            --default instruction add $r0, $r0, $r0 to stall
            instruction_decoded_buffer <= "000001";
            immediate_data_1_buffer <= (others => '0');
            immediate_data_2_buffer <= (others => '0');
            register_reference_buffer <= "00000";
            
            --set the first and second read register from rs, rt or shamt field as need be

            if instruction_data_buffer(31 downto 26) = "000000" then --register type instruction

                --destination register is rd field
                if instruction_data_buffer(15 downto 11) /= "000000" then --destination register cant be r0
                    register_reference_buffer(4 downto 0) <= instruction_data_buffer(15 downto 11); --set write register data for all instructions
                end if;

                if instruction_data_buffer(5 downto 0) = "100000" then --add instruction
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    instruction_decoded_buffer <= "000001";

                elsif instruction_data_buffer(5 downto 0) = "100010" then  --sub
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    instruction_decoded_buffer <= "000010";

                elsif instruction_data_buffer(5 downto 0) = "011000" then --mult
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    instruction_decoded_buffer <= "000100";

                elsif instruction_data_buffer(5 downto 0) = "011010" then --div
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    instruction_decoded_buffer <= "000101";

                elsif instruction_data_buffer(5 downto 0) = "101010" then  --slt
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    instruction_decoded_buffer <= "000110";

                elsif instruction_data_buffer(5 downto 0) = "100100" then  --and
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    instruction_decoded_buffer <= "001000";

                elsif instruction_data(5 downto 0) = "100101" then  --or
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    instruction_decoded_buffer <= "001001";

                elsif instruction_data_buffer(5 downto 0) = "100111" then  --nor
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    instruction_decoded_buffer <= "001010";

                elsif instruction_data_buffer(5 downto 0) = "101000" then  --xor
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    instruction_decoded_buffer <= "001011";

                elsif instruction_data_buffer(5 downto 0) = "100111" then  --mfhi
                    instruction_decoded_buffer <= "001111";

                elsif instruction_data_buffer(5 downto 0) = "100111" then  --mflo
                    instruction_decoded_buffer <= "010000";

                elsif instruction_data_buffer(5 downto 0) = "000000" then  --sll
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(10 downto 6);
                    instruction_decoded_buffer <= "010010";

                elsif instruction_data_buffer(5 downto 0) = "000010" then  --srl
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(10 downto 6);
                    instruction_decoded_buffer <= "010011";

                elsif instruction_data_buffer(5 downto 0) = "000011" then  --sra
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer(4 downto 0) <= instruction_data_buffer(10 downto 6);
                    instruction_decoded_buffer <= "010111";

                elsif instruction_data_buffer(5 downto 0) = "001000" then  --jr
                    if instruction_data_buffer(15 downto 11) /= "000000" then --destination register cant be r0
                        register_reference_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21); --overwrite write data for rs
                    end if;
                end if;
            
            elsif ((instruction_data_buffer(31 downto 26) /= "000000") or 
                   (instruction_data_buffer(31 downto 26) /= "000010") or 
                   (instruction_data_buffer(31 downto 26) /= "000011")) then --immediate type instruction, no jumps

                --destination register is rt field
                if instruction_data_buffer(20 downto 16) /= "000000" then --destination register cant be r0
                    register_reference_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16); --set write register data for all instructions
                end if;

                if instruction_data_buffer(31 downto 26) = "001000" then --addi instruction
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    if instruction_data_buffer(15 downto 15) = '0' then --if msb is 0, sign extend 0
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data_buffer(15 downto 0);
                    elsif instruction_data_buffer(15 downto 15) = '1' then --if msb is 1, sign extend 1
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data_buffer(15 downto 0);
                    end if;
                    instruction_decoded_buffer <= "000011";

                elsif instruction_data_buffer(5 downto 0) = "001010" then  --slti
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    if instruction_data_buffer(15 downto 15) = '0' then 
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data_buffer(15 downto 0);
                    elsif instruction_data_buffer(15 downto 15) = '1' then 
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data_buffer(15 downto 0);
                    end if;
                    instruction_decoded_buffer <= "000111";

                elsif instruction_data_buffer(5 downto 0) = "001100" then --andi
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer <= "0000000000000000" & instruction_data_buffer(15 downto 0);
                    instruction_decoded_buffer <= "001101";

                elsif instruction_data_buffer(5 downto 0) = "011010" then --ori
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer <= "0000000000000000" & instruction_data_buffer(15 downto 0);
                    instruction_decoded_buffer <= "001110";

                elsif instruction_data_buffer(5 downto 0) = "101010" then  --xori
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    immediate_data_2_buffer <= "0000000000000000" & instruction_data_buffer(15 downto 0);
                    instruction_decoded_buffer <= "001110";

                elsif instruction_data_buffer(5 downto 0) = "001111" then  --lui
                    immediate_data_1_buffer <= instruction_data_buffer(15 downto 0) & "0000000000000000";
                    instruction_decoded_buffer <= "010000";

                elsif instruction_data(5 downto 0) = "100011" then  --lw
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    if instruction_data_buffer(15 downto 15) = '0' then 
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data_buffer(15 downto 0);
                    elsif instruction_data_buffer(15 downto 15) = '1' then
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data_buffer(15 downto 0);
                    end if;
                    instruction_decoded_buffer <= "010100";

                elsif instruction_data_buffer(5 downto 0) = "101011" then  --sw
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(25 downto 21);
                    if instruction_data_buffer(15 downto 15) = '0' then 
                        immediate_data_2_buffer <= "0000000000000000" & instruction_data_buffer(15 downto 0);
                    elsif instruction_data_buffer(15 downto 15) = '1' then 
                        immediate_data_2_buffer <= "1111111111111111" & instruction_data_buffer(15 downto 0);
                    end if;
                    instruction_decoded_buffer <= "010101";

                elsif instruction_data_buffer(5 downto 0) = "000100" then  --beq
                    if instruction_data_buffer(25 downto 21) /= "000000" then --destination register cant be r0
                        register_reference_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16); --overwrite destination as rs
                    end if;
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    if instruction_data_buffer(15 downto 15) = '0' then 
                        immediate_data_2_buffer <= "00000000000000" & instruction_data_buffer(15 downto 0) & "00";
                    elsif instruction_data_buffer(15 downto 15) = '1' then 
                        immediate_data_2_buffer <= "11111111111111" & instruction_data_buffer(15 downto 0) & "00";
                    end if;
                    instruction_decoded_buffer <= "010110";

                elsif instruction_data_buffer(5 downto 0) = "000101" then  --bne
                    if instruction_data_buffer(25 downto 21) /= "000000" then --destination register cant be r0
                        register_reference_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16); --overwrite destination as rs
                    end if;
                    immediate_data_1_buffer(4 downto 0) <= instruction_data_buffer(20 downto 16);
                    if instruction_data_buffer(15 downto 15) = '0' then 
                        immediate_data_2_buffer <= "00000000000000" & instruction_data_buffer(15 downto 0) & "00";
                    elsif instruction_data_buffer(15 downto 15) = '1' then 
                        immediate_data_2_buffer <= "11111111111111" & instruction_data_buffer(15 downto 0) & "00";
                    end if;
                    instruction_decoded_buffer <= "010111";
                end if;
            
            elsif (instruction_data_buffer(31 downto 26) = "000010") then --j unconditional jump
                immediate_data_1_buffer (25 downto 0) <= instruction_data_buffer(25 downto 0);
                instruction_decoded_buffer <= "011000";
            
            elsif (instruction_data_buffer(31 downto 26) = "000011") then --jal
                immediate_data_1_buffer (25 downto 0) <= instruction_data_buffer(25 downto 0);
                instruction_decoded_buffer <= "011010";
                
            end if;
                
        
                
        end if;
    end process;

    instruction_decoded <= instruction_decoded_buffer;
    immediate_data_1 <= immediate_data_1_buffer;
    immediate_data_2 <= immediate_data_2_buffer;
    register_reference <= register_reference_buffer;

end;