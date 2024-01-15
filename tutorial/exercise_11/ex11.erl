-module(ex11).
-compile(export_all).

counterProcess(C) ->
    receive
        plus ->
            counterProcess(C+1);
        get ->
            io:format("Counter ~p\n",[C]),
            counterProcess(C);
        stop ->
            ok
    end.

rpc(Pid, Request) -> 
    Pid ! {self(), Request}, 
    receive 
       {Pid, Response} -> 
            counter ! plus,
            Response
       after 250 -> 
           unreachable
    end. 

% We have informed all processes that we are Coordinator
% Continute business as usual
informOfCoordinator([], AllPs) ->
    process(AllPs);

informOfCoordinator([OtherP | OtherPs], AllPs) ->
    OtherP ! {inform, self()},
    informOfCoordinator(OtherPs, AllPs).

% We are coordinator now, so we must inform all processes now
elect([], AllPs) ->
    io:format("No active higher Process found; ~p Is now Coordinator\n",[self()]),
    informOfCoordinator(AllPs, AllPs);

% Look for first higher Process to respond
elect([OtherP | OtherPs], AllPs) ->
    if 
        (OtherP > self()) ->
            io:format("Sending RPC to ~p\n",[OtherP]),
            Resp = rpc(OtherP, election),

            case Resp of
                ok ->
                    io:format("~p Answered, reentering main loop\n", [OtherP]),
                    OtherP ! startElection,
                    process(AllPs); 
                unreachable ->
                    io:format("~p Didnt answer, trying next\n",[OtherP]),
                    elect(OtherPs, AllPs)
            end;

        true ->
            elect(OtherPs, AllPs)
    end.

% Start Process
startProcess() -> 
    process([]).
    
process(AllPs) ->
    receive 
        {Pid, election} ->
            Pid ! {self(), ok},
            process(AllPs); 
        startElection ->
            io:format("Starting Election amongst ~p\n",[AllPs]),
            elect(AllPs, AllPs);
        {inform, Pid} ->
            process(AllPs);
        {processes, AllProcesses} ->
            process(AllProcesses);
        stop ->
            ok
    end.    

% Assignment bs
sendAllProcesses([], AllPs) ->
    AllPs;

sendAllProcesses([P | Ps], AllPs) ->
    P ! {processes, AllPs},
    io:format("Process registered: ~p\n",[P]),
    sendAllProcesses(Ps, AllPs).

stopAll([]) ->
    ok;

stopAll([P | Ps]) ->
    P ! stop,
    stopAll(Ps).

head([P | _]) ->
    P.

setup() ->
    [spawn(?MODULE, startProcess, [])] 
    ++ [spawn(?MODULE, startProcess, [])] 
    ++ [spawn(?MODULE, startProcess, [])] 
    ++ [spawn(?MODULE, startProcess, [])]. 

run() ->
    Counter = spawn(?MODULE, counterProcess, [0]),
    register(counter, Counter),

    Group = setup(),
    sendAllProcesses(Group, Group),
    timer:sleep(1000),
    % Start election once
    head(Group) ! startElection,
    timer:sleep(2000),

    % Deactivate Coordinator
    lists:max(Group) ! stop,
    
    % Start another election to get new Coordinator
    head(Group) ! startElection,
    timer:sleep(2000),

    % Add another group of processes
    Group2 =  Group ++ setup(),
    sendAllProcesses(Group2, Group2),
    timer:sleep(1000),

    % Elect again
    head(Group) ! startElection,

    timer:sleep(1000),
    counter ! get,

    timer:sleep(5000),
    stopAll(Group2),
    counter ! stop.



                

