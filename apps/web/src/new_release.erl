-module(new_release).
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
  #h3{body= <<"create erlang release">>},
  #panel{class=["form-horizontal", "create-container", release], body=[
    #panel{class=["control-group", large, tall], body=[
      #label{class=["control-label"], body= <<"Name:">>, for=release},
      #panel{class=[controls], body=[
        #textbox{id=release, value= <<"web">>}
      ]}
    ]},
    #panel{class=["control-group", large], body=[
      #label{class=["control-label"], body= <<"LXC:">>, for=lxc},
      #panel{class=[controls], body=#select{id=lxc, class=[selectpicker], data_fields=[], body=[
          #option{body= <<"skyline.synrc.com">>},
          #option{body= <<"gn1.synrc.com">>}
        ]} } ]},
    #panel{class=["control-group", large], body=[
      #label{class=["control-label"], body= <<"Application Bone: ">>, for=app_bone},
      #panel{class=[controls, long], body=#select{id=app_bone, class=[selectpicker], body=[
        #option{body= <<"Fury Blog">>},
        #option{body= <<"Skyline App Store">>, label= <<"App Store">>},
        #option{body= <<"Social Esprit">>},
        #option{body= <<"None">>}
      ]}}
    ]},
    #panel{class=["btn-toolbar"], body=[#link{id=createlxc, class=[btn, "btn-large", "btn-success"], body= <<"Approve">>, postback=create_release}]} ]} ].

api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [];
event(create_release) ->
    wf:redirect("/releases").

