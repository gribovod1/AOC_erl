-module(aoc2015_day3_2).
-author("Gribovod").

%% API
-export([start/0]).

coord(B, {CurrX, CurrY}) ->
  case B of
    60 -> {CurrX - 1, CurrY};
    62 -> {CurrX + 1, CurrY};
    94 -> {CurrX, CurrY + 1};
    118 -> {CurrX, CurrY - 1};
    _   -> {CurrX, CurrY}
  end.

count_santa(Coords, SantaCoord, RoboCoord, <<B:8, Data/binary>>) ->
  Coord = coord(B, RoboCoord),
  case dict:is_key(Coord, Coords) of
    true -> count_robo(Coords, SantaCoord, Coord, Data);
    false -> 1 + count_robo(dict:store(Coord, 1, Coords), SantaCoord, Coord, Data)
  end;
count_santa(_, _, _, <<>>) ->
  0.

count_robo(Coords, SantaCoord, RoboCoord, <<B:8, Data/binary>>) ->
  Coord = coord(B, SantaCoord),
  case dict:is_key(Coord, Coords) of
    true -> count_santa(Coords, Coord, RoboCoord, Data);
    false -> 1 + count_santa(dict:store(Coord, 1, Coords), Coord, RoboCoord, Data)
  end;
count_robo(_, _, _, <<>>) ->
  0.

start()  ->
  {ok, Data} = file:read_file("data_day3"),
  C = dict:store({0, 0}, 1, dict:new()),
  io:format("House count: ~w~n",[count_santa(C, {0, 0}, {0, 0}, Data) + 1]).

