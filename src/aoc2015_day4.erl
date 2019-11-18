-module(aoc2015_day4).
-author("Shilin").

%% API
-export([santacoin/0]).

% md5_hex отсюда: http://sacharya.com/md5-in-erlang/
md5_hex(S) ->
  Md5_bin =  erlang:md5(S),
  Md5_list = binary_to_list(Md5_bin),
  lists:flatten(list_to_hex(Md5_list)).

list_to_hex(L) ->
  lists:map(fun(X) -> int_to_hex(X) end, L).

int_to_hex(N) when N < 256 ->
  [hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
  $0+N;
hex(N) when N >= 10, N < 16 ->
  $a + (N-10).

zero_count([B | Data]) ->
  if
    B == 48 -> 1 + zero_count(Data);
    true -> 0
  end;
zero_count([]) -> 0.

calc(false, Msg, Curr) ->
  calc(zero_count(md5_hex([Msg | integer_to_list(Curr + 1)])) >= 6, Msg, Curr + 1);
calc(true, _, Curr) -> Curr.

santacoin() ->
  Msg = "ckczppom",
  io:format("Hash: ~w~n",[calc(zero_count(md5_hex(Msg)) >= 6, Msg, 0)]).