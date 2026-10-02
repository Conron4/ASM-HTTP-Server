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
  .lcomm socket_fd, 8
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
    movq $6, %rdx # Protocol = tcp see /etc/protocols could be 0 imliped but chooose 6
    syscall

    testq %rax, %rax
    js _badexit

    movq %rax, socket_fd(%rip)
    movq $49, %rax
    movq socket_fd(%rip), %rdi
    movq

    jmp _exit

  _exit:
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

  buffer:
    .fill 64,1,0

  newline:
    .byte 10  
