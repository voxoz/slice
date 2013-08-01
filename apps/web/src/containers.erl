-module(containers).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("ins/include/node_server.hrl").
-include_lib("kvs/include/users.hrl").

main() -> case wf:user() of undefined -> wf:redirect("/login"); _ -> 
   [#dtl{file = "prod", bindings=[{title,<<"Containers">>},{body,body()}]}] end.

body() -> index:header() ++ [
  #section{id=content, body=
    #panel{class=[container], body=
      #panel{class=[row, dashboard], body=[
        #panel{class=[span3], body=dashboard:sidebar_menu(?MODULE)},
        #panel{class=[span9], body=dashboard:section(containers(wf:user()), "icon-list")}]}}}
  ] ++ index:footer().

containers(User) ->
%  Boxes = [ B || B <- ets:foldl(fun(C,A) -> [C|A] end,[],boxes), B#box.user == (wf:user())#user.email ],
  Boxes = [ B || B <- kvs:all(box), B#box.user == (wf:user())#user.email ],
  [
  #h3{body= <<"sshpass -p &lt;password&gt; ssh root@&lt;host&gt; -p &lt;port&gt;">>},
  case Boxes of
     [] -> [<<"You have no containers yet.">>, #br{}, #br{}];
     _ -> #table{class=[table, "table-hover", containers],
      header=[#tr{cells=[
%        #th{body= <<"ID">>},
        #th{body= <<"Hostname">>},
        #th{body= <<"Password">>},
        #th{body= <<"Host">>},
        #th{body= <<"Port">>},
        #th{body= <<"Action">>}]} ],
      body=[ [box(Box) || Box <- Boxes ]]} end,
  #panel{class=["btn-toolbar"], body=[#button{id=create, class=[btn, "btn-large", "btn-success"], body= <<"Create LXC">>, postback=create_lxc, delegate=dashboard}]} ].

box(#box{id=Id,host=Hostname,pass=Pass,region=Region,user=User,portmap=Ports,status=Status}) ->
    #tr{class=[status(Status)], cells=[
        #td{body= wf:to_list(coalesce(Hostname))},
%        #td{body= wf:to_list(coalesce(Id))},
        #td{body= wf:to_list(coalesce(Pass))},
        #td{body= region(Region)},
        #td{body= wf:to_list(coalesce(proplists:get_value(22,Ports)))},
        #td{body= button(Status,Id,Region)} ]}.

region(Region) -> [Name,Server] = string:tokens(atom_to_list(Region),"@"), Server.
status(running) -> success;
status(_) -> error.
button(running,Id,Region) -> #button{id=Id,class=[btn],body= <<"Stop">>, postback={stop,Id,Region}, delegate=containers};
button(_,Id,Region) ->
  wf:wire(wf:f("$('#~s').on('click', function(){$(this).html(\"<i class='icon-spinner icon-spin'></i> \"+$(this).html()); });", [Id])),
  #button{id=Id,class=[btn],body=[ <<" Start">>], postback={start,Id,Region}, delegate=containers}.


api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [];
event({start,Id,Region}) -> 
    Res = rpc:call(Region,node_server,docker_start,[Id]),
    case kvs:get(box,Id) of
        {ok,Box} -> kvs:put(Box#box{status=running});
        _ -> skip end,
    error_logger:info_msg("START LXC: ~p",[Res]),
    wf:redirect("/containers");
event({stop,Id,Region}) ->
    Res = rpc:call(Region,node_server,docker_stop,[Id]),
    case kvs:get(box,Id) of
        {ok,Box} -> kvs:put(Box#box{status=undefined});
        _ -> skip end,
    error_logger:info_msg("STOP LXC: ~p",[Res]),
    wf:redirect("/containers");
event(X) -> 
   error_logger:info_msg("Unknown Event: ~p",[X]),
  ok.


coalesce(X) -> case X of undefined -> []; Z -> Z end.
