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
use ieee.std_logic_textio.all;
use std.textio.all;
use work.hex_util.all;

entity top_level_tb is
end entity;

architecture behavioural of top_level_tb is
	signal sysClk    : std_logic;

	-- 16MHz RGBI clock domain
	signal disp16   : std_logic;
	signal hSyncIn  : std_logic;
	signal vSyncIn  : std_logic;
	signal rgbiIn   : std_logic_vector(3 downto 0);

	-- 25MHz VGA clock domain
	signal disp25   : std_logic;
	signal hSyncOut : std_logic;
	signal vSyncOut : std_logic;
	signal rgbiOut  : std_logic_vector(3 downto 0);
begin
	uut: entity work.top_level
		port map(
			-- 16MHz RGBI clock domain
			sysClk_in => sysClk,
			hSync_in  => hSyncIn,
			vSync_in  => vSyncIn,
			rgbi_in   => rgbiIn,

			-- 25MHz RGBI clock domain
			hSync_out => hSyncOut,
			vSync_out => vSyncOut,
			rgbi_out  => rgbiOut
		);

	process
	begin
		sysClk <= '0';
		loop
			wait for 31.25 ns;
			sysClk <= not(sysClk);
		end loop;
	end process;

	process
		alias clk16 is <<signal uut.clk16 : std_logic>>;
	begin
		disp16 <= '0';
		loop
			wait until clk16'event;
			wait for 21.25 ns;
			disp16 <= not(clk16);
		end loop;
	end process;
	
	process
		alias clk25 is <<signal uut.clk25 : std_logic>>;
	begin
		disp25 <= '0';
		loop
			wait until clk25'event;
			wait for 10 ns;
			disp25 <= not(clk25);
		end loop;
	end process;
	
	-- Drive the unit under test. Read stimulus from stimulus.sim and write results to results.sim
	process
		alias clk16 is <<signal uut.clk16 : std_logic>>;
		variable inLine : line;
		file inFile     : text open read_mode is "stimulus.sim";
	begin
		hSyncIn <= '0';
		vSyncIn <= '0';
		rgbiIn  <= "0000";
		while ( not endfile(inFile) ) loop
			readline(inFile, inLine);
			while ( inLine.all'length = 0 or inLine.all(1) = '#' or inLine.all(1) = ht or inLine.all(1) = ' ' ) loop
				readline(inFile, inLine);
			end loop;
			wait until rising_edge(clk16);
			rgbiIn <= to_4(inLine.all(1));
			hSyncIn <= to_1(inLine.all(3));
			vSyncIn <= to_1(inLine.all(5));
		end loop;
		hSyncIn <= '0';
		vSyncIn <= '0';
		rgbiIn  <= "0000";
		wait;
	end process;

	-- Drive the unit under test. Read stimulus from stimulus.sim and write results to results.sim
	process
		alias clk25 is <<signal uut.clk25 : std_logic>>;
		variable outLine : line;
		file outFile     : text open write_mode is "results.sim";
	begin
		loop
			wait until rising_edge(clk25);
			write(outLine, from_4(rgbiOut));
			write(outLine, ' ');
			write(outLine, hSyncOut);
			write(outLine, ' ');
			write(outLine, vSyncOut);
			writeline(outFile, outLine);
		end loop;
	end process;

end architecture;
