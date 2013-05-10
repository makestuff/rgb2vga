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
		sysClk_in : in  std_logic;
		hSync_out : out std_logic;
		vSync_out : out std_logic;
		rgb_in    : in  std_logic_vector(2 downto 0);
		rgb_out   : out std_logic_vector(2 downto 0)
	);
end entity;

architecture rtl of top_level is
	signal locked   : std_logic;             -- goes high when pixClk DLL locks
	signal reset    : std_logic;             -- remains high until pixClk DLL locks
	signal pixClk   : std_logic := '0';      -- 25MHz pixel clock
	signal pixX     : unsigned(9 downto 0);  -- current pixel's X coordinate
	signal pixY     : unsigned(9 downto 0);  -- current pixel's Y coordinate
	constant HRES   : integer := 640;        -- horizontal resolution
	--constant VRES   : integer := 480;        -- vertical resolution
	constant VRES   : integer := 512;
begin
	-- Instantiate VGA sync circuit, driven with the 25MHz pixel clock
	vga_sync: entity work.vga_sync
		generic map (
			-- Horizontal parameters (numbers are pixClk counts)
			HORIZ_DISP => HRES,
			HORIZ_FP   => 16,
			HORIZ_RT   => 96,
			HORIZ_BP   => 48,

			-- Vertical parameters (in line counts)
			VERT_DISP  => VRES,
			--VERT_FP    => 10,  -- 640x480 @ 60Hz
			--VERT_RT    => 2,
			--VERT_BP    => 29
			VERT_FP    => 45,  -- 640x512 @ 50Hz
			VERT_RT    => 2,
			VERT_BP    => 66
		)
		port map(
			clk_in     => pixClk,
			reset_in   => reset,
			hSync_out  => hSync_out,
			vSync_out  => vSync_out,
			pixX_out   => pixX,
			pixY_out   => pixY
		);

	-- Generate the 25MHz pixel clock from the input clock
	clk_gen: entity work.clk_gen_wrapper
		port map(
			clk_in     => sysClk_in,
			clk_out    => pixClk,
			locked_out => locked
		);

	-- We're in reset until the DLL locks on
	reset <= not(locked);

	-- Set the visible area to eight vertical colour bars
	rgb_out <= rgb_in;
		--"100" when pixX >= 3*HRES/8 and pixX < 4*HRES/8 and pixY < VRES else  -- 4: blue
		--"011" when pixX >= 2*HRES/8 and pixX < 3*HRES/8 and pixY < VRES else  -- 3: yellow
		--"010" when pixX >= 1*HRES/8 and pixX < 2*HRES/8 and pixY < VRES else  -- 2: green
		--"001" when pixX >= 0*HRES/8 and pixX < 1*HRES/8 and pixY < VRES else  -- 1: red
		--"111" when pixX >= 7*HRES/8 and pixX < 8*HRES/8 and pixY < VRES else  -- 8: white
		--"110" when pixX >= 6*HRES/8 and pixX < 7*HRES/8 and pixY < VRES else  -- 7: cyan
		--"101" when pixX >= 5*HRES/8 and pixX < 6*HRES/8 and pixY < VRES else  -- 6: magenta
		--"000";                                                                -- 5: black
end architecture;
