--
-- Copyright (C) 2013 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	port (
		-- 16MHz pixel clock from BBC Micro
		sysClk_in : in  std_logic;

		-- Input 15.625kHz RGB signals
		rgbi_in   : in  std_logic_vector(3 downto 0);
		hSync_in  : in  std_logic;
		vSync_in  : in  std_logic;
		
		-- Output 31.250kHz VGA signals
		rgbi_out  : out std_logic_vector(3 downto 0);
		hSync_out : out std_logic;
		vSync_out : out std_logic
	);
end entity;

architecture rtl of top_level is
	-- Config parameters
	constant SAMPLE_OFFSET : integer := 248;
	constant SAMPLE_WIDTH  : integer := 656;
	constant HORIZ_RT      : integer := 96;
	constant HORIZ_BP      : integer := 30;
	constant HORIZ_DISP    : integer := 656;
	constant HORIZ_FP      : integer := 18;

	-- VSYNC state-machine
	type VType is (
		S_WAIT_VSYNC,
		S_EXTRA1,
		S_EXTRA2,
		S_NOEXTRA,
		S_ASSERT_VSYNC
	);

	-- Clocks
	signal clk16           : std_logic;
	signal clk25           : std_logic;
	
	-- Registers in the 16MHz clock domain:
	signal state           : VType := S_WAIT_VSYNC;
	signal state_next      : VType;
	signal hSync_s16       : std_logic;
	signal vSync_s16       : std_logic;
	signal hSyncStart      : std_logic;
	signal vSyncStart      : std_logic;
	signal hCount16        : unsigned(9 downto 0) := (others => '0');
	signal hCount16_next   : unsigned(9 downto 0);
	signal lineToggle      : std_logic := '1';
	signal lineToggle_next : std_logic;

	-- Registers in the 25MHz clock domain:
	signal hSync_s25a      : std_logic;
	signal hSync_s25b      : std_logic;
	signal hCount25        : unsigned(9 downto 0) := to_unsigned(HORIZ_DISP + HORIZ_FP, 10);
	signal hCount25_next   : unsigned(9 downto 0);

	-- Signals on the write side of the RAMs:
	signal writeEn0        : std_logic;
	signal writeEn1        : std_logic;

	-- Signals on the read side of the RAMs:
	signal ram0Data        : std_logic_vector(3 downto 0);
	signal ram1Data        : std_logic_vector(3 downto 0);
begin
	-- Generate 16MHz and 25MHz clocks
	clk_gen: entity work.clk_gen
		port map(
			inclk0 => sysClk_in,
			c0 => clk16,
			c1 => clk25
		);

	-- Two RAM blocks, each straddling the 16MHz and 25MHz clock domains, for storing pixel lines;
	-- whilst we're reading from one at 25MHz, we're writing to the other at 16MHz. Their roles
	-- swap every incoming 64us scanline.
	--
	ram0: entity work.dpram
		port map(
			-- Write port
			wrclock   => clk16,
			wraddress => std_logic_vector(hCount16),
			wren      => writeEn0,
			data      => rgbi_in,

			-- Read port
			rdclock   => clk25,
			rdaddress => std_logic_vector(hCount25),
			q         => ram0data
		);
	ram1: entity work.dpram
		port map(
			-- Write port
			wrclock   => clk16,
			wraddress => std_logic_vector(hCount16),
			wren      => writeEn1,
			data      => rgbi_in,

			-- Read port
			rdclock   => clk25,
			rdaddress => std_logic_vector(hCount25),
			q         => ram1data
		);

	-- 16MHz clock domain ---------------------------------------------------------------------------
	process(clk16)
	begin
		if ( rising_edge(clk16) ) then
			hSync_s16 <= hSync_in;
			vSync_s16 <= vSync_in;
			hCount16  <= hCount16_next;
			lineToggle <= lineToggle_next;
			state <= state_next;
		end if;
	end process;

	-- Pulses representing the start of incoming HSYNC & VSYNC
	hSyncStart <=
		'1' when hSync_s16 = '0' and hSync_in = '1'
		else '0';
	vSyncStart <=
		'1' when vSync_s16 = '0' and vSync_in = '1'
		else '0';

	-- Create horizontal count, aligned to incoming HSYNC
	hCount16_next <=
		to_unsigned(2**10 - SAMPLE_OFFSET + 1, 10) when hSyncStart = '1'
		else hCount16 + 1;

	-- Toggle every incoming HSYNC
	lineToggle_next <=
		not(lineToggle) when hSyncStart = '1'
		else lineToggle;

	-- Generate interleaved write signals for dual-port RAMs
	writeEn0 <=
		'1' when hCount16 < SAMPLE_WIDTH and lineToggle = '0'
		else '0';
	writeEn1 <=
		'1' when hCount16 < SAMPLE_WIDTH and lineToggle = '1'
		else '0';

	-- Interleave output of dual-port RAMs
	rgbi_out <=
		ram0Data when lineToggle = '1'
		else ram1Data;
		
	-- State machine to generate VGA VSYNC
	process(state, vSyncStart, hSyncStart, hCount16(9))
	begin
		state_next <= state;
		case state is
			-- Wait for VSYNC start
			when S_WAIT_VSYNC =>
				vSync_out <= '1';
				if ( vSyncStart = '1' ) then
					if ( hCount16(9) = '0' ) then
						state_next <= S_EXTRA1;
					else
						state_next <= S_NOEXTRA;
					end if;
				end if;

			-- Insert an extra 64us scanline
			when S_EXTRA1 =>
				vSync_out <= '1';
				if ( hSyncStart = '1' ) then
					state_next <= S_EXTRA2;  -- 0.5 lines after VSYNC
				end if;
			when S_EXTRA2 =>
				vSync_out <= '1';
				if ( hSyncStart = '1' ) then
					state_next <= S_ASSERT_VSYNC;  -- 1.5 lines after VSYNC
				end if;

			-- Don't insert an extra 64us scanline
			when S_NOEXTRA =>
				vSync_out <= '1';
				if ( hSyncStart = '1' ) then
					state_next <= S_ASSERT_VSYNC;  -- 0.5 lines after VSYNC
				end if;

			-- Assert VGA VSYNC for 64us
			when S_ASSERT_VSYNC =>
				vSync_out <= '0';
				if ( hSyncStart = '1' ) then
					state_next <= S_WAIT_VSYNC;
				end if;
		end case;
	end process;

	-- 25MHz clock domain ---------------------------------------------------------------------------
	process(clk25)
	begin
		if ( rising_edge(clk25) ) then
			hCount25  <= hCount25_next;
			hSync_s25a <= hSync_in;
			hSync_s25b <= hSync_s25a;
		end if;
	end process;

	-- Generate 25MHz hCount
	hCount25_next <=
		to_unsigned(2**10 - HORIZ_RT - HORIZ_BP, 10) when
			(hSync_s25a = '1' and hSync_s25b = '0') or
			(hCount25 = HORIZ_DISP + HORIZ_FP - 1)
		else hCount25 + 1;

	-- Generate VGA HSYNC
	hSync_out <=
		'0' when hCount25 >= to_unsigned(2**10 - HORIZ_RT - HORIZ_BP, 10) and hCount25 < to_unsigned(2**10 - HORIZ_BP, 10)
		else '1';

end architecture;
