-module(node_server).
-author('Maxim Sokhatsky').
-copyright('Synrc Research Center').
-compile(export_all).
-include_lib("kvs/include/users.hrl").
-include_lib("ins/include/node_server.hrl").
-define(CREATE_TAB(T), store_mnesia:create_table(T, record_info(fields, T), [{storage, permanent}]) ).

zodiac() ->  [{19,1,"ca"},{16,2,"aq"},{12,3,"pi"},{19,4,"ar"},{14,5,"ta"},{20,6,"ge"},{21,6,"cn"},
              {10,8,"le"},{16,9,"vi"},{31,10,"li"},{21,11,"se"},{30,11,"op"},{18,12,"sa"}].
chinese() -> [{2013,2,10,"sn"},{2014,1,31,"ho"},{2015,2,19,"go"}].

init_db() ->
    ?CREATE_TAB(instance),
    ?CREATE_TAB(release),
    ?CREATE_TAB(region),
    ?CREATE_TAB(box),

    Regions = [ #region{name="do",provider="Digital Ocean"},
                #region{name="hz",provider="Hetzner"},
                #region{name="am",provider="Amazon"} ],
    Instances = [ #instance{name='instance_server@do2.synrc.com',region="do",status=active} ],

    kvs:put(Regions ++ Instances),
    ok.

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

create(Hostname,User,Token,Cpu,Ram,Cert,Ports) ->
    case auth(User,Token) of
         ok -> create_box(Hostname,User,Cpu,Ram,Cert,Ports);
         Error -> Error end.

make_pass() ->
    Res = os:cmd("makepasswd --char=12"),
    [Pass] = string:tokens(Res,"\n"),
    Pass,
    Res2 = os:cmd(["mkpasswd -m sha-512 ",Pass]),
    [Code] = string:tokens(Res2,"\n"),
    {Pass,Code}.

make_docker_template(Hostname,User,Pass) ->
    erlydtl:compile(code:priv_dir(ins) ++ "/" ++ "Dockerfile.template",docker_template),
    {ok,File} = docker_template:render([{password,Pass}]),
    os:cmd(["mkdir -p users/",User,Hostname]),
    file:write_file(["users/",User,Hostname,"/Dockerfile"], File).

make_nginx_template(Name,Region,Port) ->
    erlydtl:compile(code:priv_dir(ins) ++ "/" ++ "nginx.template",nginx_template),
    {ok,File} = nginx_template:render([{name,Name},{region,Region},{port,Port}]),
    file:write_file(["/etc/nginx/sites-enabled/",Name], File).

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

docker_start(Id) ->
    os:cmd(["docker start ",Id]),
    {ok,Box} = kvs:get(box,Id),
    Ports = [{P,docker_port(Id,P)}||{P,M}<-Box#box.portmap],
    kvs:put(Box#box{status=undefined,portmap=Ports}),
    make_nginx_template(Box#box.name,containers:region(Box#box.region),proplists:get_value(8989,Ports)),
    os:cmd("sudo service nginx reload").

docker_stop(Id) ->
    os:cmd(["docker stop ",Id]),
    {ok,Box} = kvs:get(box,Id),
    Ports = [{P,0}||{P,M}<-Box#box.portmap],
    kvs:put(Box#box{status=running,portmap=Ports}).

docker_ps() -> Res = os:cmd("docker ps"),
    [kvs:put(B#box{status=undefined})||B<-kvs:all(box)],
    Lines = string:tokens(Res,"\n"),
    [ begin
	Columns = string:tokens(Line," "),
	case kvs:get(box,hd(Columns)) of
	    {ok,Box} -> kvs:put(Box#box{status=running});
	    {error,Reason} -> skip end,
	error_logger:info_msg("~p~n",[Columns])
    end || Line <- Lines],
    error_logger:info_msg("~p",[Lines]).


docker_port(Id,Port) ->
    Res = os:cmd(["docker port ",Id," ",integer_to_list(Port)]),
    case string:tokens(Res,"\n") of
        [Tokens] -> list_to_integer(Tokens);
	_ -> 0 end.

hostname_ip() ->
    Res = os:cmd("hostname -I"),
    IP = string:tokens(Res," "),
    hd(IP).

create_box(Hostname,User,Cpu,Ram,Cert,Ports) ->
    {Pass,Code} = make_pass(),
    make_docker_template(Hostname,User,Code),
    LXC = docker_build(Hostname,User),
    docker_commit(LXC,Hostname,User),
    Id = docker_run(Hostname,User,Cpu,Ram,Ports),
    PortMap = [{Port,docker_port(Id,Port)}|| Port <- Ports],
    Ip = hostname_ip(),
    Box = #box{id=Id,host=Hostname,region=node(),pass=Pass,portmap=PortMap,
                user=User,ssh=proplists:get_value(22,PortMap),datetime=calendar:now_to_datetime(now())},
    kvs:put(Box),
    Box.

auth(User,Token) ->
    case ets:lookup(accounts,Token) of
         [{_,User}] -> ok;
         _ -> error end.

decide() -> {ok,I} = kvs:get(instance,'instance_server@do2.synrc.com'), I.

transform_box() ->
    Fun = fun({box,Id,User,Host,Pass,Region,Ram,Cpu,Ports,Datetime,Status}) -> 
              {box,Id,User,Host,Pass,Region,Ram,Cpu,Ports,Datetime,Status,0} end,
    Retur = mnesia:transform_table(box, Fun, [id,user,host,pass,ssh,region,ram,cpu,portmap,datetime,status,name]),
    io:format("Retur = ~p~n",[Retur]).
