Ryan Napolitano
rn2473
Security 1, HW2

I was able to complete most of the assignment but when it came down to connecting s_server and s_client, I had major issues. I tried for days to figure out what was causing the issue but could nto figure it out. I must not have the correct firewall setting applied on google cloud for my VM instances. Every time I tried to connect the two I would receive the following error after running "bash s_client.sh".....:

140217042560128:error:0200206F:system library:connect:Connection refused:../crypto/bio/b_soc
k2.c:110:
140217042560128:error:2008A067:BIO routines:BIO_connect:connect error:../crypto/bio/b_sock2.
c:111:
140217042560128:error:0200206F:system library:connect:Connection refused:../crypto/bio/b_soc
k2.c:110:
140217042560128:error:2008A067:BIO routines:BIO_connect:connect error:../crypto/bio/b_sock2.
c:111:
connect:errno=111


I tried posting on piazza but did not get a response. Hopefully someone can answer so I do not run into this same issue in the future because it became a major issue that got in the way of completing the assignment. I've looked for days online to try and figure out the problem but came to no conclusions. 

Overall I thought this was a pretty cool assignment!