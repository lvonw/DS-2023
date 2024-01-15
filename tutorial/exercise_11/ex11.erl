-module(ex11).
-compile(export_all).

rpc(Pid, Request) -> 
    Pid ! {self(), Request}, 
    receive 
       {Pid, Response} -> 
           Response
       after 250 -> 
           unreachable
    end. 

% We have informed all processes that we are Coordinator
% Continute business as usual
informOfCoordinator([], AllPs) ->
    process(AllPs, AllPs);

informOfCoordinator([OtherP | OtherPs], AllPs) ->
    OtherP ! {inform, self()},
    informOfCoordinator(OtherPs, AllPs).

% Start Process
process(AllPs) -> 
    process(AllPs, AllPs).

% We are coordinator now, so we must inform all processes now
process([], AllPs) ->
    informOfCoordinator(AllPs, AllPs);

process([OtherP | OtherPs], AllPs) ->
    receive 
        {Pid, election} ->
            Pid ! {self(), ok},
            process(AllPs, AllPs); 
        {startElection} ->
            if 
                (OtherP > self()) ->
                    Resp = rpc(OtherP, election),
                    case Resp of
                        ok ->
                                OtherP ! startElection,
                                process(AllPs, AllPs); 
                        unreachable ->
                            process(OtherPs, AllPs)
                    end;
                true ->
                    process(OtherPs, AllPs)
            end;
        {inform, Pid} ->
            ok
    end.    

% Assignment b

setup() ->
    
                

