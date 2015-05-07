#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <netinet/in.h>
#include <unistd.h>
#include <signal.h>
#include <assert.h>

#define SRV_ADDR "0.0.0.0"
#define SRV_PORT 9001
#define SC_SIZE 0x2000

void handle_client(int sock)
{
	int i;
	int ret;
	int offset;
	char *ptr;
	void (*f)();

	void *p_code = mmap(NULL, SC_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC, 
		MAP_ANON | MAP_PRIVATE, -1 , 0);

	if(p_code == NULL) {
		printf("Memory allocation failed\n");
		return;
	}

	offset = 0;
	while(offset < SC_SIZE) {
		ret = recv(sock, ((uint8_t*) p_code) + offset, SC_SIZE - offset, 0);
		if(ret <= 0)
			break;

		offset += ret;
	}

	printf("[%d] Read %d bytes from socket\n", getpid(), offset);

	ptr = (char*) p_code;
	for(i = 0; i < offset; i++) {
		if(!isalnum((int) ptr[i])) {
			printf("[%d] Patching shellcode at offset: %d\n", getpid(), i);
			ptr[i] = '\0';
		}
	}

	f = (void*) p_code;
	f();
}

void child_handler(int signo)
{
	printf("Child exit (%d)\n", signo);
}

void segv_handler(int signo)
{
	printf("SIGSEGV (%d)\n", signo);
	exit(EXIT_FAILURE);
}

void abrt_handler(int signo)
{
	printf("SIGABRT (%d)\n", signo);
	exit(EXIT_FAILURE);
}

int srv_run()
{
	struct sockaddr_in sin;
	struct sockaddr_in cin;
	int srv_fd, cln_fd;
	int tmp;
	int sop;

	srv_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	assert(srv_fd > 0);

	sop = 1;
	setsockopt(srv_fd, SOL_SOCKET, SO_REUSEADDR, (void*) &sop, sizeof(sop));

	sin.sin_addr.s_addr = inet_addr(SRV_ADDR);
	sin.sin_port = htons(SRV_PORT);
	sin.sin_family = AF_INET;

	assert(!bind(srv_fd, (struct sockaddr*) &sin, sizeof(sin)));
	listen(srv_fd, 100);

	//signal(SIGCHLD, child_handler);
	signal(SIGCHLD, SIG_IGN);

	while(1) {
		tmp = sizeof(cin);
		cln_fd = accept(srv_fd, (struct sockaddr*) &cin, &tmp);
		if(cln_fd < 0)
			continue;

		printf("Received connection from %s:%d\n", (char*) inet_ntoa(cin.sin_addr), ntohs(cin.sin_port));
		if(!fork()) {
			printf("Processing client: pid: %d socket: %d\n", getpid(), cln_fd);

			//signal(SIGSEGV, segv_handler);
			//signal(SIGABRT, abrt_handler);
			
			close(srv_fd);
			handle_client(cln_fd);

			shutdown(cln_fd, SHUT_RDWR);
			close(cln_fd);
			exit(0);
		}

		close(cln_fd);
	}
}

int main(int argc, char **argv)
{
	return srv_run();
}
