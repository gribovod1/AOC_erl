-module(day8).
-author("Gribovod").
-export([parse/0]).

parse() ->
  {ok, Data} = file:read_file("data_day8"),
  io:format("Summary part one, part two: ~p~n",[char_count(string:split(binary_to_list(Data), [13, 10], all), 0, 0)]).

char_count([Line | Lines], Acc1, Acc2) ->
  Length = string:length(Line),
  {ClearlyLine, CodedLine} = parse_line(Line, Length - 2, Length + 4),
  char_count(Lines, Acc1 + Length - ClearlyLine, Acc2 + CodedLine - Length);
char_count([], Acc1, Acc2) -> {Acc1, Acc2}.

parse_line([C, X | L], Acc1, Acc2) when C == 92, X == 92 -> parse_line(L, Acc1 - 1, Acc2 + 2);
parse_line([C, X | L], Acc1, Acc2) when C == 92, X == 34 -> parse_line(L, Acc1 - 1, Acc2 + 2);
parse_line([C, X, _, _ | L], Acc1, Acc2) when C == 92, X == 120 -> parse_line(L, Acc1 - 3, Acc2 + 1);
parse_line([_ | L], Acc1, Acc2) -> parse_line(L, Acc1, Acc2);
parse_line([], Acc1, Acc2) -> {Acc1, Acc2}.