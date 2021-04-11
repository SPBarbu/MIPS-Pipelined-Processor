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
        -- adder inputs for pc
        ex_adder_input0 : in std_logic_vector(31 downto 0);
        ex_adder_input1 : in std_logic_vector(31 downto 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : out std_logic_vector(5 downto 0);
        --address for memory or data to be written back to register
        immediate_data_ex_out : out std_logic_vector(31 downto 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : out std_logic_vector (4 downto 0);

        --ex adder output
        ex_adder_output: out std_logic_vector(31 downto 0);
        --output of zero
        alu_zero_output: out std_logic := '0'

    );
end EX_stage;

architecture behavior of EX_stage is
--DECLARE COMPONENTS
component alu is
port(
    alu_input0 : in std_logic_vector(31 downto 0);
    alu_input1 : in std_logic_vector(31 downto 0);
    alu_output : out std_logic_vector(31 downto 0);
    alu_control : in std_logic_vector(5 downto 0);
    alu_zero : out std_logic := '0'
);
end component;

component add is
port(
    add_input0 : in std_logic_vector(31 downto 0);
    add_input1 : in std_logic_vector(31 downto 0);
    add_output : out std_logic_vector(31 downto 0)
);
end component;

    signal instruction_next_stage_buffer : std_logic_vector(5 downto 0) := (others => '0');--TODO initialize to stall
    signal immediate_data_ex_out_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
    signal register_reference_next_stage_buffer : std_logic_vector (4 downto 0) := (others => '0');--TODO initialize to stall
    signal ex_add_output_buffer : std_logic_vector(31 downto 0);

    --left shifted input for adder
    signal shifted_adder_input : std_logic_vector(31 downto 0);
 
    

begin
    --shifting by 2 bits
    shifted_adder_input <= ex_adder_input1(29 downto 0) & "00";
    --port maps

    arithmetic_logic_unit : alu
    port map(
        alu_input0 => immediate_data_1,
        alu_input1 => immediate_data_2,
        alu_output => immediate_data_ex_out,
        alu_control => current_instruction,
        alu_zero => alu_zero_output
    );

    adder : add
    port map(
        add_input0 => ex_adder_input0,
        add_input1 => shifted_adder_input,
        add_output => ex_adder_output_buffer
    );



    EX_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            --propagate unchanged values to next stage
            instruction_next_stage_buffer <= current_instruction;
            register_reference_next_stage_buffer <= register_reference_current;
            -- TODO logic for the EX stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to MEM on the next clock cycle only
            --branch instructions
            if (current_instruction = "000100") or (current_instruction = "000101") then
                --if branch condition met, branch to pc + branch offset
                if (alu_zero_output = '1') then
                    ex_adder_output <= ex_adder_input0;
                --else continue as usual
                else
                    ex_adder_output <= ex_adder_output_buffer;
                end if;
            end if;
        end if;
    end process;

    instruction_next_stage <= instruction_next_stage_buffer;
    immediate_data_ex_out <= immediate_data_ex_out_buffer;
    register_reference_next_stage <= register_reference_next_stage_buffer;

end;