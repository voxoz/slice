-module(containers).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("kvs/include/users.hrl").

main() -> case wf:user() of undefined -> wf:redirect("/login"); _ -> 
   [#dtl{file = "prod", bindings=[{title,<<"Containers">>},{body,body()}]}] end.

body() -> index:header() ++ [
  #section{id=content, body=
    #panel{class=[container], body=
      #panel{class=[row, dashboard], body=[
        #panel{class=[span3], body=dashboard:sidebar_menu(containers)},
        #panel{class=[span9], body=dashboard:section(key(wf:user()), "icon-list")}]}}}
  ] ++ index:footer().

key(User) -> [
  #h3{body= <<"SSH Public Key">>},
  #panel{class=["btn-toolbar"], body=[#link{class=[btn, "btn-large", "btn-success"], body= <<"Save">>}]} ].

api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [].
