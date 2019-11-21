-module(day7).
-author("Gribovod").
-export([circuit/0, threadGate/1]).
-record(wire, {type = wire, name = [], value}).
-record(gate, {type = none, outWire, inWires = [], msgCount = 0, dict}).
-record(cmsg, {type = value, wire = [], value = 0}).

circuit() ->
  {ok, Data} = file:read_file("data_day7"),
  Dict = createGatesAndWire(dict:new(), parse(string:split(binary_to_list(Data), [13, 10], all))),
  send(Dict, #cmsg{type = dict, value = Dict}),
  command_process(Dict).

% Обработка команд пользователя
command_process(Dict) ->
  case string:strip(io:get_line("c> "), right, $\n) of
    eof -> 0;
    "exit" -> 0;
    "start" -> start(Dict), command_process(Dict);
    "circuit" -> io:format("Circuit: ~p~n", [Dict]), command_process(Dict);
    Data ->io:format("Out wire ~w value:", [Data]), command_process(out_wire_value(Dict, Data))
  end.

% Запуск схемы отправкой стартового сообщения
start(Circuit)-> send(Circuit, #cmsg{type = start}).

% Вывести значение провода с указанным именем
out_wire_value(Circuit, WireName) -> send(Circuit, #cmsg{type = out_value, value = WireName}), Circuit.

% Отправить сообщение всем вентилям
send(Dict, Msg) -> dict:fold(fun(_, Value, AccIn) -> send(Value, Msg, AccIn) end, 0, Dict).
send([Gate | Gates], Msg, Acc) when is_pid(Gate) -> send(Gates, Gate!Msg, Acc + 1);
send([_ | Gates], Msg, Acc) -> send(Gates, Msg, Acc);
send([], _, Acc) -> Acc.

% Создаём потоки для вентилей
createGatesAndWire(Dict, [Gate | Gates]) -> createGatesAndWire(registerGate(Dict, Gate#gate.inWires, spawn(?MODULE, threadGate, [Gate])), Gates);
createGatesAndWire(Dict, []) -> Dict.

% Регистрируем вентиль в записях всех входящих проводов и возвращаем новую таблицу
registerGate(Dict, [Wire | Wires], GatePid) ->%when Wire#wire.type == wire ->
  case dict:find(Wire#wire.name, Dict) of
    error -> registerGate(dict:store(Wire#wire.name, [GatePid], Dict), Wires, GatePid);
    {ok, _} -> registerGate(dict:append(Wire#wire.name, GatePid, Dict), Wires, GatePid)
  end;
registerGate(Dict, [], _) -> Dict.

% Приём входящих сообщений потока
threadGate(Gate) ->
  receive
    Msg -> threadGate(processMessage(Gate, Msg))
  end.

% Обработка входящих значений в зависимости от типа сообщения и вентиля
processMessage(Gate, Message) when Message#cmsg.type == dict -> Gate#gate{dict = Message#cmsg.value, msgCount = Gate#gate.msgCount + 1};

processMessage(Gate, Message) when Message#cmsg.type == out_value, Gate#gate.outWire#wire.name == Message#cmsg.value -> Gate#gate.outWire, io:format("msgs: ~p, value: ~p~n", [Gate#gate.msgCount, Gate#gate.outWire#wire.value]), Gate#gate{msgCount = Gate#gate.msgCount + 1};

processMessage(Gate, Message) when Message#cmsg.type == start, Gate#gate.type == gateWire ->
  [InWire] =  Gate#gate.inWires,
  GateNewState = Gate#gate{outWire = Gate#gate.outWire#wire{value = InWire#wire.value}, msgCount = Gate#gate.msgCount + 1},
  wireSend(Gate#gate.dict, GateNewState#gate.outWire),
  GateNewState;

processMessage(Gate, Message) when Message#cmsg.type == value, Gate#gate.type == gateWire ->
  GateNewState = Gate#gate{outWire = Gate#gate.outWire#wire{value = Message#cmsg.value}, msgCount = Gate#gate.msgCount + 1},
  wireSend(Gate#gate.dict, GateNewState#gate.outWire),
  GateNewState;

processMessage(Gate, Message) when Message#cmsg.type == value, Gate#gate.type == gateNot, Message#cmsg.value == undefined -> Gate#gate{outWire = Gate#gate.outWire#wire{value = undefined}, msgCount = Gate#gate.msgCount + 1};
processMessage(Gate, Message) when Message#cmsg.type == value, Gate#gate.type == gateNot ->
  GateNewState = Gate#gate{outWire = Gate#gate.outWire#wire{value = bnot Message#cmsg.value}, msgCount = Gate#gate.msgCount + 1},
  wireSend(Gate#gate.dict, GateNewState#gate.outWire),
  GateNewState;

processMessage(Gate, Message) when Message#cmsg.type == value, Message#cmsg.value == undefined -> Gate#gate{inWires = getWireValues(Gate, Message), msgCount = Gate#gate.msgCount + 1};
processMessage(Gate, Message) when Message#cmsg.type == value, is_list(Gate#gate.inWires) ->
  [Wire1, Wire2] = getWireValues(Gate, Message),
  GateNewState = Gate#gate{outWire = Gate#gate.outWire#wire{value = calc2Wires(Gate, Wire1, Wire2)}, inWires = [Wire1 , Wire2], msgCount = Gate#gate.msgCount + 1},
  wireSend(Gate#gate.dict, GateNewState#gate.outWire),
  GateNewState;
processMessage(Gate, _) -> Gate.

% Считать результат работы двухвходного вентиля в зависимости от его типа
calc2Wires(_, Wire1, Wire2) when Wire1#wire.value == undefined; Wire2#wire.value == undefined -> undefined;
calc2Wires(Gate, Wire1, Wire2) when Gate#gate.type == gateOr -> Wire1#wire.value bor Wire2#wire.value;
calc2Wires(Gate, Wire1, Wire2) when Gate#gate.type == gateAnd -> Wire1#wire.value band Wire2#wire.value;
calc2Wires(Gate, Wire1, Wire2) when Gate#gate.type == gateRShift -> Wire1#wire.value bsr Wire2#wire.value;
calc2Wires(Gate, Wire1, Wire2) when Gate#gate.type == gateLShift -> Wire1#wire.value bsl Wire2#wire.value;
calc2Wires(_, _, _) -> undefined.

% Возвращает значения всех входящих проводов с обновлённым значением по проводу, от которого получено сообщение
getWireValues(Gate, Message) -> get2WireValues(Gate#gate.inWires, Message).
get2WireValues([Wire1 , Wire2], Message) when Wire1#wire.name == Message#cmsg.wire -> [Wire1#wire{value = Message#cmsg.value} , Wire2];
get2WireValues([Wire1 , Wire2], Message) when Wire2#wire.name == Message#cmsg.wire -> [Wire1 , Wire2#wire{value = Message#cmsg.value}];
get2WireValues([Wire1 , Wire2], _) -> [Wire1 , Wire2].

% Отправить сообщение по указанному проводу
wireSend(Dict, Wire) when Dict /= undefined, Wire#wire.value /= undefined ->
  case dict:find(Wire#wire.name, Dict) of
    error -> 0;
    {ok, Gates} -> gatesSend(Gates, #cmsg{wire = Wire#wire.name, value = Wire#wire.value})
  end;
wireSend(_, _) -> 0.

% Отправить сообщение всем вентилям по списку
gatesSend([Pid | Gates], Value) when is_pid(Pid) -> gatesSend(Gates, Pid!Value);
gatesSend([_ | Gates], Value) -> gatesSend(Gates, Value);
gatesSend([], _) -> 0.

% Преобразуем вентили в виде текста в кортежи
parse([Gate | Gates]) -> [gate_tuple(string:split(Gate, " ", all)) | parse(Gates)];
parse([]) -> [].
gate_tuple(["NOT", Wire1, "->", Wire2]) -> #gate{type = gateNot, inWires = [wireOrValue(Wire1)], outWire = wireOrValue(Wire2)}; % NOT wire1 -> wire2
gate_tuple([Wire1, "OR", Wire2, "->", Wire3]) -> #gate{type = gateOr, inWires = [wireOrValue(Wire1), wireOrValue(Wire2)], outWire = wireOrValue(Wire3)}; % wire1 OR wire2 -> wire3
gate_tuple([Wire1, "AND", Wire2, "->", Wire3]) -> #gate{type = gateAnd, inWires = [wireOrValue(Wire1), wireOrValue(Wire2)], outWire = wireOrValue(Wire3)}; % wire1 AND wire2 -> wire3
gate_tuple([Wire1, "RSHIFT", Wire2, "->", Wire3]) -> #gate{type = gateRShift, inWires = [wireOrValue(Wire1), wireOrValue(Wire2)], outWire = wireOrValue(Wire3)}; % wire1 RSHIFT wire2 -> wire3
gate_tuple([Wire1, "LSHIFT", Wire2, "->", Wire3]) -> #gate{type = gateLShift,inWires = [ wireOrValue(Wire1), wireOrValue(Wire2)], outWire = wireOrValue(Wire3)}; % wire1 LSHIFT wire2 -> wire3
gate_tuple([Wire1, "->", Wire2]) -> #gate{type = gateWire, inWires = [wireOrValue(Wire1)],outWire =  wireOrValue(Wire2)}; % wire1 -> wire2
gate_tuple(_) -> #gate{}.

% Провод или константа?
wireOrValue(Wire) ->
  case string:to_integer(Wire) of
    {error, _} -> #wire{name = Wire};
    {Value, _} -> #wire{type = value, name = Wire, value = Value}
  end.
