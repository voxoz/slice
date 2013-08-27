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
    #panel{class=["control-group", large, tall], body=[
      #label{class=["control-label"], body= <<"Name:">>, for=release},
      #panel{class=[controls], body=[
        #textbox{id=release, value= node_server:hostname()++integer_to_list(kvs:next_id(feed)), disabled=true}
      ]}
    ]},
    #panel{class=["control-group", tall], body=[
      #label{class=["control-label"], body= <<"CPU:">>, for=cpu},
      #panel{class=[controls], body=#slider{id=cpu, formater = <<"function(value){return 'CPU: '+value;}">>}}
    ]},
    #panel{class=["control-group", tall], body=[
      #label{class=["control-label"], body= <<"RAM:">>, for=ram},
      #panel{class=[controls], body=#slider{id=ram, formater= <<"function(value){return 'RAM: '+value;}">>}}
    ]},
    #panel{class=["btn-toolbar"], body=[#link{id=createlxc, class=[btn, "btn-large", "btn-success"],
                                        body= <<"Approve">>, postback=create_lxc,source=[release]}]} ]} ].

api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [];
event(create_lxc) ->
    Node = node_server:decide(),
    Hostname = wf:q(release),
    Res = rpc:call(Node#instance.name,node_server,create_box,[Hostname,(wf:user())#user.email,0,120*1024*1024,0,[22,8000,8989]]),
    error_logger:info_msg("Box: ~p",[Res]),
    ets:insert(boxes,Res),
    wf:redirect("/containers").

