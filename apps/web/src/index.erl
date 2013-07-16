-module(index).
-compile(export_all).
-include_lib("n2o/include/wf.hrl").
-include_lib("kvs/include/users.hrl").

header()-> header(false).
header(Inverse) -> [
  #panel{class=[navbar, "navbar-fixed-top", if Inverse==true->"navbar-inverse"; true-> "" end, "sky-navbar"], body=[
    #panel{class=["navbar-inner"], body=[
      #panel{class=[container], body=[
        #link{class=[btn, "btn-navbar"], data_fields=[{<<"data-toggle">>, <<"collapse">>}, {<<"data-target">>, <<".nav-collapse">>}], url="javascript:void(0)",
          body=[#span{class=["icon-bar"]}||_I<-lists:seq(1,3)]},

        #h1{class=[brand], body=#link{url="http://voxoz.com", body= <<"Erlang Cloud">>, name="top" }},
        #panel{class=["nav-collapse", "collapse"], body=[
          #list{class=[nav, "pull-right"], body=[
            #li{body=#link{body= <<"Home">>,url="http://voxoz.com/"}},
            #li{body=#link{body= <<"Pricing">>,url="http://voxoz.com/pricing.html"}},
            #li{body=#link{body= <<"Apps">>,url="http://voxoz.com/apps.html"}},
 %           #li{body=#link{body= <<"Devs">>,url="#"}},
%            #li{body=#link{body= <<"About">>,url="#"}},
            #li{body=[
              case wf:user() of
                undefined -> #link{id=login1, body= <<"Dashboard">>, postback=to_login, delegate=login};
                User ->
                    #link{class=["dropdown-toggle", "avatar"],
                    %data_fields=[{<<"data-toggle">>, <<"dropdown">>}],
                    url="/account", body=[
                    case User#user.avatar of undefined-> ""; Img-> #image{class=["img-circle", "img-polaroid"], image=iolist_to_binary([Img,"?sz=50&width=50&height=50&s=50"]), width= <<"50px">>, height= <<"50px">>} end,
                    case User#user.display_name of undefined -> []; N -> N end]} end,
              #button{id="style-switcher", class=[btn, "btn-inverse", "dropdown-toggle", "account-link"], data_fields=[{<<"data-toggle">>, <<"dropdown">>}], body=#i{class=["icon-cog"]}},
              #list{class=["dropdown-menu"], body=[
                #li{body=#link{body=[#i{class=["icon-cog"]},  <<" Preferences">>]}},
                #li{body=#link{postback=chat,body=[#i{class=["icon-cog"]},  <<" Notifications">>]}},
                case wf:user() of
                  undefined -> #li{body=#link{id=loginbtn, postback=to_login, delegate=login, body=[#i{class=["icon-off"]}, <<" Login">> ]}};
                  _A -> #li{body=#link{id=logoutbtn, postback=logout, delegate=login, body=[#i{class=["icon-off"]}, <<" Logout">> ] }} end ]} ]} ]} ]} ]} ]} ]} ].

footer() -> [].
footer_main()-> [
  #footer{id=mainfooter, class=[section, "sky-footer"], body=
    #panel{class=["row-fluid"], body=[
          #panel{class=[span5, "footer-banner"], body=[
            #h3{body= <<"Synrc Research Center">>},
            #p{body = <<"Feel free to share your thoughts on Voxoz, Erlang, PaaS and other things.">>},
            #list{class=[icons], body=[
              #li{body=[#i{class=["icon-github", "icon-2x"]}, #link{url= <<"https://github.com/synrc">>, body= <<"Synrc Repositories">>}]}
            ]},
            #list{class=[unstyled], body=[
              #li{body= <<" &copy; 2013 Synrc Research Center s.r.o.">>},
              #li{body= <<" Roh&#225;&#269;ova 141/18, Praha 3 13000, Czech Republic">>},
              #li{body= <<" HQ: Chokolivsky blvd, 19A, off. 8, Kyiv, Ukraine">>}
            ]}
          ]},
          #panel{class=[span2], body=[
            #h3{body= <<"voxoz">>},
            #list{class=[unstyled], body=[
              #li{body=#link{url= <<"http://voxoz.com">>, body= <<"How it works">>}},
              #li{body=#link{url= <<"http://voxoz.com/pricing.html">>, body= <<"Pricing">>}},
              #li{body=#link{url= <<"http://voxoz.com/apps.html">>, body= <<"Applications">>}}
            ]}
          ]},
          #panel{class=[span5], body=[
            #h3{body= <<"Recent news">>},
            #list{class=[unstyled], body=[
              #li{body=[#h3{body=[#link{url= <<"http://voxoz.com/">>, body= <<"First Erlang PaaS">>}]}, #p{body= <<"Jun 12, 2013">>}]},
              #li{body=[#h3{body=[#link{url= <<"http://synrc.com/framework/web">>, body= <<"N2O: Fastest Erlang Web Framework">>}]}, #p{body= <<"May 1, 2013">>}]} ]} ]} ]} }].


event(login) -> User = wf:q(user), wf:user(User), 
    error_logger:info_msg("Login Pressed Indeex"),
    wf:redirect("/account").
