library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EX_stage is
    port (
        clock : in std_logic;
        --instruction to execute currently
        current_instruction : in std_logic_vector(5 downto 0);
        --contains data for alu operations, or address for memory
        immediate_data_1 : in std_logic_vector(31 downto 0);
        immediate_data_2 : in std_logic_vector(31 downto 0);
        immediate_data_3 : in std_logic_vector(31 downto 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : out std_logic_vector(5 downto 0);
        --address for memory or data to be written back to register
        immediate_data_ex_out : out std_logic_vector(31 downto 0);
        immediate_data_ex_out_2 : out std_logic_vector(31 downto 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : out std_logic_vector (4 downto 0)
    );
end EX_stage;

architecture behavior of EX_stage is

    signal instruction_next_stage_buffer : std_logic_vector(5 downto 0) := (others => '0');--TODO initialize to stall
    signal immediate_data_ex_out_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
    signal immediate_data_ex_out_buffer_2 : std_logic_vector(31 downto 0) := (others => '0');
    signal register_reference_next_stage_buffer : std_logic_vector (4 downto 0) := (others => '0');--TODO initialize to stall
    signal ex_add_output_buffer : std_logic_vector(31 downto 0);


    --buffer for zero of alu   
    signal ex_alu_zero_buffer : std_logic;
    --high and low register
    signal hi : std_logic_vector(31 downto 0);
    signal lo : std_logic_vector(31 downto 0);
begin

    EX_logic_process : process (clock)
    --variable for multiplication
    variable mult : std_logic_vector(63 downto 0);
    begin
        if (rising_edge(clock)) then
            --propagate unchanged values to next stage
            instruction_next_stage_buffer <= current_instruction;
            register_reference_next_stage_buffer <= register_reference_current;
            immediate_data_ex_out_buffer_2 <= immediate_data_3;
            -- TODO logic for the EX stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to MEM on the next clock cycle only
            case current_instruction is
                --WHEN IT IS TYPE R, THE FUNCT IS PASSED INSTEAD
                --ARITHMETIC
                --add
                when "100000" =>
                    immediate_data_ex_out_buffer <= std_logic_vector(unsigned(immediate_data_1) + unsigned(immediate_data_2));
                
                --sub
                when "100010" =>
                    immediate_data_ex_out_buffer <= std_logic_vector(unsigned(immediate_data_1) - unsigned(immediate_data_2));
                
                --addi
                when "001000" =>
                    immediate_data_ex_out_buffer <= std_logic_vector(unsigned(immediate_data_1) + unsigned(immediate_data_2));
                
                --mult
                --hi register store upper 32 bits, lo register store lower 32 bits of the mult
                when "011000" =>
                    mult := std_logic_vector(to_unsigned((to_integer(unsigned(immediate_data_1)) * to_integer(unsigned(immediate_data_2))), 64));
                    hi <= mult(63 downto 32);
                    lo <= mult(31 downto 0);
                    immediate_data_ex_out_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";               
                --div
                --hi register store remainder, lo register store quotient
                when "011010" =>
                    hi <= std_logic_vector(unsigned(immediate_data_1) mod unsigned(immediate_data_2));
                    lo <= std_logic_vector(unsigned(immediate_data_1) / unsigned(immediate_data_2));
                    immediate_data_ex_out_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
                
                --slt
                --set on less than, if input0 < input1, output 1, else 0
                when "101010" =>
                    if (unsigned(immediate_data_1) < unsigned(immediate_data_2)) then
                        immediate_data_ex_out_buffer <= std_logic_vector(to_unsigned(1, 32));
                    else
                        immediate_data_ex_out_buffer <= std_logic_vector(to_unsigned(0, 32));
                    end if;
                
                --slti
                --same as slt but with immediate value
                when "001010" =>
                    if (unsigned(immediate_data_1) < unsigned(immediate_data_2)) then
                        immediate_data_ex_out_buffer <= std_logic_vector(to_unsigned(1, 32));
                    else
                        immediate_data_ex_out_buffer <= std_logic_vector(to_unsigned(0, 32));
                    end if;
                
                --LOGICAL
                --and
                when "100100" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 and immediate_data_2;
                
                --or
                when "100101" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 or immediate_data_2;
                
                --nor
                when "100111" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 nor immediate_data_2;
                
                --xor
                when "101000" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 xor immediate_data_2;
                
                --andi
                when "001100" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 and immediate_data_2;
                
                --ori
                when "001101" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 or immediate_data_2;
                
                --xori
                when "001110" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 xor immediate_data_2;
                
                --TRANSFER
                --mfhi
                --read hi register
                when "010000" =>
                    immediate_data_ex_out_buffer <= hi;
                    
                --mflo
                --read lo register
                when "010010" =>
                    immediate_data_ex_out_buffer <= lo;
                
                --lui
                --upper 16 bits are input1, rest are 0
                when "001111" =>
                    immediate_data_ex_out_buffer <= std_logic_vector(to_unsigned(to_integer(unsigned(immediate_data_1)), 16)) & "0000000000000000";
                
                --SHIFT
                --sll
                --shift info stored in shamt bits of input1, discard (32-(32-shamt)) MSB and concatenate zeros at the end
                when "000000" =>
                    immediate_data_ex_out_buffer <= immediate_data_1((31 - to_integer(unsigned(immediate_data_2))) downto 0) & std_logic_vector(to_unsigned(0, to_integer(unsigned(immediate_data_2))));
                    
                --srl
                --shift info stored in shamt bits of input1, discard (32-(32-shamt)) LSB and concatenate zeros at the beginning
                when "000010" =>
                    immediate_data_ex_out_buffer <= std_logic_vector(to_unsigned(0, to_integer(unsigned(immediate_data_2)))) & immediate_data_1(31 downto to_integer(unsigned(immediate_data_2)));
                    
                --sra
                when "000011" =>
                    --same as srl except concatenate either 0 or 1 dependning on MSB of input0
                    --adding a "" in order to be a vector to do unisgned() conversion
                    immediate_data_ex_out_buffer <= std_logic_vector(to_unsigned(to_integer(unsigned'("" & immediate_data_1(31))), to_integer(unsigned(immediate_data_2)))) & immediate_data_1(31 downto to_integer(unsigned(immediate_data_2)));
                --MEMORY
                --lw
                when "100011" =>
                    immediate_data_ex_out_buffer <= std_logic_vector(unsigned(immediate_data_1) + unsigned(immediate_data_2));
                    
                --sw
                when "101011" =>
                    immediate_data_ex_out_buffer <= std_logic_vector(unsigned(immediate_data_1) + unsigned(immediate_data_2));
                when others =>
                    null;
    
            end case;
        end if;
    end process;

    instruction_next_stage <= instruction_next_stage_buffer;
    immediate_data_ex_out <= immediate_data_ex_out_buffer;
    immediate_data_ex_out_2 <= immediate_data_ex_out_buffer_2;
    register_reference_next_stage <= register_reference_next_stage_buffer;

end;