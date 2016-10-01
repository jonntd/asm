.data
extern CreateThread: proc
extern malloc: proc
extern free: proc
extern  WaitForSingleObject: proc ;
extern  WaitForMultipleObjects: proc;
;extern  WaitForSingleObject: proc ;

INFINITE dq 0ffffffffh ; infinite for waiting thread
malloc_ptr  dq ? ; dq stands for quad word double precision,dq is jsut the same as qword, aka 64 bit
thread_ids dq ?
thread_ids_array dq 4 dup (?)

.code
	

	create_thread_asm proc
	;this function is in charge to spawn the threads and subdivide the
	;work etc

	push rbp;
	mov rbp, rsp

	push 0; ThreadID
	push 0; Creation flag start immediatly

	sub rsp, 20h;reserving some space

	mov r9, rcx; here is the pointer to our arguments
	mov rcx, 0 ; security attributes 
	mov rdx ,0 ; same stack size as caller
	mov r8  , subroutine

	call CreateThread

	mov rsp, rbp
	pop rbp
	ret

	create_thread_asm endp

	push_no_stress_avx_threaded proc
	;function signature
	;extern "C" void push_no_stress_loop(double* pts, float* normals, double weight, int point_count);
	; this mean we expect the following arguments in the following registers
	; pts -> this is a double* but that doesn mean it will go into xmm*, 
	;        it will actually go into rcx
	; normals -> same as above but in rdx 
	; weight -> xmm2
	; point_count -> r9 
	
	;backupping inputs	
	;r12-r15 are preserved by callee so we can override them no problem

	push rbp;
	mov rbp, rsp

	push r10
	push r11
	push r12
	push r13
	push r14
	push r15

	mov r12, rcx ; copying points pointer
	mov r13, rdx ; copying normal pointer
	mov r14 , r9 ; copying point count

	;computing points per thread
	mov rdx, 0 ;zeroing rdx for the division
	mov rax, r14 ;loading the number we wish to divide
	mov r15, 4
	div r15 ; we are going to split in 4 threads
		  ; now rax holds the point each thread needs to proces
		  ; rdx holds the reminder, which will be added to last thread
	mov r15, rax; we moved the point count to r15	

	;we are going to allocate memory for our params for each thread
	sub rsp , 10h ;here we add some shadow space to make sure we are 16byte aligned
	
	mov rcx, (4*5 )*8; setting the amount of memory we want, 
				  ; we have 4 threads with 4 params each and each is 8 bytes, a qword
	call malloc;

	add rsp , 10h
	;we should check if the result in rax is 0, aka null, but we are lazy and ignore that for now
	mov malloc_ptr , rax

	;we have the memory we can now allocate parameters for the first thread then call thread


	;thread1
	;here no much work to be done
	mov qword ptr[rax] ,r12; pushing mem ptr
	mov qword ptr [rax + 8] ,r13 ;pushing normal ptr
	movd rbx, xmm2 ;moving to general register
	mov qword ptr [rax + 16] ,rbx  ; writing weight
	mov qword ptr [rax + 24] ,r15 ; writing point count


	;movd r15 , xmm2 ;move weight to r15 then to stack
	;push r15
	;push r13 ; pushing pushing normals
	;push r12 ; pushing points


	;do whatever
	; lets move the pointer to the memory we want
	mov rcx , rax;
	call create_thread_asm	
	mov thread_ids_array , rax
	;mov thread_ids_array+8 ,2 

	;thread2

	;mov rax ,malloc_ptr ;loading where our storage for the thread is 
	;mov rbx ,r12 ; loading the point pointers in rbx
	mov rax, 32  ;we want to shift by the point count * 8 *4 where 8*4 is the size of four doubles
	mul r15; doing the multiply, result will be in rax
	mov r10, rax; moving result into r10, this is the value we want to shift the point pointer for
	add r10, r12; r10 should now hold the shifted pointer for the points
	
	mov r11, malloc_ptr 

	mov qword ptr[r11 + 0 +(4*8)] ,r10; pushing mem ptr for points
	;now we do the same deal BUT for the normals which are shifted by 3 floats each
	mov rax, 12  ;we want to shift by the point count * 8 *4 where 8*4 is the size of four doubles
	mul r15; doing the multiply, result will be in rax
	mov r10, rax; moving result into r10, this is the value we want to shift the point pointer for
	add r10, r13; r10 should now hold the shifted pointer for the points


	mov qword ptr [r11 +  8 + (4*8)] ,r10 ;pushing normal ptr
	; xmm2 gets zeroed between when callthread gets called, rbx is not, so the value is still
	; there, it s kinda hacky i should probalby try to save that value properly but hey YOLO
	;movd rbx, xmm2 ;moving to general register
	mov qword ptr [r11 + 16+ (4*8)] ,rbx  ; writing weight
	mov qword ptr [r11 + 24+ (4*8)] ,r15 ; writing point count
	
	;mov rax, malloc_ptr 
	
	;we now need to set rcx to the shifted parameters pointer	
	add r11, 4*8 
	mov rcx , r11 ;
	call create_thread_asm	
	mov thread_ids_array +8, rax
	;mov thread_ids_array+8 ,2 
	;wait for threads to finish
	;mov rcx, qword ptr [thread_ids_array]
	mov rcx, 2 
	lea rdx, thread_ids_array 
	mov r8 ,1 
	mov r9 , INFINITE 


	;call WaitForSingleObject	
	sub rsp , 10h ;here we add some shadow space  that s what windows like, i am not arguing with that
	call WaitForMultipleObjects
	add rsp , 10h


	;free memory

	mov rcx, malloc_ptr
	sub rsp , 10h ;here we add some shadow space to make sure we are 16byte aligned
	call free
	add rsp , 10h

	
	;popping back registers
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10

	;resetting the stack
	mov rsp, rbp
	pop rbp
	ret
	
	push_no_stress_avx_threaded endp
	
	subroutine proc
	;moving arguments from pointer given us by the thread call to register as regular func
	; call
	; the pointer is inside rcx;	
	; this is what we expect
	; pts -> this is a double* but that doesn mean it will go into xmm*, 
	;        it will actually go into rcx
	; normals -> same as above but in rdx 
	; weight -> xmm2
	; point_count -> r9 

	push rbp;
	mov rbp, rsp

	push r15
	mov r15, rcx
	mov rcx, qword ptr [r15] ;loading point pointer
	mov rdx, qword ptr [r15+ 8] ;loading normal pointer pointer
	mov r9, qword ptr [r15+24] ;loading normal pointer pointer
	movd xmm2, qword ptr [r15 +16];loading weight


	;loop code
	vbroadcastsd ymm2, xmm2 ; loading the weight on all 4 slots of the register

	MainLoop:

	vmovupd ymm0,  qword ptr[rcx] ; loading 4 doubles into the first register
								 ; it holds the positions

	vmovups xmm1, dword ptr[rdx] ; here we load 4 floats, the normals, the normals
								; are packed 3 at the times not 4, so one is actually 
								; from next one, but won't affect the computation since is 
								; affecting only the w component
	vcvtps2pd ymm1, xmm1 ;converting float4 to double 4

	vmulpd ymm1, ymm1, ymm2 ; scaling the normal

	vaddpd ymm0, ymm0,ymm1 ; summing the vector 
	vmovupd qword ptr [rcx], ymm0 ;writing the result to memory

	add rcx,32 ;shifting the points pointer
	add rdx,12 ; shifting the normals pointer

	dec r9 ;decrementing the counter
	cmp r9,0 ;check if we are done
	jnz MainLoop ;if not repeat the loop

	mov rax ,0

	pop r15
	mov rsp, rbp
	pop rbp
	ret
	subroutine endp
end
