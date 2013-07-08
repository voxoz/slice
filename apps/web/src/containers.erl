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
  Boxes = kvs:all(box),
  [
  #h3{body= <<"your linux boxes">>},
  case Boxes of
     [] -> [<<"You have no containers yet.">>, #br{}, #br{}];
     _ -> #table{class=[table, "table-hover", containers],
      header=[#tr{cells=[
        #th{body= <<"ID">>},
        #th{body= <<"Host">>},
        #th{body= <<"Pass">>},
        #th{body= <<"Region">>},
        #th{body= <<"SSH">>},
        #th{body= <<"action">>}]} ],
      rows=[ box(Box) || Box <- Boxes ]} end,
  #panel{class=["btn-toolbar"], body=[#button{id=create, class=[btn, "btn-large", "btn-success"], body= <<"Create LXC">>, postback=create}]} ].

box(#box{id=Id,host=Hostname,pass=Pass,region=Region,user=User,ssh=Port}) ->
    #tr{class=[success], cells=[
        #td{body= wf:to_list(coalesce(Id))},
        #td{body= wf:to_list(coalesce(Hostname))},
        #td{body= wf:to_list(coalesce(Pass))},
        #td{body= wf:to_list(coalesce(Region))},
        #td{body= wf:to_list(coalesce(Port))},
        #td{body= #button{class=[btn],body= <<"Stop">>, postback={stop,Id}}} ]}.

api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [];
event(create) ->
   wf:redirect("/newlxc");
event(_) -> [].

coalesce(X) -> case X of undefined -> []; Z -> Z end.
