%%%-------------------------------------------------------------------
%%% @author Gribovod
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. нояб. 2019 12:12
%%%-------------------------------------------------------------------
-module(aoc2015_day3_1).
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

count(Coords, CurrCoord, <<B:8, Data/binary>>) ->
  Coord = coord(B, CurrCoord),
  case dict:is_key(Coord, Coords) of
    true -> count(Coords, Coord, Data);
    false -> 1 + count(dict:store(Coord, 1, Coords), Coord, Data)
  end;
count(_, _, <<>>) ->
  0.

start()  ->
  {ok, Data} = file:read_file("data_day3"),
  C = dict:store({0, 0}, 1, dict:new()),
  io:format("House count: ~w~n",[count(C, {0, 0}, Data) + 1]).

