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
