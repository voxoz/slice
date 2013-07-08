-module(newlxc).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("ins/include/node_server.hrl").
-include_lib("kvs/include/users.hrl").

main() -> case wf:user() of undefined -> wf:redirect("/login"); _ -> 
   [#dtl{file = "prod", bindings=[{title,<<"Create container">>},{body,body()}]}] end.

body() -> index:header() ++ [
  #section{id=content, body=
    #panel{class=[container], body=
      #panel{class=[row, dashboard], body=[
        #panel{class=[span3], body=dashboard:sidebar_menu(containers)},
        #panel{class=[span9], body=dashboard:section(create_lxc(wf:user()), "icon-list")}]}}}
  ] ++ index:footer().

create_lxc(User) -> [
  #h3{body= <<"create container">>},
  #panel{class=["form-horizontal", "create-container"], body=[
    #panel{class=["control-group", name], body=[
      #label{class=["control-label"], body= <<"Name:">>, for=release},
      #panel{class=[controls], body=[
        #textbox{id=release, value= <<"snsc3">>}
      ]}
    ]},
    #panel{class=["control-group"], body=[
      #label{class=["control-label"], body= <<"CPU:">>, for=cpu},
      #panel{class=[controls], body=[
        #textbox{data_fields=[
          {<<"data-spy">>, <<"slider">>},
          {<<"data-slider-id">>, <<"cpu">>},
%          {<<"data-slider-min">>, <<"-20">>},
%          {<<"data-slider-max">>, <<"20">>},
%          {<<"data-slider-step">>, <<"1">>},
          {<<"data-slider-value">>, <<"5">>}%,
%          {<<"data-slider-orientation">>, <<"horizontal">>},
%          {<<"data-slider-selection">>, <<"after">>},
%          {<<"data-slider-tooltip">>, <<"show">>},
%          {<<"data-slider-handle">>, <<"round">>}
        ]}
      ]}
    ]},
    #panel{class=["control-group"], body=[
      #label{class=["control-label"], body= <<"RAM:">>, for=ram},
      #panel{class=[controls], body=[
        #textbox{data_fields=[
          {<<"data-spy">>, <<"slider">>},
          {<<"data-slider-id">>, <<"ram">>},
          {<<"data-slider-value">>, <<"5">>}
        ]}
      ]}
    ]}
  ]},
  #panel{class=["btn-toolbar"], body=[#link{id=createlxc, class=[btn, "btn-large", "btn-success"], body= <<"Approve">>, postback=create_lxc}]} ].

api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [];
event(create_lxc) ->
    Node = node_server:decide(),
    Res = rpc:call(Node#instance.name,node_server,create_box,[wf:user(),10,64,0,[22,80]]),
    error_logger:info_msg("Box: ~p",[Res]),
%    {Id,Ip,Port,User,Hostname,Pass,{Date,Time}} = Res,
%    Box = #box{id=Id,host=Hostname,pass=Pass,user=User,ssh=Port,datetime={Date,Time},ports=[22,80]},
%    {ok,Box} = Res,
    ets:insert(boxes,Res),
    wf:redirect("/containers").

