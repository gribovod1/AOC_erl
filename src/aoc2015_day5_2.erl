-module(aoc2015_day5_2).
-author("Gribovod").
-export([nice_count/0]).

find_double(Char1, Char2, [H1, H2 | _]) when H1 == Char1, H2 == Char2 -> true;
find_double(Char1, Char2, [_, H2 | T]) -> find_double(Char1, Char2, [H2 | T]);
find_double(_, _, [_ | []]) -> false;
find_double(_, _, []) -> false.

verify_2char([H1, H2 | T]) ->
  case find_double(H1, H2, T) of
    false -> verify_2char([H2 | T]);
    true -> true
  end;
verify_2char([_ | []]) -> false;
verify_2char([]) -> false.

char_eye([H1, _, H3 | _]) when H1 == H3-> true;
char_eye([_, H2, H3 | T]) -> char_eye([H2 | [H3 | T]]);
char_eye([_, _ | []]) -> false;
char_eye([_ | []]) -> false;
char_eye([]) -> false.

is_nice(List, Num) ->
  case verify_2char(List) andalso char_eye(List) of
    false -> 0;
    true -> io:format("Nice: ~w~n",[Num]), 1
  end.

counter([H | T], Num) ->
  is_nice(H, Num) + counter(T, Num + 1);
counter([], _) -> 0.

nice_count() ->
  {ok, Data} = file:read_file("data_day5"),
  io:format("Nice count: ~w~n",[counter(string:split(binary_to_list(Data), [13, 10], all), 0)]).