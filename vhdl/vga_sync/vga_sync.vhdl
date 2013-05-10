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

entity vga_sync is
	generic(
		-- Horizontal parameters (numbers are pixel clock counts)
		HORIZ_DISP  : integer := 640;  -- display area
		HORIZ_FP    : integer := 16;   -- front porch
		HORIZ_RT    : integer := 96;   -- beam retrace
		HORIZ_BP    : integer := 48;   -- back porch

		-- Vertical parameters (in line counts)
		VERT_DISP   : integer := 480;  -- display area
		VERT_FP     : integer := 10;   -- front porch
		VERT_RT     : integer := 2;    -- beam retrace
		VERT_BP     : integer := 29;   -- back porch

		-- Pixel coordinate bit-widths
		COORD_WIDTH : integer := 10
	);
	port(
		clk_in     : in std_logic;
		reset_in   : in std_logic;
		hSync_out  : out std_logic;
		vSync_out  : out std_logic;
		pixX_out   : out unsigned(COORD_WIDTH-1 downto 0) := (others => '0');
		pixY_out   : out unsigned(COORD_WIDTH-1 downto 0) := (others => '0')
	);
end vga_sync;

architecture arch of vga_sync is
	-- Line & pixel counters
	signal vCount      : unsigned(COORD_WIDTH-1 downto 0) := (others => '0');
	signal vCount_next : unsigned(COORD_WIDTH-1 downto 0);
	signal hCount      : unsigned(COORD_WIDTH-1 downto 0) := (others => '0');
	signal hCount_next : unsigned(COORD_WIDTH-1 downto 0);
	
	-- Registered horizontal & vertical sync signals
	signal vSync       : std_logic := '1';
	signal vSync_next  : std_logic;
	signal hSync       : std_logic := '1';
	signal hSync_next  : std_logic;
	
	-- End-of-line/screen flags
	signal hEnd        : std_logic;
	signal vEnd        : std_logic;
begin
	-- Registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				vCount <= (others => '0');
				hCount <= (others => '0');
				vSync <= '1';
				hSync <= '1';
			else
				vCount <= vCount_next;
				hCount <= hCount_next;
				vSync <= vSync_next;
				hSync <= hSync_next;
			end if;
		end if;
	end process;

	-- End-of-line flag
	hEnd <=
		'1' when hCount = HORIZ_DISP + HORIZ_FP + HORIZ_BP + HORIZ_RT - 1
		else '0';

	-- End-of-frame flag
	vEnd <=
		'1' when vCount = VERT_DISP + VERT_FP + VERT_BP + VERT_RT - 1
		else '0';

	-- Current pixel within the current line, 0-639 for 640x480@60Hz
	hCount_next <=
		hCount + 1 when hEnd = '0' else
		(others => '0');

	-- Current line within the current frame, 0-524 for 640x480@60Hz
	vCount_next <=
		(others => '0') when hEnd = '1' and vEnd = '1' else
		vCount + 1      when hEnd = '1' and vEnd = '0'
		else vCount;
	
	-- Registered horizontal and vertical syncs
	hSync_next <=
		'0' when hCount >= HORIZ_DISP + HORIZ_FP - 1 and hCount < HORIZ_DISP + HORIZ_FP + HORIZ_RT - 1
		else '1';
	vSync_next <=
		'0' when vCount = VERT_DISP + VERT_FP - 1 and hEnd = '1' else
		'1' when vCount = VERT_DISP + VERT_FP + VERT_RT - 1 and hEnd = '1' else
		vSync;
	
	-- Drive output signals
	hSync_out <= hSync;
	vSync_out <= vSync;
	pixX_out <= hCount;
	pixY_out <= vCount;
end arch;
