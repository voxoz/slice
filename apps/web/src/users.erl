-module(users).
-compile(export_all).
-include_lib("kvs/include/users.hrl").
-include_lib("ins/include/node_server.hrl").

% This is REST callbacks module for bucket USERS

-define(USERS, [#user{username="maxim",email="maxim@synrc.com"},
                #user{username="doxtop",email="doxtop@synrc.com"},
                #user{username="roman",email="roman@github.com"}]).

init() -> ets:new(users, [named_table,{keypos,#user.email}]), ets:insert(users, ?USERS).
get([]) -> ets:foldl(fun(C,Acc) -> [C|Acc] end,[],users);
get(Id) -> ets:lookup(users,Id).
delete(Id) -> ets:delete(users,Id).
put(User=#user{}) -> ets:insert(users,User).
exists(Id) -> ets:member(users,Id).
to_html(User=#user{}) -> [<<"<tr><td>">>,coalesce(User#user.username),<<"</td><td>">>,
                                         coalesce(User#user.email),<<"</td><td>">>,
                                         coalesce(User#user.name),<<"</td></tr">>].

coalesce(Name) -> case Name of undefined -> <<>>; A -> list_to_binary(A) end.

join_node(Instance = #instance{}) -> [ case net_adm:ping(Node) of pong -> rpc:call(Node,kvs,put,[Instance]); _ -> skip 
            end || #instance{name=Node} <- kvs:all(instance) ], kvs:put(Instance).

sync() -> [ case net_adm:ping(Node) of pong -> rpc:call(Node,users,join,[]); _ -> skip 
            end || #instance{name=Node} <- kvs:all(instance) ].

join() ->
    [case net_adm:ping(Node) of
         pong -> Boxes = rpc:call(Node,kvs,all,[box]),
                 [ ets:insert(boxes,Box) || Box <- Boxes, is_list(Boxes) ],
                 Boxes;
          _ -> skip end || #instance{name=Node} <- kvs:all(instance) ].
