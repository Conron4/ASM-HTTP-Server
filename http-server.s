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
  .lcomm client_addr_len, 4
  .lcomm readbuffer, 512
  .lcomm writebuffer, 512

.text
  _start:
    movq $2, %rax
    movq $html_file, %rdi
    xorq %rsi, %rsi
    syscall

    testq %rax, %rax
    js _badexit
    
    movq %rax, html_fd(%rip)

    movq $41, %rax # Syscall for socket
    movq $2, %rdi # Domain = PF_INET IPV4 see /usr/include/bits/socket.h
    movq $1, %rsi # Type = SOCK_STREAM see /usr/include/bits/socket_type.h
    movq $0, %rdx # Protocol = IP see /etc/protocols could also be 6
    syscall

    testq %rax, %rax
    js _badexit
    movq %rax, server_fd(%rip)

    movq $49, %rax # Syscall for bind
    movq server_fd(%rip), %rdi # Socket file descripter
    movq $server_addr, %rsi # sockaddr_in struct
    movq $16, %rdx # Length 16 bytes
    syscall

    testq %rax, %rax
    js _badexit

    movq $1, %rax
    movq $1, %rdi
    movq $bind_msg, %rsi
    movq $bind_msg.len, %rdx
    syscall

    testq %rax, %rax
    js _badexit

    movq $50, %rax # Syscall for listen
    movq server_fd(%rip), %rdi # As above
    movq $5, %rsi # Backlog of 5
    syscall

    testq %rax, %rax
    js _badexit

    movq $43, %rax
    movq server_fd(%rip), %rdi
    movq $client_addr, %rsi
    movl $16, client_addr_len(%rip)
    movq $client_addr_len, %rdx
    syscall

    testq %rax, %rax
    js _badexit

    movq %rax, client_fd(%rip)
    movq $1, %rax
    movq $1, %rdi
    movq $client_msg, %rsi
    movq $client_msg.len, %rdx
    syscall
    
    jmp _exit

  _exit:
    movq $3, %rax
    movq client_fd(%rip), %rdi
    syscall

    movq $3, %rax
    movq server_fd(%rip), %rdi
    syscall

    movq $60, %rax
    xorq %rdi, %rdi
    syscall

  _badexit:
    movq $60, %rax
    movq $1, %rdi
    syscall

.data
  ok:
    .asciz "HTTP/1.1 200 OK"
    ok.len = . - ok
  
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
    bind_msg.len = . - bind_msg

  client_msg:
    .asciz "Client connected successfully\n"
    client_msg.len = . - client_msg  
