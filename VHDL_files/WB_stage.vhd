library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WB_stage is
    port (
        clock : in std_logic;
        --instruction to execute currently
        current_instruction : in std_logic_vector(5 downto 0);
        
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        --data to be written back to register, built in mux, no need for mux component
        --input of alu
        alu_input : in std_logic_vector(31 downto 0);
        --input of meme
        mem_input : in std_logic_vector(31 downto 0);
        ------------------------------------------------------------------------------
        --data to be written back to register
        immediate_data_wb : out std_logic_vector(31 downto 0);
        --register reference of current instruction to writeback
        register_reference_wb : out std_logic_vector (4 downto 0);
        --indicate that register value should be overwritten
        write_register : out std_logic
    );
end WB_stage;

architecture behavior of WB_stage is
    signal immediate_data_wb_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
    signal register_reference_wb_buffer : std_logic_vector(4 downto 0) := (others => '0');--TODO initialize to stall
    signal write_register_buffer : std_logic := '0';--TODO initialize to stall
begin
    WB_logic_process : process (clock)
    begin
        if (rising_edge(clock)) then
            register_reference_wb_buffer <= register_reference_current;
            -- immediate_data_wb_buffer <= immediate_data_mem_in;
            -- TODO logic for the WB stage. Write the values for the next stage on the buffer signals.
            -- Because signal values are only updated at the end of the process, those values will be available to ID on the next clock cycle only
            --instead of having a mux component, do the mux functionality here depending on the current opcode
            --functions that do not write from mem to register, branch and jumps not included
            if (current_instruction = "100000") or (current_instruction = "100010") or (current_instruction = "001000") or (current_instruction = "011000") or (current_instruction = "011010") or (current_instruction = "101010") or 
            (current_instruction = "001010") or (current_instruction = "100100") or (current_instruction = "100101") or (current_instruction = "100111") or (current_instruction = "101000") or (current_instruction = "001100") or 
            (current_instruction = "001101") or (current_instruction = "001110") or (current_instruction = "010000") or (current_instruction = "010010") or (current_instruction = "001111") or (current_instruction = "000000") or
            (current_instruction = "000010") or (current_instruction = "000011")
            then
                immediate_data_wb_buffer <= alu_input;
            --lw and sw write from mem to register
            elsif (current_instruction = "100011") or (current_instruction = "101011") then
                immediate_data_wb_buffer <= mem_input;
            else
                --set output to 32 X
                immediate_data_wb_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            end if;
        end if;
    end process;

    immediate_data_wb <= immediate_data_wb_buffer;
    register_reference_wb <= register_reference_wb_buffer;
    write_register <= write_register_buffer;

end;