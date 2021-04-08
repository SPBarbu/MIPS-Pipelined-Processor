--ALU
library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port(
        alu_input0 : in std_logic_vector(31 downto 0);
        alu_input1 : in std_logic_vector(31 downto 0);
        alu_output : out std_logic_vector(31 downto 0);
        alu_control : in std_logic_vector(5 downto 0);
        alu_zero : out std_logic := '0'
    );
    end alu;
    
    architecture arch of alu is
    
    --declaring signals
    --hi and lo registers
    signal hi : std_logic_vector(31 downto 0);
    signal lo : std_logic_vector(31 downto 0);
    signal mult : std_logic_vector(63 downto 0);
    begin
    process(alu_control)
    begin
        case alu_control is
            --TRANSLATED "ACTION" COLUMN OF THE MIPS OPCODE REFERECE PDF TO VHDL
            --ARITHMETIC
            --add
            when "" =>
                alu_output <= std_logic_vector(unsigned(alu_input0) + unsigned(alu_input1));
            
            --sub
            when "" =>
                alu_output <= std_logic_vector(unsigned(alu_input0) - unsigned(alu_input1));
            
            --addi
            when "" =>
                alu_output <= std_logic_vector(unsigned(alu_input0) + unsigned(alu_input1));
            
            --mult
            --hi register store upper 32 bits, lo register store lower 32 bits of the mult
            when "" =>
                --convert to first int, do mult, and then convert to 64 bit 
                -- hi <= std_logic_vector(to_unsigned(to_integer(unsigned(alu_input0)) * to_integer(unsigned(alu_input1)), 64))(63 downto 32);
                -- lo <= std_logic_vector(to_unsigned(to_integer(unsigned(alu_input0)) * to_integer(unsigned(alu_input1)), 64))(31 downto 0);
                mult <= std_logic_vector(unsigned(alu_input0) * unsigned(alu_input1));
                hi <= mult(63 downto 32);
                lo <= mult(31 downto 0);
                alu_output <= std_logic_vector(unsigned(alu_input0) * unsigned(alu_input1));
            
            --div
            --hi register store remainder, lo register store quotient
            when "" =>
                hi <= std_logic_vector(unsigned(alu_input0) mod unsigned(alu_input1));
                lo <= std_logic_vector(unsigned(alu_input0) / unsigned(alu_input1));
                alu_output <= std_logic_vector(unsigned(alu_input0) / unsigned(alu_input1));
            
            --slt
            --set on less than, if input0 < input1, output 1, else 0
            when "" =>
                if (unsigned(alu_input0) < unsigned(alu_input1)) then
                    alu_output <= std_logic_vector(to_unsigned(1, 32));
                else
                    alu_output <= std_logic_vector(to_unsigned(0, 32));
                end if;
            
            --slti
            --same as slt but with immediate value
            when "" =>
                if (unsigned(alu_input0) < unsigned(alu_input1)) then
                    alu_output <= std_logic_vector(to_unsigned(1, 32));
                else
                    alu_output <= std_logic_vector(to_unsigned(0, 32));
                end if;
            
            --LOGICAL
            --and
            when "" =>
                alu_output <= alu_input0 and alu_input1;
            
            --or
            when "" =>
                alu_output <= alu_input0 or alu_input1;
            
            --nor
            when "" =>
                alu_output <= alu_input0 nor alu_input1;
            
            --xor
            when "" =>
                alu_output <= alu_input0 xor alu_input1;
            
            --andi
            when "" =>
                alu_output <= alu_input0 and alu_input1;
            
            --ori
            when "" =>
                alu_output <= alu_input0 or alu_input1;
            
            --xori
            when "" =>
                alu_output <= alu_input0 xor alu_input1;
            
            --TRANSFER
            --mfhi
            --read hi register
            when "" =>
                alu_output <= hi;
                
            --mflo
            --read lo register
            when "" =>
                alu_output <= lo;
            
            --lui
            --upper 16 bits are input1, rest are 0
            when "" =>
                alu_output <= std_logic_vector(to_unsigned(to_integer(unsigned(alu_input1)), 16)) & "0000000000000000";
            
            --SHIFT
            --sll
            --shift info stored in shamt bits of input1, discard (32-(32-shamt)) MSB and concatenate zeros at the end
            when "" =>
                alu_output <= alu_input0((31 - to_integer(unsigned(alu_input1(10 downto 6)))) downto 0) & std_logic_vector(to_unsigned(0, to_integer(unsigned(alu_input1(10 downto 6)))));
                
            --srl
            --shift info stored in shamt bits of input1, discard (32-(32-shamt)) LSB and concatenate zeros at the beginning
            when "" =>
                alu_output <= std_logic_vector(to_unsigned(0, to_integer(unsigned(alu_input1(10 downto 6))))) & alu_input0(31 downto to_integer(unsigned(alu_input1(10 downto 6))));
                
            --sra
            when "" =>
                --same as srl except concatenate either 0 or 1 dependning on MSB of input0
                --adding a "" in order to be a vector to do unisgned() conversion
                alu_output <= std_logic_vector(to_unsigned(to_integer(unsigned'("" & alu_input0(31))), to_integer(unsigned(alu_input1(10 downto 6))))) & alu_input0(31 downto to_integer(unsigned(alu_input1(10 downto 6))));
            --MEMORY
            --lw
            when "" =>
                alu_output <= std_logic_vector(unsigned(alu_input0) + unsigned(alu_input1));
                
            --sw
            when "" =>
                alu_output <= std_logic_vector(unsigned(alu_input0) + unsigned(alu_input1));
                
            --CONTROL_FLOW
            --beq
            when "" =>
                --input1 stores offset
                alu_output <= std_logic_vector(to_unsigned(to_integer(unsigned(alu_input0)) + to_integer(unsigned(alu_input1)) * 4, 32));
                if (alu_input0 = alu_input1) then
                    alu_zero <= '1';
                else
                    alu_zero <= '0';
                end if;
            --bne
            when "" =>
                alu_output <= std_logic_vector(to_unsigned(to_integer(unsigned(alu_input0)) + to_integer(unsigned(alu_input1)) * 4, 32));
                if (alu_input0 = alu_input1) then
                    alu_zero <= '0';
                else
                    alu_zero <= '1';
                end if;
            --j
            when "" =>
                --input0 contains pc address, input1 contains target, take 4 MSB from pc and 26 LSB from target and concatenate 00   
                alu_output <= alu_input0(31 downto 28) & alu_input1(25 downto 0) & "00";
                alu_zero <= '1';
                
            --jr
            when "" =>
                --input0 stores rs
                alu_output <= alu_input0;
                alu_zero <= '1';
                
            --jal
            when "" =>
                --same as j
                alu_output <= alu_input0(31 downto 28) & alu_input1(25 downto 0) & "00";
                alu_zero <= '1';
                
            when others =>
                null;

        end case;
    end process;
    end arch;