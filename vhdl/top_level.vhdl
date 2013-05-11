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
		hSync_in  : in  std_logic;
		vSync_in  : in  std_logic;
		rgb_in    : in  std_logic_vector(2 downto 0);

		-- Output to 31.250kHz VGA monitor
		hSync_out : out std_logic;
		vSync_out : out std_logic;
		rgb_out   : out std_logic_vector(2 downto 0)
	);
end entity;

architecture rtl of top_level is
	signal pixClk      : std_logic := '0';      -- 25MHz pixel clock
	signal hSync_s0    : std_logic := '0';      -- hSync_in, synchronized to 25MHz clock
	signal hSync_s1    : std_logic := '0';      -- hSync_s0, synchronized again
	signal hCount      : unsigned(10 downto 0) := (others => '0');
	signal hCount_next : unsigned(10 downto 0);
	signal vSync_s0    : std_logic := '0';      -- hSync_in, synchronized to 25MHz clock
	signal vSync_s1    : std_logic := '0';      -- hSync_s0, synchronized again
	signal vCount      : unsigned(10 downto 0) := (others => '0');
	signal vCount_next : unsigned(10 downto 0);
	constant ORIGIN    : unsigned(10 downto 0) := (others => '0');
	constant HSHIFT    : integer := 224;
begin
	-- Generate the 25MHz pixel clock from the input clock
	clk_gen: entity work.clk_gen
		port map(
			inclk0 => sysClk_in,
			c0     => pixClk,
			locked => open
		);

	-- Create horizontal and vertical counts, aligned to incoming hSync and vSync
	hCount_next <=
		ORIGIN when hSync_s0 = '1' and hSync_s1 = '0'
		else hCount + 1;
	vCount_next <=
		ORIGIN when vSync_s0 = '1' and vSync_s1 = '0' else
		vCount + 1 when hCount = 0 else
		vCount;

	-- Generate VGA hSync and vSync
	hSync_out <=
		'0' when (hCount >= HSHIFT and hCount < HSHIFT+96) or (hCount >= HSHIFT+800 and hCount < HSHIFT+896)
		else '1';
	vSync_out <=
		'0' when vCount < 2
		else '1';

	-- Synchronize incoming hSync & vSync to the 25MHz pixClk
	process(pixClk)
	begin
		if ( rising_edge(pixClk) ) then
			hSync_s0 <= hSync_in;
			hSync_s1 <= hSync_s0;
			vSync_s0 <= vSync_in;
			vSync_s1 <= vSync_s0;
			hCount <= hCount_next;
			vCount <= vCount_next;
		end if;
	end process;
	
	-- Just pipe the incoming RGB data back out
	rgb_out <= rgb_in;

end architecture;
