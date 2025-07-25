@;==============================================================================
@;
@;	"garlic_itcm_api.s":	c�digo de las rutinas del API de GARLIC 2.0
@;							(ver "GARLIC_API.h" para descripci�n de las
@;							 funciones correspondientes)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2

	.global _ga_pid
	@;Resultado:
	@; R0 = identificador del proceso actual
_ga_pid:
	push {r1, lr}
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + z�calo
	mov r0, r1, lsr #0x4	@; R0 = PID del proceso actual
	pop {r1, pc}


	.global _ga_random
	@;Resultado:
	@; R0 = valor aleatorio de 32 bits
_ga_random:
	push {r1-r5, lr}
	ldr r0, =_gd_seed
	ldr r1, [r0]			@; R1 = valor de semilla de n�meros aleatorios
	ldr r2, =0x0019660D
	ldr r3, =0x3C6EF35F
	umull r4, r5, r1, r2	@; R5:R4 = _gd_seed * 0x19660D
	add r4, r3				@; R4 += 0x3C6EF35F
	str r4, [r0]			@; guarda la nueva semilla (R4)
	mov r0, r5				@; devuelve por R0 el valor aleatorio (R5)
	pop {r1-r5, pc}


	.global _ga_divmod
	@;Par�metros
	@; R0: unsigned int num
	@; R1: unsigned int den
	@; R2: unsigned int * quo
	@; R3: unsigned int * mod
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si hay error en la divisi�n
_ga_divmod:
	push {r4-r7, lr}
	cmp r1, #0				@; verificar si se est� intentando dividir por cero
	bne .Ldiv_ini
	mov r0, #1				@; c�digo de error
	b .Ldiv_fin2
.Ldiv_ini:
	mov r4, #0				@; R4 es el cociente (q)
	mov r5, #0				@; R5 es el resto (r)
	mov r6, #31				@; R6 es �ndice del bucle (de 31 a 0)
	mov r7, #0xff000000
.Ldiv_for1:
	tst r0, r7				@; comprobar si hay bits activos en una zona de 8
	bne .Ldiv_for2			@; bits del numerador, para evitar el rastreo bit a bit
	mov r7, r7, lsr #8
	sub r6, #8				@; 8 bits menos a buscar
	cmp r7, #0
	bne .Ldiv_for1
	b .Ldiv_fin1			@; caso especial (numerador = 0 -> q=0 y r=0)
.Ldiv_for2:
	mov r7, r0, lsr r6		@; R7 es variable de trabajo j;
	and r7, #1				@; j = bit i-�simo del numerador; 
	mov r5, r5, lsl #1		@; r = r << 1;
	orr r5, r7				@; r = r | j;
	mov r4, r4, lsl #1		@; q = q << 1;
	cmp r5, r1
	blo .Ldiv_cont			@; si (r >= divisor), activar bit en cociente
	sub r5, r1				@; r = r - divisor;
	orr r4, #1				@; q = q | 1;
 .Ldiv_cont:
	sub r6, #1				@; decrementar �ndice del bucle
	cmp r6, #0
	bge .Ldiv_for2			@; bucle for-2, mientras i >= 0
.Ldiv_fin1:
	str r4, [r2]
	str r5, [r3]			@; guardar resultados en memoria (por referencia)
	mov r0, #0				@; c�digo de OK
.Ldiv_fin2:
	pop {r4-r7, pc}


	.global _ga_divmodL
	@;Par�metros
	@; R0: long long * num
	@; R1: unsigned int * den
	@; R2: long long * quo
	@; R3: unsigned int * mod
	@;Resultado
	@; R0: 0 si no hay problema, !=0 si hay error en la divisi�n
_ga_divmodL:
	push {r4-r6, lr}
	ldr r4, [r1]			@; R4 = denominador
	cmp r4, #0				@; verificar si se est� intentando dividir por cero
	bne .LdivL_ini
	mov r0, #1				@; c�digo de error
	b .LdivL_fin
.LdivL_ini:
	ldrd r0, [r0]			@; R1:R0 = numerador
	mov r5, r2				@; R5 apunta a quo
	mov r6, r3				@; R6 apunta a mod
	mov r2, r4
	mov r3, #0				@; R3:R2 = denominador
	bl __aeabi_ldivmod
	strd r0, [r5]
	str r2, [r6]			@; guardar resultados en memoria (por referencia)			
	mov r0, #0				@; c�digo de OK
.LdivL_fin:
	pop {r4-r6, pc}


	.global _ga_printf
	@;Par�metros
	@; R0: char * format
	@; R1: unsigned int val1 (opcional)
	@; R2: unsigned int val2 (opcional)
_ga_printf:
	push {r4, lr}
	ldr r4, =_gd_pidz		@; R4 = direcci�n _gd_pidz
	ldr r3, [r4]
	and r3, #0x3			@; R3 = ventana de salida (z�calo actual MOD 4)
	bl _gg_escribir			@; llamada a la funci�n definida en "garlic_graf.c"
	pop {r4, pc}


	.global _ga_printchar
	@;Par�metros
	@; R0: int vx
	@; R1: int vy
	@; R2: char c
	@; R3: int color
_ga_printchar:
	push {r4, lr}
	add r3, r2, #32			@; R3 = c + 32, se transforma el c�digo de baldosa
							@;	en c�digo ASCII, para que _gg_escribir lo vuelva
							@;	a transformar en c�digo de baldosa; (R3 pierde
							@;	el c�digo de color que se pasa por par�metro,
							@;	pero no importa porque el color no se utiliza)
	mov r2, r1				@; R2 = vy
	mov r1, r0				@; R1 = vx
	ldr r4, =_gd_pidz
	ldr r4, [r4]			@; R4 = _gd_pidz
	ldr r0, =_gi_message	@; R0 = @ string para visualizar con _gg_escribir
	strb r3, [r0, #22]		@; guardar codigo car�cter en posici�n 22 del str.
	and r3, r4, #0x3		@; R3 = n�mero de ventana (num. z�calo % 4)
	bl _gg_escribir
	pop {r4, pc}

_gi_message:
	.asciz "print char (%d, %d) :  \n"


	.align 2
	.global _ga_printmat
	@;Par�metros
	@; R0: int vx
	@; R1: int vy
	@; R2: char *m[]
	@; R3: int color
_ga_printmat:
	push {r4-r5, lr}
	ldr r5, =_gd_pidz		@; R5 = direcci�n _gd_pidz
	ldr r4, [r5]
	and r4, #0xf			@; R4 = ventana de salida (z�calo actual)
	push {r4}				@; pasar 4� par�metro (n�m. ventana) por la pila
	bl _gg_escribir
	add sp, #4				@; eliminar 4� par�metro de la pila
	pop {r4-r5, pc}


	.global _ga_delay
	@;Par�metros
	@; R0: int nsec
_ga_delay:
	push {r2-r3, lr}
	ldr r3, =_gd_pidz		@; R3 = direcci�n _gd_pidz
	ldr r2, [r3]
	and r2, #0xf			@; R2 = z�calo actual
	cmp r0, #0
	bhi .Ldelay1
	bl _gp_WaitForVBlank	@; si nsec = 0, solo desbanca el proceso
	b .Ldelay2				@; y salta al final de la rutina
.Ldelay1:
	cmp r0, #600
	movhi r0, #600			@; limitar el n�mero de segundos a 600 (10 minutos)
	bl _gp_retardarProc
.Ldelay2:
	pop {r2-r3, pc}


	.global _ga_clear
_ga_clear:
	push {r0-r1, lr}
	ldr r1, =_gd_pidz
	ldr r0, [r1]
	and r0, #0xf			@; R0 = z�calo actual
	mov r1, #0				@; R1 = 0 -> 4 ventanas
	bl _gs_borrarVentana
	pop {r0-r1, pc}
	
	
	.global _ga_wait
	@;Par�metres:
	@; R0: �ndex del sem�for a fer wait
	@;Resultat:
	@; R0: 0 si est� ocupat, 1 si ha entrat ara en BLK, 2 si fora de rang
_ga_wait:
    push {lr}         
	cmp r0, #8				@; Si est� fora de rang guardem 2 a r0 i sortim
	blo .LferWait
	mov r0, #2
	b .LforaRangW
.LferWait:
	bl _gp_wait				@; Si est� dins del rang cridem _gp_wait
.LforaRangW:
    pop {pc}        
	
	
	.global _ga_signal
	@;Par�metres:
	@; R0: �ndex del sem�for a fer signal
	@;Resultat:
	@; R0: 0 si est� ocupat, 1 si ha sortit ara de BLK, 2 si fora de rang
_ga_signal:
    push {lr}         
	cmp r0, #8				@; Si est� fora de rang guardem 2 a r0 i sortim
	blo .LferSignal
	mov r0, #2
	b .LforaRangS
.LferSignal:
	bl _gp_signal			@; Si est� dins del rang cridem _gp_signal
.LforaRangS:
    pop {pc}        



.end

