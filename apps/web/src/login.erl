-module(login).
-compile(export_all).
-include_lib("avz/include/avz.hrl").
-include_lib("n2o/include/wf.hrl").
-include_lib("kvs/include/users.hrl").
-define(VOXOZ,[facebook,google,twitter,github]).

main() ->
  avz:callbacks(?VOXOZ),
  [ #dtl{file = "login",  ext="dtl",bindings=[{title,<<"Login">>},
                                              {header,index:header()},
                                              {footer,index:footer()},
                                              {sdk,avz:sdk(?VOXOZ)},
                                              {buttons,avz:buttons(?VOXOZ)}]} ].

event(login) -> wf:redirect("/containers");
event(X) -> avz:event(X).
api_event(X,Y,Z) -> avz:api_event(X,Y,Z).
