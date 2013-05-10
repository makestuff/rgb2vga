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

entity vga_sync_tb is
end entity;

architecture behavioural of vga_sync_tb is
	signal sysClk  : std_logic;
	signal dispClk : std_logic;  -- display version of sysClk, which leads it by 4ns
	signal hSync   : std_logic;
	signal vSync   : std_logic;
	signal pixX    : unsigned(4 downto 0);  -- current pixel's X coordinate
	signal pixY    : unsigned(4 downto 0);  -- current pixel's Y coordinate
	signal display : std_logic;
	constant HRES  : integer := 16;        -- horizontal resolution
	constant VRES  : integer := 16;        -- vertical resolution
begin
	-- Instantiate vga_sync for testing
	uut: entity work.vga_sync
		generic map (
			-- Horizontal parameters (numbers are pixClk counts)
			HORIZ_DISP => HRES,
			HORIZ_FP   => 4,
			HORIZ_RT   => 2,
			HORIZ_BP   => 4,

			-- Vertical parameters (in line counts)
			VERT_DISP  => VRES,
			VERT_FP    => 4,
			VERT_RT    => 2,
			VERT_BP    => 4,

			-- Coordinate bit-width
			COORD_WIDTH => 5
		)
		port map(
			clk_in     => sysClk,
			reset_in   => '0',
			hSync_out  => hSync,
			vSync_out  => vSync,
			pixX_out   => pixX,
			pixY_out   => pixY
		);

	-- Drive high when in active screen area
	display <=
		'1' when pixX < HRES and pixY < VRES
		else '0';
	
	-- Drive the clocks. In simulation, sysClk lags 4ns behind dispClk, to give a visual hold time for
	-- signals in GTKWave.
	process
	begin
		sysClk <= '0';
		dispClk <= '1';
		wait for 10 ns;
		dispClk <= '0';
		wait for 10 ns;		
		loop
			dispClk <= '1';
			wait for 4 ns;
			sysClk <= '1';
			wait for 6 ns;
			dispClk <= '0';
			wait for 4 ns;
			sysClk <= '0';
			wait for 6 ns;
		end loop;
	end process;
end architecture;
