-module(newlxc).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("ins/include/node_server.hrl").
-include_lib("kvs/include/users.hrl").

main() -> case wf:user() of undefined -> wf:redirect("/login"); _ -> 
   [#dtl{file = "dev", bindings=[{title,<<"Create container">>},{body,body()}]}] end.

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
      #panel{class=[controls], body=#slider{id=cpu, formater = <<"function(value){return 'CPU: '+value;}">>}}
    ]},
    #panel{class=["control-group"], body=[
      #label{class=["control-label"], body= <<"RAM:">>, for=ram},
      #panel{class=[controls], body=#slider{id=ram, formater= <<"function(value){return 'RAM: '+value;}">>}}
    ]}
  ]},
  #panel{class=["btn-toolbar"], body=[#link{id=createlxc, class=[btn, "btn-large", "btn-success"], body= <<"Approve">>, postback=create_lxc}]} ].

api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [];
event(create_lxc) ->
    Box = node_server:create_box(wf:user(),10,64,0,[22,80]),
    {Id,Ip,Port,User,Hostname,Pass,{Date,Time}} = Box,
    error_logger:info_msg("Box: ~p",[Box]),
    kvs:put(#box{id=Id,host=Hostname,pass=Pass,user=User,ssh=Port,datetime={Date,Time},ports=[22,80]}),
    wf:redirect("/containers").

