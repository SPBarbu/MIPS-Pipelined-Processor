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
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : out std_logic_vector(5 downto 0);
        --address for memory or data to be written back to register
        immediate_data_ex_out : out std_logic_vector(31 downto 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : out std_logic_vector (4 downto 0)
    );
end EX_stage;

architecture behavior of EX_stage is
    signal instruction_next_stage_buffer : std_logic_vector(5 downto 0) := (others => '0');--TODO initialize to stall
    signal immediate_data_ex_out_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
    signal register_reference_next_stage_buffer : std_logic_vector (4 downto 0) := (others => '0');--TODO initialize to stall
begin
    EX_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            --propagate unchanged values to next stage
            instruction_next_stage_buffer <= current_instruction;
            register_reference_next_stage_buffer <= register_reference_current;
            -- TODO logic for the EX stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to MEM on the next clock cycle only
        end if;
    end process;

    instruction_next_stage <= instruction_next_stage_buffer;
    immediate_data_ex_out <= immediate_data_ex_out_buffer;
    register_reference_next_stage <= register_reference_next_stage_buffer;

end;