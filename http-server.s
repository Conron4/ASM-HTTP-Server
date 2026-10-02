/*
  SPDX-License-Identifier: GPL-V2-Only
  Copyright (C) 2026 Connor A. Hopley
 
  This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.

  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
 */

.global _start
.bss
  .lcomm html_fd, 8
  .lcomm server_fd, 8
  .lcomm client_fd, 8
  .lcomm client_addr, 16
  .lcomm client_addr.len, 4
  .lcomm readbuffer, 512 
  .lcomm writebuffer, 512
  .lcomm writebuffer.len, 8 
  

.text
  _start:
    movq $41, %rax # Syscall for socket
    movq $2, %rdi # Domain = PF_INET IPV4 see /usr/include/bits/socket.h
    movq $1, %rsi # Type = SOCK_STREAM see /usr/include/bits/socket_type.h
    movq $0, %rdx # Protocol = IP see /etc/protocols could also be 6
    syscall # Get linux kernel to do shit

    testq %rax, %rax # Check if rax(error code) is a negative intger so the operation failed
    js _badexit # If true goto _badexit and exit with code 1

    movq %rax, server_fd(%rip) # Move the server fd to the server fd variable

    movq $49, %rax # Syscall for bind
    movq server_fd(%rip), %rdi # Socket file descripter
    movq $server_addr, %rsi # sockaddr_in struct
    movq $16, %rdx # Length 16 bytes
    syscall

    testq %rax, %rax # See Above
    js _badexit # See above

    movq $1, %rax # Syscall for write
    movq $1, %rdi # fd for stdout
    movq $bind_msg, %rsi # memory address of bind_msg
    movq $bind_msg.len, %rdx # memory address of bind_msg.len
    syscall

    testq %rax, %rax
    js _badexit

    movq $50, %rax # Syscall for listen
    movq server_fd(%rip), %rdi # As above
    movq $5, %rsi # Backlog of 5
    syscall

    testq %rax, %rax
    js _badexit

  _acceptloop:
    movq $2, %rax # Open syscall
    movq $html_file, %rdi # File to open
    xorq %rsi, %rsi # Set rsi to 0
    syscall 

    testq %rax, %rax 
    js _badexit 
    
    movq %rax, html_fd(%rip) # Move the html fd to the html fd variable

    movq $43, %rax # Syscall for accept
    movq server_fd(%rip), %rdi # As above
    movq $client_addr, %rsi # Pointer to client_addr
    movl $16, client_addr.len(%rip) # Set length to 16
    movq $client_addr.len, %rdx # Pointer to client_addr.len
    syscall

    testq %rax, %rax
    js _badexit

    movq %rax, client_fd(%rip) # Client Connect Successfully

    movq $1, %rax # See above
    movq $1, %rdi # See above
    movq $client_msg, %rsi # Memory address of client_msg
    movq $client_msg.len, %rdx # Memory address of client_msg.len
    syscall

    testq %rax, %rax
    js _badexit

    movq $0, %rax # Read syscall
    movq client_fd(%rip), %rdi # fd of client
    movq $readbuffer, %rsi # Memory address of readbuffer
    movq $512, %rdx # Read first 512 bytes
    syscall

    test %rax, %rax 
    js _badexit
    
    movq $0, %rax # See above
    movq html_fd(%rip), %rdi # fd of html
    movq $writebuffer, %rsi # Memory address of writebuffer
    movq $512, %rdx # Read first 512 bytes
    syscall

    test %rax, %rax
    js _badexit

    movq %rax, writebuffer.len(%rip) # RAX contains length of read bytes

    movq $1, %rax 
    movq client_fd(%rip), %rdi # Client fd
    movq $response_header, %rsi # Response header address
    movq $response_header.len, %rdx # Response header length address
    syscall

    test %rax, %rax
    js _badexit
    
    movq $1, %rax 
    movq client_fd(%rip), %rdi # See above
    movq $writebuffer, %rsi # Memory address of write buffer
    movq writebuffer.len(%rip), %rdx # Memory address of write buffer length
    syscall

    test %rax, %rax
    js _badexit

    call _clientclose
    call _htmlclose
    jmp _acceptloop

  _badexit:
    call _serverclose
    call _clientclose
    call _htmlclose
    movq $60, %rax # See above
    movq $1, %rdi # Set exit code to 1
    syscall
  
  _clientclose:
    movq $3, %rax # Syscall for close
    movq client_fd(%rip), %rdi # Client_fd
    syscall
    ret
  
  _serverclose:
    movq $3, %rax # See above
    movq server_fd(%rip), %rdi # Server_fd
    syscall
    ret
  
  _htmlclose:
    movq $3, %rax
    movq html_fd(%rip), %rdi # HTML_fd
    syscall
    ret

.data
  response_header:
    .ascii "HTTP/1.1 200 OK\r\n"
    .ascii "Content-Type: text/html\r\n"
    .ascii "\r\n"

    response_header.len = . - response_header # Magic incanation to calc length
  
  html_file:
    .asciz "test.html"

  newline:
    .byte 10

  server_addr:
    .word 2              # sin_family = AF_INET
    .word 0x901F         # sin_port = htons(8080)
    .long 0x0100007F     # sin_addr = 127.0.0.1
    .zero 8              # sin_zero padding

  bind_msg:
    .asciz "Successfull binding on 127.0.0.1:8080\n"
    bind_msg.len = . - bind_msg # See above

  client_msg:
    .asciz "Client connected successfully\n"
    client_msg.len = . - client_msg  # See above
