-module(ex10).
-export([
    startServer/1,
    startClient/1, 
    get/0, 
    timeServer/1, timeServer/2, 
    client/1, client/3, 
    ticker/2,
    run1/0,
    run2/0,
    run3/0, run3/3]).


ticker(Interval, Clock) ->
    receive
        stop -> 
            exit(normal)
    after
        Interval ->
            Clock ! {tick, self()},
            ticker(Interval, Clock)
    end.

% Assignment 1
timeServer(Interval) ->
    timeServer(0, spawn(?MODULE, ticker, [Interval, self()])).

timeServer(Time, SubPid) ->
    receive
        {tick, Pid} ->
            if 
                SubPid == Pid ->
                    timeServer(Time + 1, SubPid)
            end;

        stop -> 
            SubPid ! stop, 
            exit(normal);
        
        show ->
            io:format("Server Time: ~p\n",[Time]),
            timeServer(Time, SubPid);

        {get, Pid} -> 
            T2 = Time,
            {C1,C2,C3} = erlang:timestamp(), 
            Cutc = 1000000000000 * C1 + 1000000 * C2 + C3,
            Pid ! {server, Cutc, T2, Time},
            timeServer(Time, SubPid)
    end.

% Assignment 2/ 3
client(Interval) ->
    client(0, 0, spawn(?MODULE, ticker, [Interval, self()])).

client(Time, T1, SubPid) ->
    % if 
    %     Time rem 50 == 0 ->
    %         self() ! adjust;
    %     true ->
    %         ok
    % end, 
    receive
        {tick, Pid} ->
            if 
                SubPid == Pid ->
                    client(Time + 1, T1, SubPid)
            end;

        stop ->
            SubPid ! stop, 
            exit(normal);
        
        show ->
            io:format("Client Time: ~p\n",[Time]),
            client(Time, T1, SubPid);

        adjust ->
            serverProcess ! {get, self()},
            client(Time, Time, SubPid);

        {server, Cutc, T2, T3} ->
            T4 = Time,
            Tsync = floor(Cutc + ((T2-T1) + (T4-T3)) / 2),
            client(Tsync, 0, SubPid)
    end.


% Main
startServer(Interval) ->
    TimeServer = spawn(?MODULE, timeServer, [Interval]),
    io:format("Starting Server Process with PID ~p\n",[TimeServer]),
    register(serverProcess, TimeServer).

startClient(Interval) ->
    Client = spawn(?MODULE, client, [Interval]),
    io:format("Starting Client Process with PID ~p\n",[Client]),
    register(clientProcess, Client).

get() ->
    clockProcess ! {get, self()},
    receive
        {clock, Time} -> io:format("Recieved Time ~p\n",[Time])
    end.

run1() ->
    startServer(1000),
    timer:sleep(5000),
    startClient(1000),
    timer:sleep(2000),
    
    serverProcess ! show,
    clientProcess ! show,

    timer:sleep(2000),

    clientProcess ! adjust,
    io:format("Adjusting\n"),
    timer:sleep(2000),

    serverProcess ! show,
    clientProcess ! show,

    serverProcess ! stop,
    clientProcess ! stop.

run2() ->
    startServer(100),
    timer:sleep(5000),
    
    Client1 = spawn(?MODULE, client, [50]),
    io:format("Starting Client Process with PID ~p\n",[Client1]),
    timer:sleep(1000),


    Client2 = spawn(?MODULE, client, [100]),
    io:format("Starting Client Process with PID ~p\n",[Client2]),
    timer:sleep(1000),

    Client3 = spawn(?MODULE, client, [150]),
    io:format("Starting Client Process with PID ~p\n",[Client3]),
    timer:sleep(1000),
    
    serverProcess ! show,
    Client1 ! show,
    Client2 ! show,
    Client3 ! show,

    timer:sleep(1000),
    io:format("Adjusting\n"),
    Client1 ! adjust,
    Client2 ! adjust,
    Client3 ! adjust,
    
    timer:sleep(1000),
    serverProcess ! show,
    Client1 ! show,
    Client2 ! show,
    Client3 ! show,

    serverProcess ! stop,
    Client1 ! stop,
    Client2 ! stop,
    Client3 ! stop.

run3 () ->
    startServer(100),
    timer:sleep(5000),

    Client1 = spawn(?MODULE, client, [50]),
    io:format("Starting Client Process with PID ~p\n",[Client1]),
    timer:sleep(1000),


    Client2 = spawn(?MODULE, client, [100]),
    io:format("Starting Client Process with PID ~p\n",[Client2]),
    timer:sleep(1000),

    Client3 = spawn(?MODULE, client, [150]),
    io:format("Starting Client Process with PID ~p\n",[Client3]),
    timer:sleep(1000),  

    run3(Client1, Client2, Client3).

run3(Client1, Client2, Client3) ->
    Client1 ! show,
    Client2 ! show,
    Client3 ! show,  
    io:format("======================\n"),
    timer:sleep(200), 
    run3(Client1, Client2, Client3).