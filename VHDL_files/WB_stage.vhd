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
        --mux control
        mem_to_reg : in std_logic
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
            --instead of having a mux component, do the mux functionality here
            if (mem_to_reg == '0') then
                immediate_data_wb <= alu_input;
            elsif (mem_to_reg == '1') then
                immediate_data_wb <= mem_input;
            else
                --set output to 32 X
                immediate_data_wb <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            end if;
        end if;
    end process;

    -- immediate_data_wb <= immediate_data_wb_buffer;
    register_reference_wb <= register_reference_wb_buffer;
    write_register <= write_register_buffer;

end;