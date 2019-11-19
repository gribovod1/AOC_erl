-module(day6_2).
-author("Gribovod").
-export([lights/0]).

lights() ->
  {ok, Data} = file:read_file("data_day6"),
  Commands = parse(string:split(binary_to_list(Data), [13, 10], all)),
  io:format("Lights are lit count: ~w~n",[counter(0, Commands)]).

% Считаем, сколько лампочек включено
counter(Num, Commands) when Num < 1000000 -> get_state(0, Num div 1000, Num rem 1000, Commands) + counter(Num + 1, Commands);
counter(_, _) -> 0.

% Прогоняем лампочку с заданными координатами через все команды и вернём 1 если включена или 0 если выключена
get_state(State, X, Y, [Command | Commands]) -> get_state(in_rect(State, X, Y, Command), X, Y, Commands);
get_state(State, _, _, []) -> State.

% Если координаты входят в прямоугольник команды, применяем её к состоянию
in_rect(State, X, Y, {Command, {StartX, StartY}, {EndX, EndY}}) when X >= StartX, Y >= StartY, X =< EndX, Y =< EndY -> apply_command(State, Command);
in_rect(State, _, _, _) -> State.

% Применить команду к текущему состоянию лампочки
apply_command(State, none) -> State;
apply_command(State, on) -> State + 1;
apply_command(State, off) -> max(State - 1, 0);
apply_command(State, toggle) -> State + 2.

% Преобразуем команды в виде текста в кортежи с нормальными значениями
parse([Command | Commands]) -> [command_tuple(string:split(Command, " ", all)) | parse(Commands)];
parse([]) -> [].

command_tuple(["toggle", StartCoords, "through", EndCoords]) -> {toggle, coords(StartCoords), coords(EndCoords)};
command_tuple(["turn", "on", StartCoords, "through", EndCoords]) -> {on, coords(StartCoords), coords(EndCoords)};
command_tuple(["turn", "off", StartCoords, "through", EndCoords]) -> {off, coords(StartCoords), coords(EndCoords)};
command_tuple(_) -> {none, [], []}.

% Парсим координаты
coords(Coords) ->
  [XStr, YStr] = string:split(Coords, ",", all),
  {X, _} = string:to_integer(XStr),
  {Y, _} = string:to_integer(YStr),
  {X, Y}.