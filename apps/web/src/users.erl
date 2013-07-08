-module(users).
-compile(export_all).
-include_lib("ins/include/node_server.hrl").
-include("users.hrl").

% This is REST callbacks module for bucket USERS

-define(USERS, [#user{id="maxim",email="maxim@synrc.com"},
                #user{id="doxtop",email="doxtop@synrc.com"},
                #user{id="roman",email="roman@github.com"}]).

init() -> ets:new(users, [named_table,{keypos,#user.id}]), ets:insert(users, ?USERS).
get([]) -> ets:foldl(fun(C,Acc) -> [C|Acc] end,[],users);
get(Id) -> ets:lookup(users,Id).
delete(Id) -> ets:delete(users,Id).
put(User=#user{}) -> ets:insert(users,User).
exists(Id) -> ets:member(users,Id).
to_html(User=#user{}) -> [<<"<tr><td>">>,coalesce(User#user.id),<<"</td><td>">>,
                                         coalesce(User#user.email),<<"</td><td>">>,
                                         coalesce(User#user.name),<<"</td></tr">>].

coalesce(Name) -> case Name of undefined -> <<>>; A -> list_to_binary(A) end.

join() ->
    AllBoxes = [begin
        net_adm:ping(Node),
        Boxes = rpc:call(Node,kvs,all,[box]),
        [ ets:insert(boxes,Box) || Box <- Boxes, is_list(Boxes) ],
        Boxes
    end || #instance{name=Node} <- kvs:all(instance) ],
    ok.
