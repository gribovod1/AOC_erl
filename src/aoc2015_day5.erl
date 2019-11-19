-module(aoc2015_day5).
-author("Gribovod").
-export([nice_count/0]).

count_vowels([H | T]) ->
  case lists:member(H, "aeiou") of
    false -> count_vowels(T);
    true -> 1 + count_vowels(T)
  end;
count_vowels([]) -> 0.

verify_double_char([A, B | T]) -> A == B orelse verify_double_char([B | T]);
verify_double_char([_ | []]) -> false;
verify_double_char([]) -> false.

verify_bad_string_ab(List) ->
  string:find(List, "ab") == nomatch andalso
    string:find(List, "cd") == nomatch andalso
    string:find(List, "pq") == nomatch andalso
    string:find(List, "xy") == nomatch.

is_nice(List) ->
  case verify_bad_string_ab(List) andalso verify_double_char(List) andalso count_vowels(List) >= 3 of
    false -> 0;
    true -> 1
  end.

counter([H | T]) ->
  is_nice(H) + counter(T);
counter([]) -> 0.

nice_count() ->
  {ok, Data} = file:read_file("data_day5"),
  io:format("Nice count: ~w~n",[counter(string:split(binary_to_list(Data), [13, 10], all))]).