-module(ex9).
-export([start/1, start/2, get/0, clock/1, clock/3, ticker/2, timer/3, timerP/3]).


% Assignment 1 
ticker(Interval, Clock) ->
    receive
        stop -> 
            exit(normal)
    after
        Interval ->
            Clock ! {tick, self()},
            ticker(Interval, Clock)
    end.


clock(Interval) ->
    clock(0, spawn(?MODULE, ticker, [Interval, self()]), false).

clock(Time, SubPid, Paused) ->
    receive
        {tick, Pid} ->
            if 
                Paused ->  
                    clock(Time, SubPid, Paused);
                SubPid == Pid ->
                    io:format("tick ~p\n",[Time + 1]),
                    clock(Time + 1, SubPid, Paused)
            end;

        stop -> 
            SubPid ! stop, 
            exit(normal);
        
        pause ->
            clock(Time, SubPid, true); 

        resume -> 
            clock(Time, SubPid, false);

        {set, Value} -> 
            clock(Value, SubPid, Paused);

        {get, Pid} -> 
            Pid ! {clock, Time},
            clock(Time, SubPid, Paused)
    end.


% Assignment 2
timer(Interval, Duration, WhenDone) ->
    timerP(Duration, spawn(?MODULE, ticker, [Interval, self()]), WhenDone).

timerP(0, Ticker, WhenDone) ->
    Ticker ! stop,
    WhenDone(),
    exit(normal);

timerP(TimeLeft, Ticker, WhenDone) ->
    receive
        {tick, Pid} ->
            if 
                Ticker == Pid ->
                    io:format("tick ~p\n",[TimeLeft - 1]),
                    timerP(TimeLeft - 1, Ticker, WhenDone)
            end;

        stop -> 
            Ticker ! stop, 
            exit(normal)
    end.

% Main
start(Interval) ->
    Clock = spawn(?MODULE, clock, [Interval]),
    io:format("Starting Clock Process with PID ~p\n",[Clock]),
    register(clockProcess, Clock),
    ok.

start(Interval, Duration) ->
    WhenDone = fun() -> io:format("Timer Finished \n") end,
    Timer = spawn(?MODULE, timer, [Interval, Duration, WhenDone]),
    register(timerProcess, Timer),
    ok.

get() ->
    clockProcess ! {get, self()},
    receive
        {clock, Time} -> io:format("Recieved Time ~p\n",[Time])
    end.