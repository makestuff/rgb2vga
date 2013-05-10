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

entity clk_gen_wrapper is
	port(
		clk_in     : in  std_logic;
		clk_out    : out std_logic;
		locked_out : out std_logic
	);
end entity;

architecture structural of clk_gen_wrapper is
begin
	clk_gen : entity work.clk_gen
		port map(
			inclk0 => clk_in,
			c0     => clk_out,
			locked => locked_out
		);
end architecture;
