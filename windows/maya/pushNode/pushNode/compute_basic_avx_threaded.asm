;TO NOTE : a couple of things before people go nuts
; 1) this is just an exercise to learn better assembly, no, i won't use something like that in
;    production, also because the compiler is much smarter than i am so no point in that
; 2) here the code is actually slower, the work performed by each thread is not much and 
;    i am destroying and re-creating threads all the time which is riddiculously expensive,
;    but making my pool and managing the threads is not a rabbit hole i am willing to go down now

.data
;microsoft function we are going to use
extern CreateThread: proc
extern malloc: proc
extern free: proc
extern  WaitForMultipleObjects: proc;

reminder dq 0 ;space in memory to store the reminder of the job sudivision
INFINITE dq 0ffffffffh ; infinite for waiting thread
malloc_ptr  dq ? ; dq stands for quad word double precision,dq is jsut the same as qword, aka 64 bit
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

	;building the stack frame
	push rbp;
	mov rbp, rsp

	;here we are pushing the registers that we are going to use
	;RAX, RCX, RDX, R8, R9, R10, R11 are considered volatile and no need to preserve them
	;RBX, RBP, RDI, RSI, RSP, R12, R13, R14, and R15 are non volatile and must be resotred at the end of 
	; the function if it uses them
	;more info at:
	;https://msdn.microsoft.com/en-us/library/6t169e9c.aspx
	;https://msdn.microsoft.com/en-us/library/9z1stfyw.aspx
	push rbx
	push r12
	push r13
	push r14
	push r15

	mov r12, rcx ; copying points pointer
	mov r13, rdx ; copying normal pointer
	mov r14 , r9 ; copying point count

	;computing points per thread, aka point count /4
	mov rdx, 0 ;zeroing rdx for the division
	mov rax, r14 ;loading the number we wish to divide
	mov r15, 4
	div r15 ; we are going to split in 4 threads
		  ; now rax holds the point each thread needs to proces
		  ; rdx holds the reminder, which will be added to last thread
	mov r15, rax; we moved the point count to r15	
	mov reminder, rdx ;since rdx is volatile we store the reminder in the data segment

	;we are going to allocate memory for our params for each thread

	mov rcx, (4*5 )*8; setting the amount of memory we want, 
				  ; we have 4 threads with 4 params each and each is 8 bytes, a qword
	sub rsp , 10h ;here we add some shadow space that microsoft function call might use 
				  ; on the stack to backup registers for restore them later
	call malloc;
	add rsp , 10h ;removing shadow space

	;we should check if the result in rax is 0, aka null, but we are lazy and ignore that for now
	mov malloc_ptr , rax

	;we have the memory we can now allocate parameters for the first thread then call thread
	;thread1
	;since is the first thread we don't have to shift anything
	mov qword ptr[rax] ,r12; pushing mem ptr
	mov qword ptr [rax + 8] ,r13 ;pushing normal ptr
	movd rbx, xmm2 ;moving to general register
	mov qword ptr [rax + 16] ,rbx  ; writing weight
	mov qword ptr [rax + 24] ,r15 ; writing point count

	; lets move the argument pointer to the memory we want
	mov rcx , rax;setupping arguments for function call
	call create_thread_asm	;our function that spawn and setup the thrad
	mov thread_ids_array , rax ;saving the thread id for later use

	;thread2
	mov rax, 32  ;we want to shift by the point count * 8 *4 where 8*4 is the size of four doubles
	mul r15; here we multily by the point count, so we find out how many bytes we need to shift
			;to access the data of the second thread 
	mov r10, rax; moving result into r10, this is the value we want to shift the point pointer for
	;we sum the start position and the offset to get the correct pointer for the points
	add r10, r12; r10 should now hold the shifted pointer for the points
	
	;here we restore the pointer to where we store the thread argument
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
	mov qword ptr [r11 + 16+ (4*8)] ,rbx  ; writing weight
	mov qword ptr [r11 + 24+ (4*8)] ,r15 ; writing point count
	
	;we now need to set rcx to the shifted parameters pointer	
	add r11, 4*8 ;shifting the malloc pointer
	mov rcx , r11 ;setting the shifted pointer as argument for thread spawn
	call create_thread_asm	
	mov thread_ids_array +8, rax ;saving the thread id in the [1] index of our array


	;thread3
	mov rax, 32*2  ;we want to shift by the point count * 8 *4 where 8*4 is the size of four doubles
					;the reason why we multiply by two is that we can do it here as an immediate 
					;value rather than multiply r15 (the point count)
	mul r15; doing the multiply, result will be in rax
	mov r10, rax; moving result into r10, this is the value we want to shift the point pointer for
	add r10, r12; r10 should now hold the shifted pointer for the points
	
	mov r11, malloc_ptr ;restoring argument pointer so we can use for writing

	mov qword ptr[r11 + 0 +(2*4*8)] ,r10; pushing mem ptr for points
	;now we do the same deal BUT for the normals which are shifted by 3 floats each
	mov rax, 12  ;we want to shift by the point count * 8 *4 where 8*4 is the size of four doubles
	mul r15; doing the multiply, result will be in rax
	mov r10, rax; moving result into r10, this is the value we want to shift the point pointer for
	add r10, r13; r10 should now hold the shifted pointer for the points


	mov qword ptr [r11 +  8 + (2*4*8)] ,r10 ;pushing normal ptr
	mov qword ptr [r11 + 16+ (2*4*8)] ,rbx  ; writing weight, rbx still holds the weight
	mov qword ptr [r11 + 24+ (2*4*8)] ,r15 ; writing point count
	
	;we now need to set rcx to the shifted parameters pointer	
	add r11, 2*4*8 ; getting [2] index to the argument array
	mov rcx , r11 ;setting argument pointer for the thread
	call create_thread_asm	
	mov thread_ids_array +16, rax ;saving thread id


	;thread4, last one
	mov rax, 32*3  ;we want to shift by the point count * 8 *4 where 8*4 is the size of four doubles
					;the reason why we multiply by two is that we can do it here as an immediate 
					;value rather than multiply r15 (the point count)
	mul r15; doing the multiply, result will be in rax
	mov r10, rax; moving result into r10, this is the value we want to shift the point pointer for
	add r10, r12; r10 should now hold the shifted pointer for the points
	
	mov r11, malloc_ptr ;restoring argument pointer so we can use for writing

	mov qword ptr[r11 + 0 +(3*4*8)] ,r10; pushing mem ptr for points
	;now we do the same deal BUT for the normals which are shifted by 3 floats each
	mov rax, 12  ;we want to shift by the point count * 8 *4 where 8*4 is the size of four doubles
	mul r15; doing the multiply, result will be in rax
	mov r10, rax; moving result into r10, this is the value we want to shift the point pointer for
	add r10, r13; r10 should now hold the shifted pointer for the points


	mov qword ptr [r11 +  8 + (3*4*8)] ,r10 ;pushing normal ptr
	; xmm2 gets zeroed between when callthread gets called, rbx is not, so the value is still
	; there, it s kinda hacky i should probalby try to save that value properly but hey YOLO
	;movd rbx, xmm2 ;moving to general register
	mov qword ptr [r11 + 16+ (3*4*8)] ,rbx  ; writing weight
	add r15, reminder ;last point count we are adding any possible reminder 
	mov qword ptr [r11 + 24+ (3*4*8)] ,r15 ; writing point count
	
	;mov rax, malloc_ptr 
	
	;we now need to set rcx to the shifted parameters pointer	
	add r11, 3*4*8  ;
	mov rcx , r11 ;
	call create_thread_asm	
	mov thread_ids_array +24, rax ;saving thread id

	;wait for threads to finish
	mov rcx, 4  ;setting we are waiting for 4 threads
	lea rdx, thread_ids_array ;setting the pointer of where the ids are stored
	mov r8 ,1 ;setting true, this arguments tells windows to wait for all threads to finish
	mov r9 , INFINITE ;wait until termination


	;call WaitForSingleObject	
	sub rsp , 10h ;here we add some shadow space  that s what windows like, i am not arguing with that
	call WaitForMultipleObjects ;waiting for threads to be done
	add rsp , 10h


	;free memory
	mov rcx, malloc_ptr ;loading pointer to memory as first argument
	sub rsp , 10h ;shadow space
	call free ;freeing memory
	add rsp , 10h ;removing shadow space

	
	;popping back registers
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx

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

	;setupping stack frame
	push rbp;
	mov rbp, rsp

	push r15 ;saving register
	mov r15, rcx ;backupping rcx
	mov rcx, qword ptr [r15] ;loading point pointer, here we load from where r15 is pointing to
	mov rdx, qword ptr [r15+ 8] ;loading normal pointer pointer
	mov r9, qword ptr [r15+24] ;loading normal pointer pointer
	movd xmm2, qword ptr [r15 +16];loading weight


	vbroadcastsd ymm2, xmm2 ; loading the weight on all 4 slots of the register

	;loop code
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

	pop r15 ;restoring register 15
	;removing stack frame
	mov rsp, rbp
	pop rbp
	ret
	subroutine endp
end
