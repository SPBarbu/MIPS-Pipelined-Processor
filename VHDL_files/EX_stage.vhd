LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY EX_stage IS
    PORT (
        clock : IN STD_LOGIC;
        --instruction to execute currently
        current_instruction : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        --contains data for alu operations, or address for memory
        immediate_data_1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_data_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_data_3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        --address for memory or data to be written back to register
        immediate_data_ex_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        immediate_data_ex_out_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : OUT STD_LOGIC_VECTOR (4 DOWNTO 0)
    );
END EX_stage;

ARCHITECTURE behavior OF EX_stage IS

    SIGNAL instruction_next_stage_buffer : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');--TODO initialize to stall
    SIGNAL immediate_data_ex_out_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');--TODO initialize to stall
    SIGNAL immediate_data_ex_out_buffer_2 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL register_reference_next_stage_buffer : STD_LOGIC_VECTOR (4 DOWNTO 0) := (OTHERS => '0');--TODO initialize to stall
    SIGNAL ex_add_output_buffer : STD_LOGIC_VECTOR(31 DOWNTO 0);
    --buffer for zero of alu   
    SIGNAL ex_alu_zero_buffer : STD_LOGIC;
    --high and low register
    SIGNAL hi : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL lo : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

    EX_logic_process : PROCESS (clock)
        --variable for multiplication
        VARIABLE mult : STD_LOGIC_VECTOR(63 DOWNTO 0);
    BEGIN
        IF (rising_edge(clock)) THEN
            --propagate unchanged values to next stage
            instruction_next_stage_buffer <= current_instruction;
            register_reference_next_stage_buffer <= register_reference_current;
            immediate_data_ex_out_buffer_2 <= immediate_data_3;
            -- TODO logic for the EX stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to MEM on the next clock cycle only
            CASE current_instruction IS
                    --WHEN IT IS TYPE R, THE FUNCT IS PASSED INSTEAD
                    --ARITHMETIC
                    --add
                WHEN "100000" =>
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(unsigned(immediate_data_1) + unsigned(immediate_data_2));

                    --sub
                WHEN "100010" =>
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(unsigned(immediate_data_1) - unsigned(immediate_data_2));

                    --addi
                WHEN "001000" =>
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(unsigned(immediate_data_1) + unsigned(immediate_data_2));

                    --mult
                    --hi register store upper 32 bits, lo register store lower 32 bits of the mult
                WHEN "011000" =>
                    mult := STD_LOGIC_VECTOR(to_unsigned((to_integer(unsigned(immediate_data_1)) * to_integer(unsigned(immediate_data_2))), 64));
                    hi <= mult(63 DOWNTO 32);
                    lo <= mult(31 DOWNTO 0);
                    immediate_data_ex_out_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
                    --div
                    --hi register store remainder, lo register store quotient
                WHEN "011010" =>
                    hi <= STD_LOGIC_VECTOR(unsigned(immediate_data_1) MOD unsigned(immediate_data_2));
                    lo <= STD_LOGIC_VECTOR(unsigned(immediate_data_1) / unsigned(immediate_data_2));
                    immediate_data_ex_out_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

                    --slt
                    --set on less than, if immediate_data_1 < immediate_data_2, output 1, else 0
                WHEN "101010" =>
                    IF (unsigned(immediate_data_1) < unsigned(immediate_data_2)) THEN
                        immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(to_unsigned(1, 32));
                    ELSE
                        immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(to_unsigned(0, 32));
                    END IF;

                    --slti
                    --same as slt but with immediate value
                WHEN "001010" =>
                    IF (unsigned(immediate_data_1) < unsigned(immediate_data_2)) THEN
                        immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(to_unsigned(1, 32));
                    ELSE
                        immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(to_unsigned(0, 32));
                    END IF;

                    --LOGICAL
                    --and
                WHEN "100100" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 AND immediate_data_2;

                    --or
                WHEN "100101" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 OR immediate_data_2;

                    --nor
                WHEN "100111" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 NOR immediate_data_2;

                    --xor
                WHEN "101000" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 XOR immediate_data_2;

                    --andi
                WHEN "001100" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 AND immediate_data_2;

                    --ori
                WHEN "001101" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 OR immediate_data_2;

                    --xori
                WHEN "001110" =>
                    immediate_data_ex_out_buffer <= immediate_data_1 XOR immediate_data_2;

                    --TRANSFER
                    --mfhi
                    --read hi register
                WHEN "010000" =>
                    immediate_data_ex_out_buffer <= hi;

                    --mflo
                    --read lo register
                WHEN "010010" =>
                    immediate_data_ex_out_buffer <= lo;

                    --lui
                    --upper 16 bits are immediate_data_2, rest are 0
                WHEN "001111" =>
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(immediate_data_1)), 16)) & "0000000000000000";

                    --SHIFT
                    --sll
                    --shift info stored in immediate_data_2, discard (32-(32-shamt)) MSB and concatenate zeros at the end
                WHEN "000000" =>
                    immediate_data_ex_out_buffer <= immediate_data_1((31 - to_integer(unsigned(immediate_data_2))) DOWNTO 0) & STD_LOGIC_VECTOR(to_unsigned(0, to_integer(unsigned(immediate_data_2))));

                    --srl
                    --shift info stored in immediate_data_2, discard (32-(32-shamt)) LSB and concatenate zeros at the beginning
                WHEN "000010" =>
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(to_unsigned(0, to_integer(unsigned(immediate_data_2)))) & immediate_data_1(31 DOWNTO to_integer(unsigned(immediate_data_2)));

                    --sra
                WHEN "000011" =>
                    --same as srl except concatenate either 0 or 1 dependning on MSB of immediate_data_1
                    --adding a "" in order to be a vector to do unisgned() conversion
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned'("" & immediate_data_1(31))), to_integer(unsigned(immediate_data_2)))) & immediate_data_1(31 DOWNTO to_integer(unsigned(immediate_data_2)));
                    --MEMORY
                    --lw
                WHEN "100011" =>
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(unsigned(immediate_data_1) + unsigned(immediate_data_2));

                    --sw
                WHEN "101011" =>
                    immediate_data_ex_out_buffer <= STD_LOGIC_VECTOR(unsigned(immediate_data_1) + unsigned(immediate_data_2));
                WHEN OTHERS =>
                    NULL;

            END CASE;
        END IF;
    END PROCESS;

    instruction_next_stage <= instruction_next_stage_buffer;
    immediate_data_ex_out <= immediate_data_ex_out_buffer;
    immediate_data_ex_out_2 <= immediate_data_ex_out_buffer_2;
    register_reference_next_stage <= register_reference_next_stage_buffer;

END;