-record(region,{name,provider}).
-record(instance, {name,user,region,status}).
-record(box,{name,instance,region,hostname,ram,cpu,ports,status}).
-record(release,{name,box,instance,region,status}).
-record(app,{name,release,box,instance,region,status}).