.code
	zero_array proc
		;rcx holds the pointer of the memory
		;rdx holds how many bytes we wish to clear
		;r8 holds how many bytes at once we want to clear
		cmp rdx,0 ; checking if we got a size zero
		je Exit ; if we do we get out and do nothing

		;here we are going to devide by the amount of bytes we want to apply at once
		; then we loop for the quotient and then handle the reminder in the final stage
		mov rax, rdx  ;loading the size we want to devide for
		mov r9, rdx ;moving the original byte size to r9 to have a backup if needed
				    ;if not i ll remove this
		mov rdx,0 ;cleaering rdx to let it be clear for the division result
		idiv r8 ;now we should have the quotient in rax and reminder in rdx

		ClearLoop: ;label for looping
		mov qword ptr [rcx], 0 ;writing zero to memory; 64bit at the time
		add rcx, r8 ;incrementing by user amount 
		dec rax ;decrementing counter
		jnz ClearLoop ;keep looping if we are not zero

		cmp rdx,0;we check wether we have any reminder to take care of
		je Exit ;if not we go to exit and set return value

		ReminderLoop:
		mov byte ptr [rcx], 0 ;writing zero to memory
		add rcx, 1 ;incrementing one byte
		dec rdx ;decrementing counter
		jnz ReminderLoop; keep looping if we are not zero


		Exit:
			mov rax,1;setting retun status to true
		ret
		Failure:
			mov rax,0;settting failure return status
		ret

	zero_array endp
end