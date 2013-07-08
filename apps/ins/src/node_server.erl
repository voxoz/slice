-module(node_server).
-author('Maxim Sokhatsky').
-copyright('Synrc Research Center').
-compile(export_all).
-include_lib("kvs/include/users.hrl").
-include_lib("ins/include/node_server.hrl").

zodiac() ->  [{19,1,"ca"},{16,2,"aq"},{12,3,"pi"},{19,4,"ar"},{14,5,"ta"},{20,6,"ge"},{21,6,"cn"},
              {10,8,"le"},{16,9,"vi"},{31,10,"li"},{21,11,"se"},{30,11,"op"},{18,12,"sa"}].
chinese() -> [{2013,2,10,"sn"},{2014,1,31,"ho"},{2015,2,19,"go"}].

hostname() -> 
    {{Y,M,D},Time} = calendar:now_to_datetime(now()), 
    year({Y,M,D}) ++ month({M,D}).

year(Date) ->
    lists:foldl(fun(A,Acc) ->
        {D,M,Y,Code} = A,
        case Date >= {D,M,Y} of true -> Code; _ -> Acc end 
    end,"un",chinese()).

month({M,D}) ->
    lists:foldl(fun(A,Acc) ->
        {Day,Month,Code} = A,
        case {M,D} >= {Month,Day} of true -> Code; _ -> Acc end 
    end,"sa",zodiac()).

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

make_pass() ->
    Res = os:cmd("makepasswd --char=12"),
    [Pass] = string:tokens(Res,"\n"),
    Pass.

make_template(Hostname,User,Pass) ->
    erlydtl:compile(code:priv_dir(ins) ++ "/" ++ "Dockerfile.template",docker_template),
    {ok,File} = docker_template:render([{password,Pass}]),
    os:cmd(["mkdir -p users/",User,Hostname]),
    file:write_file(["users/",User,Hostname,"/Dockerfile"], File).

docker_build(Hostname,User) ->
    Res = os:cmd(["docker build users/",User,Hostname]),
    Tokens = string:tokens(Res,"\n"),
    [Success,Id,LXC|Rest] = lists:reverse(Tokens),
    Running = string:tokens(LXC," "),
    hd(lists:reverse(Running)).

docker_commit(Id,Hostname,User) -> os:cmd(["docker commit ",Id," voxoz/",User,Hostname]).
docker_push(Hostname,User) -> os:cmd(["docker push voxoz/",User,Hostname]).

docker_run(Hostname,User,Cpu,Ram,Ports) ->
    P = string:join([ "-p " ++ integer_to_list(Port) || Port <- Ports], " "),
    Cmd = ["docker run -d ",P," -c=",integer_to_list(Cpu)," -h=\"",Hostname,"\" voxoz/",User,Hostname,
           " /usr/bin/supervisord -n"],
    Res = os:cmd(Cmd),
    Tokens = string:tokens(Res,"\n"),
    hd(Tokens).

docker_port(Id,Port) ->
    Res = os:cmd(["docker port ",Id," ",integer_to_list(Port)]),
    [Tokens] = string:tokens(Res,"\n"),
    list_to_integer(Tokens).

hostname_ip() ->
    Res = os:cmd("hostname -I"),
    IP = string:tokens(Res," "),
    hd(IP).

create_box(User,Cpu,Ram,Cert,Ports) ->
    Pass = make_pass(),
    Hostname = [hostname(),integer_to_list(kvs:next_id(feed))],
    make_template(Hostname,User,Pass),
    LXC = docker_build(Hostname,User),
    docker_commit(LXC,Hostname,User),
%    docker_push(Hostname,User),
    Id = docker_run(Hostname,User,Cpu,Ram,Ports),
    Port = docker_port(Id,22),
    Ip = hostname_ip(),
%    {Id,Ip,Port,User,Hostname,Pass,{Date,Time}} = Res,
    Box = #box{id=Id,host=Hostname,region=Ip,pass=Pass,user=User,ssh=Port,datetime=calendar:now_to_datetime(now()),ports=[22,80]},
    kvs:put(Box),
    Box.
%    Res = {Id,Ip,Port,User,Hostname,Pass,calendar:now_to_datetime(now())},
%    .

auth(User,Token) ->
    case ets:lookup(accounts,Token) of
         [{_,User}] -> ok;
         _ -> error end.

decide() ->
    Instances = kvs:all(instance),
    [First|Rest] = Instances,
    First.
