-module(node_server).
-compile(export_all).
-include_lib("kvs/include/users.hrl").

login(User,Pass) ->
    Res = kvs:get(user,User),
    case Res of
        {ok,#user{username=User,password=Pass}} -> 
            Token = erlang:md5(term_to_binary({now(),make_ref()})),
            ets:insert(accounts,{Token,User}),
            Token;
        _ -> skip end.

create(User,Token,Cpu,Ram,Cert,Ports) ->
    case auth(User,Token) of
         ok -> create_box(User,Cpu,Ram,Cert,Ports);
         Error -> Error end.

create_box(User,Cpu,Ram,Cert,Ports) ->
    P = string:join([ "-p " ++ integer_to_list(Port) || Port <- Ports], " "),
    Hostname = "sncn" ++ integer_to_list(kvs:next_id(feed)),
    Cmd = "docker run -d " ++ P ++ 
          " -c=" ++ integer_to_list(Cpu) ++ 
          " -h \""++ Hostname ++ "\" voxoz/precise /usr/bin/supervisord -n",
    error_logger:info_msg(Cmd),
    Res = os:cmd(Cmd),
    Tokens = string:tokens(Res,"\n"),
    [Id]=tl(Tokens),
    Id.

auth(User,Token) ->
    case ets:lookup(accounts,Token) of
         [{_,User}] -> ok;
         _ -> error end.
