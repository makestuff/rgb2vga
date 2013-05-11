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
	signal clk16         : std_logic := '0';      -- 16MHz input pixel clock
	signal clk25         : std_logic := '0';      -- 25MHz output pixel clock
	signal hSync_s16     : std_logic := '0';      -- hSync_in, registered with 16MHz clock
	signal hSync_s25a    : std_logic := '0';      -- hSync_in, synchronized to 25MHz clock
	signal hSync_s25b    : std_logic := '0';      -- hSync_s25a, synchronized again
	signal hCount16      : unsigned(9 downto 0) := (others => '0');
	signal hCount16_next : unsigned(9 downto 0);
	signal hCount25a     : unsigned(10 downto 0) := (others => '0');
	signal hCount25b     : unsigned(10 downto 0) := (others => '0');
	signal hCount25_next : unsigned(10 downto 0);
	signal vSync_s25a    : std_logic := '0';      -- hSync_in, synchronized to 25MHz clock
	signal vSync_s25b    : std_logic := '0';      -- hSync_s25a, synchronized again
	signal vCount        : unsigned(10 downto 0) := (others => '0');
	signal vCount_next   : unsigned(10 downto 0);
	signal ram0wren      : std_logic := '0';
	signal ram1wren      : std_logic := '0';
	signal ram0data      : std_logic_vector(3 downto 0) := "0000";
	signal ram1data      : std_logic_vector(3 downto 0) := "0000";
	constant ORIGIN      : unsigned(10 downto 0) := (others => '0');
	constant HSHIFT      : integer := 0;
begin
	-- Generate the 25MHz pixel clock from the input clock
	clk_gen: entity work.clk_gen
		port map(
			inclk0 => sysClk_in,
			c0     => clk16,
			c1     => clk25
		);

	-- Two RAM blocks for storing pixel lines (read from one, write to other, then swap every 64us)
	ram0: entity work.dpram
		port map(
			-- Write port
			data      => "0" & rgb_in,
			wraddress => std_logic_vector(hCount16),
			wrclock   => clk16,
			wren      => ram0wren,

			-- Read port
			rdaddress => std_logic_vector(hCount25b(9 downto 0)),
			rdclock   => clk25,
			q         => ram0data
		);
	ram1: entity work.dpram
		port map(
			-- Write port
			data      => "0" & rgb_in,
			wraddress => std_logic_vector(hCount16),
			wrclock   => clk16,
			wren      => ram1wren,

			-- Read port
			rdaddress => std_logic_vector(hCount25b(9 downto 0)),
			rdclock   => clk25,
			q         => ram1data
		);

	ram0wren <= std_logic(vCount(1));
	ram1wren <= not(ram0wren);
	
	-- Create horizontal and vertical counts, aligned to incoming hSync and vSync
	hCount16_next <=
		(others => '0') when hSync_in = '1' and hSync_s16 = '0'
		else hCount16 + 1;
	hCount25_next <=
		ORIGIN-HSHIFT when hSync_s25a = '1' and hSync_s25b = '0'
		else hCount25a + 1;
	hCount25b <=
		hCount25a when hCount25a < 800
		else hCount25a - 800;
	vCount_next <=
		ORIGIN when vSync_s25a = '1' and vSync_s25b = '0' else
		vCount + 1 when hCount25b = 0 else
		vCount;

	-- Generate VGA hSync and vSync
	hSync_out <=
		'0' when hCount25b < 96
		else '1';
	vSync_out <=
		'0' when vCount < 2
		else '1';

	-- Synchronize incoming hSync & vSync to the 25MHz clock
	process(clk25)
	begin
		if ( rising_edge(clk25) ) then
			hSync_s25a <= hSync_in;
			hSync_s25b <= hSync_s25a;
			vSync_s25a <= vSync_in;
			vSync_s25b <= vSync_s25a;
			hCount25a  <= hCount25_next;
			vCount     <= vCount_next;
		end if;
	end process;

	process(clk16)
	begin
		if ( rising_edge(clk16) ) then
			hSync_s16 <= hSync_in;
			hCount16  <= hCount16_next;
		end if;
	end process;
	
	-- Just pipe the incoming RGB data back out
	rgb_out <=
		ram0data(2 downto 0) when ram1wren = '1' else
		ram1data(2 downto 0);

end architecture;
