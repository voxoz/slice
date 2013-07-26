-module(releases).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("kvs/include/users.hrl").

main() -> case wf:user() of undefined -> wf:redirect("/login"); _ -> 
   [#dtl{file = "prod", bindings=[{title,<<"Releases">>},{body,body()}]}] end.

body() -> index:header() ++ [
  #section{id=content, body=
    #panel{class=[container], body=
      #panel{class=[row, dashboard], body=[
        #panel{class=[span3], body=dashboard:sidebar_menu(?MODULE)},
        #panel{class=[span9], body=dashboard:section(containers(wf:user()), "icon-list")}]}}}
  ] ++ index:footer().


row(Color,Name,LXC,Live,Sync) ->
      #tr{class=[Color], cells=[
        #td{body= Name},
        #td{body= LXC},
        #td{body= #link{class=[btn], body= Live}},
        #td{body= #link{class=[btn], body= Sync}} ]}.

containers(User) -> [
  #h3{body= <<"Erlang releases">>},
  #table{class=[table, "table-hover", containers],
    header=[ #tr{cells=[
      #th{body= <<"Name">>},
      #th{body= <<"LXC">>},
      #th{body= <<"Live">>},
      #th{body= <<"Sync">>}]} ],
    body=[[
        row(success,"app","gn1.synrc.com","Stop","Update"),
        row(success,"game","gn1.synrc.com","Start","Initial Push"),
        row(success,"web","gn1.synrc.com","Stop","Update"),
        row(warning,"web","skyline.synrc.com","Stop","Update")
      ]]},
    #panel{class=["btn-toolbar"], body=[#link{id=createrel, class=[btn, "btn-large", "btn-success"], body= <<"Create Release">>, postback=create_release, delegate=dashboard}]} ].

api_event(Name,Tag,Term) -> error_logger:info_msg("dashboard Name ~p, Tag ~p, Term ~p",[Name,Tag,Term]).
event(init) -> [].
