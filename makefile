http-server:
	as http-server.s -o http-server.o
	ld http-server.o -o http-server
clean:
	rm http-server
	rm *.o