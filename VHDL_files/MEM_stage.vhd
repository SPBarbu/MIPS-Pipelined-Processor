library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--TAKEN FROM GIVEN CODE FOR MEMORY of CACHE, added file io for mem
use STD.textio.all;
use ieee.std_logic_textio.all;

entity MEM_stage is
    generic (
        ram_size : integer := 8192; -- 8192 lines of 32 bit words
        mem_delay : time := 0.5 ns;
        clock_period : time := 1 ns
    );
    port (
        clock : in std_logic;
        --instruction to execute currently
        current_instruction : in std_logic_vector(5 downto 0);
        --address for memory or data to be written back to register
        immediate_data_mem_in : in std_logic_vector(31 downto 0);
        --for store value
        immediate_data_mem_in_2 : in std_logic_vector(31 downto 0);
        --register reference of current instruction forwarded for writeback
        register_reference_current : in std_logic_vector (4 downto 0);
        ------------------------------------------------------------------------------
        --opcode of the current instruction forwarded to the next stage
        instruction_next_stage : out std_logic_vector(5 downto 0);
        --data to be written back to register
        immediate_data_mem_out : out std_logic_vector(31 downto 0);
        --register reference of current instruction to forward for writeback
        register_reference_next_stage : out std_logic_vector (4 downto 0);
        --for writing back to txt file
        memwritetotext : in std_logic
    );
end MEM_stage;

architecture behavior of MEM_stage is

    signal instruction_next_stage_buffer : std_logic_vector(5 downto 0) := (others => '0');--TODO initialize to stall
    signal immediate_data_mem_out_buffer : std_logic_vector(31 downto 0) := (others => '0');--TODO initialize to stall
    signal register_reference_next_stage_buffer : std_logic_vector (4 downto 0) := (others => '0');--TODO initialize to stall

    --signals for memory
    type MEM is array(ram_size - 1 downto 0) of std_logic_vector(31 downto 0);
    signal ram_block : MEM;

begin

    -- MEM_logic_process : process (clock)
    -- begin
    --     if (rising_edge(clock)) then
    --         --propagate unchanged values to next stage
    --         instruction_next_stage_buffer <= current_instruction;
    --         register_reference_next_stage_buffer <= register_reference_current;
    --         -- TODO logic for the MEM stage. Write the values for the next stage on the buffer signals.
    --         -- Because signal values are only updated at the end of the process, those values will be available to WB on the next clock cycle only
    --         if (current_instruction = "100000") or (current_instruction = "100010") or (current_instruction = "001000") or (current_instruction = "011000") or (current_instruction = "011010") or (current_instruction = "101010") or 
    --         (current_instruction = "001010") or (current_instruction = "100100") or (current_instruction = "100101") or (current_instruction = "100111") or (current_instruction = "101000") or (current_instruction = "001100") or 
    --         (current_instruction = "001101") or (current_instruction = "001110") or (current_instruction = "010000") or (current_instruction = "010010") or (current_instruction = "001111") or (current_instruction = "000000") or
    --         (current_instruction = "000010") or (current_instruction = "000011")
    --         then
    --             immediate_data_mem_out_buffer <= immediate_data_mem_in;
    --         --lw and sw write from mem to register
    --         elsif (current_instruction = "100011") or (current_instruction = "101011") then
    --             immediate_data_mem_out_buffer <= mem_input;
    --         else
    --             --set output to 32 X
    --             immediate_data_wb_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    --         end if;
    --     end if;
    -- end process;

    --This is the main section of the SRAM model
    mem_process : process (clock)
    begin
        --This is a cheap trick to initialize the SRAM in simulation
        if (now < 1 ps) then
            for i in 0 to ram_size - 1 loop
                ram_block(i) <= std_logic_vector(to_unsigned(0, 32));
            end loop;
        end if;

        --This is the actual synthesizable SRAM block
        if (clock'event and clock = '1') then
            --propagate unchanged values to next stage
            instruction_next_stage_buffer <= current_instruction;
            register_reference_next_stage_buffer <= register_reference_current;
            --not mem operation, just pass alu output
            if (current_instruction = "100000") or (current_instruction = "100010") or (current_instruction = "001000") or (current_instruction = "011000") or (current_instruction = "011010") or (current_instruction = "101010") or
                (current_instruction = "001010") or (current_instruction = "100100") or (current_instruction = "100101") or (current_instruction = "100111") or (current_instruction = "101000") or (current_instruction = "001100") or
                (current_instruction = "001101") or (current_instruction = "001110") or (current_instruction = "010000") or (current_instruction = "010010") or (current_instruction = "001111") or (current_instruction = "000000") or
                (current_instruction = "000010") or (current_instruction = "000011")
                then
                immediate_data_mem_out_buffer <= immediate_data_mem_in;
                --sw 
            elsif (current_instruction = "100011") then
                ram_block(to_integer(unsigned(immediate_data_mem_in))) <= immediate_data_mem_in_2;
                --lw
            elsif (current_instruction = "101011") then
                immediate_data_mem_out_buffer <= ram_block(to_integer(unsigned(immediate_data_mem_in)));
            else
                --set output to 32 X
                immediate_data_mem_out_buffer <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            end if;
        end if;
    end process;

    --process for writing back to text file
    writetotext_process : process (memwritetotext)
        variable row : line;
        --for write back to file
        file text_file : text open write_mode is "memory.txt";
    begin
        if (memwritetotext = '1') then
            --iterate for every ram block 
            for I in 0 to 8191 loop
                --write the contents of the row at I to the line variable
                write(row, ram_block(I));
                --write the line to the text file
                writeline(text_file, row);
            end loop;
            file_close(text_file);
        end if;
    end process;

    instruction_next_stage <= instruction_next_stage_buffer;
    immediate_data_mem_out <= immediate_data_mem_out_buffer;
    register_reference_next_stage <= register_reference_next_stage_buffer;

end;