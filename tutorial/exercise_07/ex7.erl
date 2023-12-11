-module(ex7). 
-export([convert/2, maxitem/1, maxitem/2, diff/3]).

%a
convert(X, cm)      -> X / 2.54;
convert(X, inch)    -> X * 2.54.

%b und c
maxitem([], Y)                  -> 
    io:format("Entered end case, returning ~p\n", [Y]), 
    Y;
maxitem([V | VS], Y) when V > Y -> 
    io:format("First list element ~p is greater than previous value ~p\n", [V, Y]), 
    maxitem(VS, V); 
maxitem([V | VS], Y)            -> 
    io:format("Previous list element ~p is greater than first value ~p\n", [Y, V]), 
    maxitem(VS, Y).

maxitem(X) -> maxitem(X, -10000).

%d
diff(F, X, H) ->
    (F(X+H) - F(X-H)) / (2*H). 

%AnFunc = fun(X) -> 2 * math:pow(X, 3) - 12 * X + 3
