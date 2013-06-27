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

% LXC creation schema

% ports: 22, 80, 2000
% user: maxim
% cpu: 8
% ram: 128000000

% makepasswd --char=12
% > L96QBmh21gKb
% docker build .
% >  ---> Running in e2f2668a6ab5
% >  ---> 79f6c9f416d2
% > Successfully built 79f6c9f416d2
% docker commit e2f2668a6ab5 synrc/sncn1
% docker push synrc/sncn1
% docker run -d -p 22 -p 80 -c=8 -m=128000000 synrc/sncn1 /usr/bin/supervisor -n
% > b33e7a0a354c
% docker port b33e7a0a354c 22
% > 49158
% docker port b33e7a0a354c 80
% > 49159

% mail: IP=do1.synrc.com, ROOT_PASS=L96QBmh21gKb, NAME=sncn1, ID=387ba01740ed, SSH_PORT=49158

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
