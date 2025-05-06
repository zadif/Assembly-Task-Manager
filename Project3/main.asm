
include functionHeaders.inc

.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD
string_print MACRO str1
   mov edx, offset str1
   call WriteString
   call Crlf
ENDM
.data
    str1 byte "Following are options which you can perform: ",0
    str2 byte "Press 1 to view all process",0
    str3 byte "Press 2 to  terminate process",0
    str4 byte "Press 3 to check battery health",0
    str5 byte "Press 4 to  view system specs",0
    str6 byte "Press 8 to  exit",0
    str7 byte "Enter your choice:   ",0
    str8 byte "Want to use task manager again? ",0
    str9 byte "Press 1  to continue , 0 to not  :   ",0
    str10 byte "Press 5 View OS info  and windows running time ",0
    str11 byte "Press 6 to view all harddisks ",0
    str12 byte "Press 7 information about addresses",0

    input1 dd 0
    input2 dd 0

.code
main PROC
    whileLoop:
            string_print str1
            string_print str2
            string_print str3
            string_print str4
            string_print str5
            string_print str10
            string_print str11
            string_print str12

            string_print str6
            mov edx,offset str7
            call writeString
            call readInt
            call crlf
            mov input1,eax

            cmp eax,1
            je view_processes
            cmp eax,2
            je terminate_proc
            cmp eax,3
            je battery_health
            cmp eax,4
           je system_specs
           
            cmp eax,6
            je diskInfoTag
            cmp eax,5
            je OSinfo
              cmp eax,7
            je addressing
            cmp eax,8
            je exiting


     view_processes:
    call viewAllProcess
    jmp  tag

terminate_proc:
    ; Placeholder for terminate process 
    call viewAllProcess
   call terminateProcess2 
    jmp  tag

battery_health:
    ; Placeholder for battery health check
    call BatteryCheck
    jmp  tag

system_specs:
    ; Placeholder for system specs
    call systemSpecs
    jmp  tag

    OSinfo:
    call displayOsInfo
      jmp  tag

      diskInfoTag:
      call diskInfo 
      jmp tag

      addressing:
      call addressesInfo
      jmp tag


        tag:
        call crlf
            string_print str8
            mov edx, offset str9
            call writeString
            call readInt
            mov input2,eax
            call crlf

            cmp input2,1
            je whileLoop

       exiting: 

    INVOKE ExitProcess, 0
main ENDP


END main