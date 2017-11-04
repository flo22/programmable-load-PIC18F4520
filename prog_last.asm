; Datei: 		prog_last.ASM
; Erstellt von:	Florian Müller
; Erstellt am:  07.01.2011
;
; Beschreibung:     
; PIC 18f4550 steuert die LAST sowie Kommunikation über RS232 und LCD
; Quarz = 16MHz
; Baudrate sowie Adresse wird über Dip-Taster (4Bit) abgefragt
; 

     
;**********************************************************************************
; Include-Dateien
;**********************************************************************************
	LIST p=18F4520             		; Der Prozessortyp wird festgelegt 
	include <P18F4520.inc>      	; Headerdatei mit Registerdaten
;**********************************************************************************
; Configuration erfolgt über die IDE MPLAB -> Configure -> Configuration Bits	
;**********************************************************************************

;**********************************************************************************
; Variablennamen vergeben
;**********************************************************************************

bsr_temp	Equ		0x83			; temporäres Bankregister
w_temp      Equ		0x84	 		; temporäres Arbeitsregister
status_temp Equ     0x85			; temppräres Statusregister

#define	loop1		0x86			; Zeitschleifenwert der 100us Schleife
#define loop2		0x87			; Zeitschleifenwert des Multiplikator der 100us Schleife
#define lcd_data	0x88			; lcd-Daten, die zum Display uebertragen werden
#define lcd_data2	0x89			; lcd-daten, die um 3 Stellen nach rechts geschoben werden
#define lcd_status	0x90			; busy-flag auslesen
#define lcd_rs_on	0x91			; Setzt Steuerwort auf 1 oder 0
#define lcd_startup 0x92			; Startup-time für das LCD
#define	ad_low		0x93			; low-nibble des AD-Werts
#define	ad_high		0x94			; high-nibble des AD-Werts

#define	address		0x95			; Adresse der Platine
#define rs232_byte0	0x96
#define rs232_byte1	0x97
#define rs232_byte2	0x98
#define rs232_byte3	0x99
#define rs232_byte4	0x9a
#define rs232_byte5	0x9b
#define rs232_byte6	0x9c
#define rs232_byte7	0x9d
#define rs232_byte8	0x9e
#define	counter		0x9f
#define befehl		0xa0
#define	mode		0xa1			; Display Mode auswählen
#define	I_low		0xa2			; low Byte der Strombegrenzung
#define I_high		0xa3			; high Byte der Strombegrenzung
#define	U_low		0xa4			; low Byte der Spannungsbegrenzung
#define	U_high		0xa5			; high Byte der Spannungsbegrenzung
#define	R_low		0xa6			; low Byte des Widerstandswerts
#define	R_high		0xa7			; high Byte des Widerstandswerts
#define Temp		0xa8			; Temperaturwert
#define P_low		0xa9			; low Byte der Leistung
#define	P_high		0xaa			; high Byte der Leistung
#define	mini_loop	0xab			; loop zum widerholen von Anweisungen
#define	bcd_U_1		0xac			; Einer BCD U
#define bcd_U_2		0xad			; Zehner BCD U
#define bcd_U_3		0xae			; Hunderter BCD U
#define bcd_U_4		0xaf			; Tausender BCD U
#define	bcd_I_1		0xb0			; Einer BCD I
#define bcd_I_2		0xb1			; Zehner BCD I
#define bcd_I_3		0xb2			; Hunderter BCD I
#define bcd_I_4		0xb3			; Tausender BCD I
#define	bcd_T_1		0xb4			; Einer BCD T
#define bcd_T_2		0xb5			; Zehner BCD T
#define bcd_temp	0xb6			; temporaerer bcd Speicher

#define ad_temp		0xb8			; Temp Variable von ad_low und ad_high
#define ad_temp_l	0xba			; Temp der ad low
#define bcd_R_1		0xbb			; Einer BCD R
#define bcd_R_2		0xbc			; Zehner BCD R
#define bcd_R_3		0xbd			; Hunderter BCD R
#define bcd_R_4		0xbe			; Tausender BCD R
#define bcd_R_5		0xbf			; Zehn-Tausender BCD R
#define U_ist_1		0xc0			; aktuelle U Einer
#define U_ist_2		0xc1			; aktuelle U Zehner
#define U_ist_3		0xc2			; aktuelle U Hunderter
#define U_ist_4		0xc3			; aktuelle U Tausender
#define I_ist_1		0xc4			; aktuelle I Einer			
#define I_ist_2		0xc5			; aktuelle I Zehner
#define I_ist_3		0xc6			; aktuelle I Hunderter
#define I_ist_4		0xc7			; aktuelle I Tausender
#define	loop3		0xc8			; lange_pause loop



#define mode_0		mode, 0
#define mode_U		mode, 1
#define mode_I		mode, 2
#define mode_P		mode, 3
#define mode_T		mode, 4
#define mode_R		mode, 5

#define lcd_port	PORTD
#define lcd_enable	PORTD,2
#define lcd_rs		PORTD,0
#define lcd_rw		PORTD,1
#define	lcd_tris	TRISD

#define t2_relais	PORTC,1		; Relais zur Spannungsmessung an/aus
#define t2_tris		TRISC,1

#define t1_relais	PORTD,7		; Relais zur Last an/aus
#define t1_tris		TRISD,7

#define t3_luefter	PORTB,3		; Lüfter an / aus
#define	t3_tris		TRISB,3	

#define	TXD			PORTC,6		; Transmit Pin
#define RXD			PORTC,7		; Receive Pin

#define int_tris	TRISB		; Interrupt der Folientastatur
#define	int4		PORTB,4		; Taster-Interrupt 
#define	int5		PORTB,5		; Taster-Interrupt

#define ad_tris		TRISA		
#define ad_port		PORTA		; AD-Port

#define baud0_tris	TRISC, 0
#define baud0_bit	PORTC, 0	; 1. Bit der Baudrate
#define baud1_tris	TRISE, 0
#define baud1_bit	PORTE, 0	; 2. Bit der Baudrate

#define add0_tris	TRISE, 1
#define add0_bit	PORTE, 1	; 1. Bit der Adresse
#define add1_tris	TRISE, 1
#define add1_bit	PORTE, 1	; 2. Bit der Adresse


;__________________________________________________________________________________

;**********************************************************************************
;Programmcode:
;**********************************************************************************
    org    	0x00                 ; die Startadresse nach Reset ist 0, hier startet der PIC
    goto   	main                 ; Sprung zum Hauptprogramm

;**********************************************************************************
;Interruptbehandlungsroutine
;**********************************************************************************
  	org		0x08				 ; die Startadresse des Interrupts

isr
	movwf 	w_temp 					; Arbeitsregister retten
	movff 	STATUS,  status_temp 	; Status retten
	movff 	BSR,	 bsr_temp 		; Bank retten
	banksel RCREG
	
	btfsc	PIR1,	RCIF			; wenn RX int von RS232
	goto	rs232_int				; RS232 Byte auswerten

	btfsc	INTCON, INT0IF			; wenn int0 auslöste
	goto	isr_up					; hochzählen

	btfsc	INTCON3, INT1IF			; wenn int1
	goto	isr_down				; runterzählen

	btfsc	INTCON3, INT2IF			; wenn int2
	goto	isr_mode				; moduswechsel

	btfsc	int4					; wenn int4
	goto	isr_loc					; 

	btfsc	int5					; wenn int5
	goto	isr_onoff				; 

isr_end
	banksel	INTCON
	bcf		PIR1,	RCIF	; Receive Interrupt Flag löschen
	bcf		INTCON,	RBIF	; Int-Flag löschen
	bcf		INTCON, TMR0IF	; Timer0-Flag löschen
	bcf		INTCON, INT0IF	; External-Flag löschen
	bcf		INTCON3, INT1IF	; int1 flag löschen
	bcf		INTCON3, INT2IF	; int2 flag löschen
	bcf		PIR1,	SSPIF	; transmission flag
	bcf		PIR1,	ADIF	; AD-flag löschen
	bcf		PIR1,	PSPIF	; parallel-slave flag löschen
	
	movff 	bsr_temp, 	BSR 	; bsr wiederherstellen
	movf 	w_temp, 	W 		; w wiederherstellen
	movff	status_temp, STATUS ; status wiederherstellen
	retfie						; Ende der ist

;**********************************************************************************
; RS232 Schnittstelle: Empfangen und auswerten
; Befehle: Iset, Uset, Rset, Rout, Iout, Uout, Tout, On, Off
;**********************************************************************************
rs232_int
	banksel	RCREG
	movf	RCREG, w			; RS-232 Datenbyte entnehmen
	clrf	RCREG
	banksel	rs232_byte0
	movwf	rs232_byte0			; frame abspeichern
	movlw	0x00
	cpfseq	counter				; Addresse abfragen ?
	goto	count_1
	
	movf	address, w			; Adresse in w schreiben
	cpfseq  rs232_byte0			;
	goto	discard				; alles verwerfen
	incf	counter, 1			; Bytezähler um 1 erhöhen
	goto	rs232_int_end

count_1
	movlw	0x01
	cpfseq	counter
	goto	count_2
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte1
	goto	rs232_int_end		;
count_2
	movlw	0x02
	cpfseq	counter
	goto	count_3
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte2			;
	movlw	'N'
	cpfseq	rs232_byte2
	goto	rs232_int_end		;
	bsf		t3_luefter			; Luefter anschalten zur Kuehlung
	bsf		t1_relais			; Relais 1 schalten !! Last freigeben
	banksel	rs232_byte0
	clrf	rs232_byte0
	goto	verarbeiten
count_3
	movlw	0x03
	cpfseq	counter
	goto	count_4
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte3			;
	movlw	'F'
	cpfseq	rs232_byte3
	goto	rs232_int_end		;
	bcf		t1_relais			; Relais 1 ausschalten !! Last aus
	banksel	rs232_byte0
	clrf	rs232_byte0
	goto	verarbeiten			;
count_4
	movlw	0x04
	cpfseq	counter
	goto	count_5
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte4			;
	movlw	'u'
	cpfseq	rs232_byte3	
	goto	rs232_int_end		;
	clrf	rs232_byte0
	goto	verarbeiten
count_5
	movlw	0x05
	cpfseq	counter
	goto	count_6
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte5			;
	goto	rs232_int_end		;
count_6
	movlw	0x06
	cpfseq	counter
	goto	count_7
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte6			;
	goto	rs232_int_end		;
count_7
	movlw	0x07
	cpfseq	counter
	goto	count_8
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte7			;
	goto	rs232_int_end		;
count_8
	movlw	0x08
	cpfseq	counter
	goto	count_9
	incf	counter, 1			; Bytezähler um 1 erhöhen
	movf	rs232_byte0, w		;
	movwf	rs232_byte8			;
	goto	rs232_int_end		;
count_9
	movlw	0x09
	cpfseq	counter
	goto	discard
	incf	counter, 1			; Bytezähler um 1 erhöhen
	goto	rs232_int_end		;

discard
	banksel counter
	clrf	counter

rs232_int_end
	movlw	0x0a
	cpfseq	counter
	goto	isr_end				; Ende der isr

verarbeiten
	movf	rs232_byte1, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte2, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte3, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte4, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte5, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte6, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte7, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte8, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	movf	rs232_byte0, w		; zur Bestätigung
	call	rs232_ausgabe		; gebe Daten an RS232 aus
	
auswertung
	banksel	rs232_byte1
	movlw	'I'
	cpfseq	rs232_byte1
	goto	not_I
	movlw	's'
	cpfseq	rs232_byte2
	goto	not_Iset
	call	I_set
	goto	speicher_freigeben
not_Iset
	call	I_out
	goto	speicher_freigeben
not_I
	movlw	'U'
	cpfseq	rs232_byte1
	goto	not_IU
	movlw	's'
	cpfseq	rs232_byte2
	goto	not_Uset
	call	U_set
	goto	speicher_freigeben
not_Uset
	call	U_out
	goto	speicher_freigeben
not_IU
	movlw	'R'
	cpfseq	rs232_byte1
	goto	not_IUR
	movlw	's'
	cpfseq	rs232_byte2
	goto	not_Rset
	call	R_set
	goto	speicher_freigeben
not_Rset
	call	R_out
	goto	speicher_freigeben
not_IUR
	movlw	'P'
	cpfseq	rs232_byte1
	goto	not_IURP
	movlw	'o'
	cpfseq	rs232_byte2
	goto	speicher_freigeben
	call	P_out
	goto	speicher_freigeben
not_IURP
	movlw 	'T'
	cpfseq	rs232_byte1
	goto	speicher_freigeben
	movlw	'o'
	cpfseq	rs232_byte2
	goto	speicher_freigeben
	call	T_out
	goto	speicher_freigeben	

speicher_freigeben
	banksel	rs232_byte0
	clrf	rs232_byte0
	clrf	rs232_byte1	
	clrf	rs232_byte2	
	clrf	rs232_byte3	
	clrf	rs232_byte4	
	clrf	rs232_byte5	
	clrf	rs232_byte6	
	clrf	rs232_byte7	
	clrf	rs232_byte8	
	goto	discard				; counter löschen

I_set							; Strombegrenzung einstellen
	banksel	rs232_byte5
	movf	rs232_byte5, w
	banksel	bcd_I_4
	movwf	bcd_I_4
	banksel	rs232_byte6
	movf	rs232_byte6, w
	banksel	bcd_I_3
	movwf	bcd_I_3
	banksel rs232_byte8
	movf	rs232_byte8, w
	banksel	bcd_I_2
	movwf	bcd_I_2
	banksel rs232_byte0
	movf	rs232_byte0, w
	banksel	bcd_I_1
	movwf	bcd_I_1	
	return

I_out							; aktueller Stromwert ausgeben
	banksel	I_ist_4
	movf	I_ist_4, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	I_ist_3
	movf	I_ist_3, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	I_ist_2
	movf	I_ist_2, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	I_ist_1
	movf	I_ist_1, w
	iorlw	0x30
	call	rs232_ausgabe
	return

U_set							; Maximale vorgesehene Spannung wird festgelegt
	banksel	rs232_byte5
	movf	rs232_byte5, w
	banksel	bcd_U_4
	movwf	bcd_U_4
	banksel	rs232_byte6
	movf	rs232_byte6, w
	banksel	bcd_U_3
	movwf	bcd_U_3
	banksel rs232_byte8
	movf	rs232_byte8, w
	banksel	bcd_U_2
	movwf	bcd_U_2
	banksel rs232_byte0
	movf	rs232_byte0, w
	banksel	bcd_U_1
	movwf	bcd_U_1	
	return

U_out							; Aktuelle Spannung wird ausgegeben
	banksel	U_ist_4
	movf	U_ist_4, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	U_ist_3
	movf	U_ist_3, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	U_ist_2
	movf	U_ist_2, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	U_ist_1
	movf	U_ist_1, w
	iorlw	0x30
	call	rs232_ausgabe
	return

R_set							; Widerstandswert wird festegelegt
	banksel	rs232_byte5
	movf	rs232_byte5, w
	banksel	bcd_R_5
	movwf	bcd_R_5
	banksel	rs232_byte6
	movf	rs232_byte6, w
	banksel	bcd_R_4
	movwf	bcd_R_4
	banksel	rs232_byte7
	movf	rs232_byte7, w
	banksel	bcd_R_3
	movwf	bcd_R_3
	banksel rs232_byte8
	movf	rs232_byte8, w
	banksel	bcd_R_2
	movwf	bcd_R_2
	banksel rs232_byte0
	movf	rs232_byte0, w
	banksel	bcd_R_1
	movwf	bcd_R_1
	return

R_out							; Aktueller eingestellter Widerstandswert wird ausgegeben
	banksel bcd_R_5
	movf	bcd_R_5, w
	call	rs232_ausgabe
	banksel bcd_R_4
	movf	bcd_R_4, w
	call	rs232_ausgabe
	banksel bcd_R_3
	movf	bcd_R_3, w
	call	rs232_ausgabe
	banksel bcd_R_2
	movf	bcd_R_2, w
	call	rs232_ausgabe
	banksel bcd_R_1
	movf	bcd_R_1, w
	call	rs232_ausgabe
	return

P_out							; Aktuelle Leistung wird ausgegeben
	banksel	I_ist_4
	movf	I_ist_4, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	I_ist_3
	movf	I_ist_3, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	I_ist_2
	movf	I_ist_2, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	I_ist_1
	movf	I_ist_1, w
	iorlw	0x30
	call	rs232_ausgabe
	movlw	'*'
	call	rs232_ausgabe
	banksel	U_ist_4
	movf	U_ist_4, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	U_ist_3
	movf	U_ist_3, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	U_ist_2
	movf	U_ist_2, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel	U_ist_1
	movf	U_ist_1, w
	iorlw	0x30
	call	rs232_ausgabe
	return

T_out							; Aktuelle Temeratur wird ausgegeben
	banksel bcd_T_2
	movf	bcd_T_2, w
	iorlw	0x30
	call	rs232_ausgabe
	banksel bcd_T_1
	movf	bcd_T_1, w
	iorlw	0x30
	call	rs232_ausgabe
	movlw	'C'
	call	rs232_ausgabe
	return
;__________________________________________________________________________________

;**********************************************************************************
; Interrupt der Taster an der Frontfolie
;**********************************************************************************
isr_onoff							; An-Ausschalten mit der Frontplatte
;	bsf		t3_luefter				; Luefter zur Kuehlung anschalten				****************************** TEST !!!
	comf	t2_relais				; 
	movlw	.100
	call	pause					; Taster entprellen
	goto	isr_end

isr_mode							; Modus Auswahl der Frontplatte
	banksel	mode
	btfsc	mode_R
	goto	mode_reset
	rlcf	mode, 1
	goto	isr_mode_end
mode_reset							
	clrf	mode
	bsf		mode_0
isr_mode_end		
	movlw	.100
	call	pause					; Taster entprellen	
	goto	isr_end

isr_loc								; loc Umschaltung auf ein Locales Event
	movlw	.100
	call	pause					; Taster entprellen				
	goto	isr_end
;*******************************************************************************************
isr_up								; hochzählen / Inkrementieren
	banksel	mode
	btfsc	mode_U
	goto	U_up
	btfsc	mode_I
	goto	I_up
	btfsc	mode_R
	goto	R_up
	goto	isr_up_end
	
U_up
	banksel	bcd_U_3
	movlw	0x39
	cpfseq  bcd_U_3
	goto	inc_U_3
	movlw	0x30
	movwf	bcd_U_3
	movlw	0x33
	cpfseq	bcd_U_4
	goto	inc_U_4
	goto	isr_up_end
inc_U_3
	movlw	0x33
	cpfseq	bcd_U_4
	goto	inc_U_3_go
	goto	isr_up_end
inc_U_3_go
	incf	bcd_U_3
	goto	isr_up_end
inc_U_4
	incf	bcd_U_4
	goto	isr_up_end

I_up
	banksel	bcd_I_2
	movlw	0x39
	cpfseq  bcd_I_2
	goto	inc_I_2
	movlw	0x30
	movwf	bcd_I_2
	movlw	0x39
	cpfseq	bcd_I_3
	goto	inc_I_3
	goto	isr_up_end
inc_I_2
	movlw	0x39
	cpfseq	bcd_I_3
	goto	inc_I_2_go
	goto	isr_up_end
inc_I_2_go
	incf	bcd_I_2
	goto	isr_up_end
inc_I_3
	incf	bcd_I_3
	goto	isr_up_end

R_up
	banksel bcd_R_2
	movlw	0x39
	cpfseq  bcd_R_2
	goto	inc_R_2
	movlw	0x30
	movwf	bcd_R_2
	movlw	0x39
	cpfseq	bcd_R_3
	goto	inc_R_3
	goto	isr_up_end
inc_R_2
	movlw	0x39
	cpfseq	bcd_R_3
	goto	inc_R_2_go
	goto	isr_up_end
inc_R_2_go
	incf	bcd_R_2
	goto	isr_up_end
inc_R_3
	incf	bcd_R_3
	goto	isr_up_end

isr_up_end
	movlw	.100
	call	pause					; Taster entprellen	
	goto	isr_end
;*************************************************************************************
isr_down							; runterzählen / Dekrementieren
	banksel	mode
	btfsc	mode_U
	goto	U_down
	btfsc	mode_I
	goto	I_down
	btfsc	mode_R
	goto	R_down
	goto	isr_down_end
	
U_down
	banksel	bcd_U_3
	movlw	0x30
	cpfseq  bcd_U_3
	goto	dec_U_3
	movlw	0x30
	cpfseq	bcd_U_4
	goto	dec_U_4
	goto	isr_up_end
dec_U_3
	decf	bcd_U_3
	goto	isr_up_end
dec_U_4
	movlw	0x39
	movwf	bcd_U_3
	decf	bcd_U_4
	goto	isr_down_end

I_down
	banksel	bcd_I_2
	movlw	0x30
	cpfseq  bcd_I_2
	goto	dec_I_2
	movlw	0x30
	cpfseq	bcd_I_3
	goto	dec_I_3
	goto	isr_up_end
dec_I_2
	decf	bcd_I_2
	goto	isr_up_end
dec_I_3
	movlw	0x39
	movwf	bcd_I_2
	decf	bcd_I_3
	goto	isr_down_end

R_down
	banksel bcd_R_2
	movlw	0x30
	cpfseq  bcd_R_2
	goto	dec_R_2
	movlw	0x30
	cpfseq	bcd_R_3
	goto	dec_R_3
	goto	isr_up_end
dec_R_2
	decf	bcd_R_2
	goto	isr_up_end
dec_R_3
	movlw	0x39
	movwf	bcd_R_2
	decf	bcd_R_3
	goto	isr_down_end

isr_down_end
	movlw	.100
	call	pause					; Taster entprellen	
	goto	isr_end	
;__________________________________________________________________________________


;**********************************************************************************
;Hauptprogramm
;**********************************************************************************
main
	call 	init_system			; PIC wird initialisiert
	call    lcd_init			; LCD wird initialisiert

	call	dip_abfrage			; Baudrate und Adresse werden abgefragt

loop							; Endlosschleife
	call		ad_wandeln		; AD-Wandlung
	call		mode_auswahl	; Mode-Auswahl der Frontplatte
	call		lange_pause		; 1s Pause
		
	goto		loop
;__________________________________________________________________________________

;**********************************************************************************
; AD-Wandlung zum Messen von Spannung, Strom und Temperatur
;**********************************************************************************
ad_wandeln
	banksel	ADCON0
	bcf 	ADCON0, CHS0
	bcf 	ADCON0, CHS1
	bcf 	ADCON0, CHS2
	bcf 	ADCON0, CHS3		; Channel 0 Spannungs-Messung an RA0
	call	ad_wandeln_go

	call	bcd_wandeln_U		; Wandelt die AD Messwerte in BCD um

	call	bcd_wandeln_I		; Wandelt die AD Messwerte in BCD um

	call	bcd_wandeln_T		; Wandelt die AD Messwerte in BCD um
	
	return

ad_wandeln_go
	movlw 	0xff
	call 	pause				; Pause bei Channel Wechsel sowie Messung
	banksel	ADCON0
	bsf		ADCON0, GO			; startet den AD Wandler
warten
	btfsc	ADCON0, GO
	goto	warten				; wartet bis AD-Wandlung fertig ist

	movlw 	0xff
	call 	pause

	banksel	ADRESL
	movf	ADRESL, w			; low Byte der Wandlung in w
	banksel	ad_low
	movwf	ad_low

	movf	ad_low, w			; *************************************************** TEST!!
	andlw	0x0f
	iorlw	0x30
	call	rs232_ausgabe

	swapf	ad_low, w
	andlw	0x0f
	iorlw	0x30
	call	rs232_ausgabe
	

	banksel	ADRESH
	movf	ADRESH, w			; high Byte der Wandlung in w
	banksel ad_high
	andlw	0x03				; maskieren, da nur die letzten beiden Bits info enthalten
	movwf 	ad_high
	
	movf	ad_high, w			; ************************************************************ TEST !!!
	iorlw	0x30
	call	rs232_ausgabe
	movlw	'X'
	call	rs232_ausgabe
	return	
;__________________________________________________________________________________


;**********************************************************************************
; BCD-Wandlung der gemessenen AD-Werte
;**********************************************************************************
bcd_wandeln_U
	banksel	U_ist_1
	clrf	U_ist_1
	clrf	U_ist_2
	clrf	U_ist_3
	clrf	U_ist_4				; löschen der alten Werte
bcd_wandeln_multi
	banksel	ad_low
	movf	ad_low, w
	mullw	0x03
	banksel	PRODL
	movf	PRODL, w
	banksel	ad_low
	movwf	ad_low
	banksel	PRODH
	movf	PRODH, w
	banksel	ad_temp_l
	movwf	ad_temp_l
	banksel ad_high
	movf	ad_high, w
	mullw	0x03
	banksel PRODL
	movf	PRODL, w
	banksel	ad_high
	movwf	ad_high
	banksel	ad_temp_l
	movf	ad_temp_l, w
	banksel	ad_high
	addwf	ad_high, 1		
bcd_wandeln_U1
	banksel	STATUS
	bcf		STATUS, N			; negative bit löschen
	banksel	ad_low
	movf	ad_low, w
	sublw	0x0a				; subtrahiert 10 vom W Register
	banksel	STATUS
	btfsc	STATUS, N
	goto	bcd_wandeln_U2		; Wenn negatives Ergebnis ->
	banksel	ad_low
	movwf	ad_low
	movlw	0x00
	cpfseq	ad_low
	goto	inc_bcd_U
	movlw	0x00
	cpfseq	ad_high
	goto	inc_bcd_U
	goto	bcd_wandeln_U_end
inc_bcd_U
	movlw	0x09
	cpfseq	U_ist_2
	goto	inc_bcd_U_2
	clrf	U_ist_2
	movlw	0x09
	cpfseq	U_ist_3
	goto	inc_bcd_U_3
	clrf	U_ist_3
	movlw	0x09
	cpfseq	U_ist_4
	goto	inc_bcd_U_4
	clrf	U_ist_4
	goto	bcd_wandeln_U1

inc_bcd_U_4
	incf	U_ist_4				; 4. Stelle von BCD inkrementieren
	goto	bcd_wandeln_U1
inc_bcd_U_3	
	incf	U_ist_3				; 3. Stelle von BCD inkrementieren
	goto	bcd_wandeln_U1
inc_bcd_U_2	
	incf	U_ist_2				; 2.Stelle von BCD inkrementieren
	goto	bcd_wandeln_U1

bcd_wandeln_U2
	banksel	ad_temp
	movwf	ad_temp
	banksel	ad_high
	movlw	0x00
	cpfseq	ad_high
	goto	bcd_wandeln_U3
	goto	bcd_wandeln_U4

bcd_wandeln_U3
	decf	ad_high
	banksel	ad_temp
	movf	ad_temp, w
	banksel	ad_low
	movwf	ad_low
	goto	inc_bcd_U

bcd_wandeln_U4
	movf	ad_low, w
	banksel	U_ist_1
	movwf	U_ist_1				; 1. Stelle von BCD = REST
	goto	bcd_wandeln_U_end

bcd_wandeln_U_end
	return

bcd_wandeln_I
	return

bcd_wandeln_T
	return
;__________________________________________________________________________________


;**********************************************************************************
; Konfiguration der Baudrate sowie die Adresse der Platine
;**********************************************************************************
dip_abfrage
	btfsc	baud0_bit
	goto	baud_x1
	btfsc	baud1_bit
	goto	baud_10_set
	goto	baud_00_set
baud_x1
	btfsc	baud1_bit
	goto	baud_11_set
	goto	baud_01_set
baud_00_set
	bcf		TXSTA,	BRGH	; High-Speed RS 232 aus und teiler auf 64
	bcf 	BAUDCON, BRG16	; nur 1 Register SPBRG
	movlw	.25
	movwf	SPBRG			; RS 232 Speed auf 9600 Baud stellen
	goto	add_set
baud_01_set
	bcf		TXSTA,	BRGH	; High-Speed RS 232 aus und teiler auf 64
	bcf 	BAUDCON, BRG16	; nur 1 Register SPBRG
	movlw	.12
	movwf	SPBRG			; RS 232 Speed auf 19200 Baud stellen
	goto	add_set
baud_10_set
	bsf		TXSTA,	BRGH	; High-Speed RS 232 an und teiler auf 16
	bcf 	BAUDCON, BRG16	; nur 1 Register SPBRG
	movlw	.16
	movwf	SPBRG			; RS 232 Speed auf 57600 Baud stellen
	goto	add_set
baud_11_set
	bsf		TXSTA,	BRGH	; High-Speed RS 232 an und teiler auf 16
	bcf 	BAUDCON, BRG16	; nur 1 Register SPBRG
	movlw	.8
	movwf	SPBRG			; RS 232 Speed auf 115200 Baud stellen
	goto	add_set

add_set
	btfsc	add0_bit
	goto	add_x1
	btfsc	add1_bit
	goto	add_10_set
	goto	add_00_set
add_x1
	btfsc	add1_bit
	goto	add_11_set
	goto	add_01_set
add_00_set
	banksel address
	movlw 	'0'
	movwf	address
	goto	add_end
add_01_set
	banksel	address
	movlw 	'1'
	movwf	address
	goto	add_end
add_10_set
	banksel	address
	movlw	'2'
	movwf	address
	goto	add_end
add_11_set
	banksel	address
	movlw	'3'
	movwf	address
	goto	add_end
add_end
	return	
;__________________________________________________________________________________


;**********************************************************************************
; Initialisierung des PIC
;**********************************************************************************
init_system
	banksel	lcd_tris
	clrf 	lcd_tris			; lcd_port wird zum Ausgang
	clrf	lcd_port			; 
	clrf	ad_port				; Data-latch löschen

	bsf		baud0_tris
	bsf		baud1_tris
	bsf		add0_tris
	bsf		add1_tris			; Eingänge zum prüfen der Adresse sowie Baudrate
	clrf	counter				; Bytezähler löschen

	banksel	mode
	bsf		mode_0				; Standard Mode
	
	banksel	lcd_rs_on
	movlw	0x00
	movwf	lcd_rs_on			; rs aus Steuerwort stellen
	bcf		lcd_rw				; Write Modus
	bcf		lcd_rs				; Steuerwort

	bcf		INTCON2, RBPU		; Pull UPs an PORTB aktivieren
	movlw	0xff
	movwf	int_tris			; alle Interrrupts sind Eingänge

	banksel	lcd_tris
	bcf		t3_tris		; Luefter zum Ausgang Schalten
	bcf		t3_luefter	; T3 Luefter an
	
	bcf		t2_tris		; T2 Relais als Ausgang
	bcf		t2_relais	; T2 Relais schalten

	bcf		t1_tris		; T1 Ausgang
	bcf		t1_relais	; T1 Relais schalten

	bcf		TXD			; Transmit-Pin wird zum Ausgang
	bsf		RXD			; Receive-Pin wird zum Eingang
	
	bsf		TXSTA,	TXEN	; Transmit erlaubt
	bcf		RCON,	IPEN	; no priority interrupts
	bcf		ABDOVF, ABDEN	; no auto Baud sonst muss man 0x55 schicken
	bsf		RCSTA,	SPEN	; serial port enabled
	bcf		TXSTA,  SYNC	; asynchron mod	
	bsf		PIE1,	RCIE	; enables asynchron interrupt
	bsf		RCSTA,	CREN	; enables receiver
	bsf		INTCON, PEIE	; erlaubt Externe Interrupts
	bsf		INTCON, INT0IE	; INT0 zulassen
	bsf		INTCON3, INT1IE	; INT1 zulassen
	bsf		INTCON3, INT2IE	; INT2 zulassen
	bsf		INTCON, RBIE	; enables PORTB interrupts

	movlw	0xff
	movwf	ad_tris			; PORTA als EINGANG
	bsf 	ADCON0, ADON	; AD-Converter enabled
	movlw	0xb5
	movwf	ADCON2			; conv clock=Fosc/32 TAD=16 right j
	movlw 	0x0a
	movwf	ADCON1			; AN0-AN4 = Analog

	bsf		INTCON, GIE		; erlaubt generell Interrupts

	banksel	bcd_U_1			; löschen aller Speicherregister
	movlw	0x30
	movwf	bcd_U_1
	movlw	0x30
	movwf	bcd_U_2
	movlw	0x30
	movwf	bcd_U_3
	movlw	0x30
	movwf	bcd_U_4
	movlw	0x30
	movwf	bcd_I_1
	movlw	0x30
	movwf	bcd_I_2
	movlw	0x30
	movwf	bcd_I_3
	movlw	0x30	
	movwf	bcd_I_4
	movlw	0x30
	movwf	bcd_R_1
	movlw	0x30
	movwf	bcd_R_2
	movlw	0x30
	movwf	bcd_R_3
	movlw	0x30
	movwf	bcd_R_4
	movlw	0x30
	movwf	bcd_R_5	
	clrf	bcd_T_1
	clrf	bcd_T_2
	banksel U_ist_1
	clrf	U_ist_1
	clrf	U_ist_2
	clrf	U_ist_3
	clrf	U_ist_4
	banksel I_ist_1
	clrf	I_ist_1
	clrf	I_ist_2
	clrf	I_ist_3
	clrf	I_ist_4
	
	return
;__________________________________________________________________________________


;***************************************************************************
; Initialisierung des Displays
;***************************************************************************
lcd_init
	movlw	0xff
	call	pause
	movlw	0xff
	call	pause
	movlw	0xff
	call	pause			; Wait for more than 15ms
	movlw	0x38
	call	ausgabe			; Init-Byte ausgeben
	movlw	0xff
	call 	pause		
	movlw	0xff
	call 	pause			; Wait for more than ...ms
	movlw	0x38
	call 	ausgabe			; Init-Byte ausgeben
	movlw	0xff
	call	pause			; Wait for more than ...ms
	movlw	0x38
	call 	ausgabe			; Init-Byte ausgeben
	movlw	0x0f
	call 	pause			; Wait for more than ...ms

	movlw	0x28 			; Funktion set
	call 	lcd_ausgabe
	movlw	0x0f			; Display on Control
	call	lcd_ausgabe	
	movlw	0x06			; Entry Mode set
	call 	lcd_ausgabe
	movlw	0x01			; clear Display
	call	lcd_ausgabe
	movlw	0x02			; Cursor at home
	call	lcd_ausgabe

	call	lcd_datenwort	; lcd auf Datenwort umschalten
	
	movlw	0x2f
	call 	pause	 		; Pause bevor das Display anfaengt

	movlw	'P'				; P
	call	lcd_ausgabe	
	movlw	'r'				; r
	call	lcd_ausgabe
	movlw	'o'				; o
	call	lcd_ausgabe
	movlw	'g'				; g
	call	lcd_ausgabe
	movlw	'.'				; .
	call	lcd_ausgabe
	movlw	' '				;
	call	lcd_ausgabe
	movlw	'L'				; L
	call	lcd_ausgabe
	movlw	'a'				; a
	call	lcd_ausgabe
	movlw	's'				; s
	call	lcd_ausgabe
	movlw	't'				; t
	call	lcd_ausgabe

	call lcd_steuerwort		; lcd auf Steuerwort stellen
	call lcd_home_l2		; lcd auf Zeile 2 pos. 1
	call lcd_datenwort		; lcd auf Datenwort stellen
lcd_0
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'.'				; .
	call	lcd_ausgabe
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'V'				; V
	call	lcd_ausgabe
	movlw	' '				; 
	call	lcd_ausgabe
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'.'				; .
	call	lcd_ausgabe
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'0'				; 0
	call	lcd_ausgabe
	movlw	'A'				; A
	call	lcd_ausgabe

	return					; Ende lcd_init

ausgabe						; spezielle Ausgabe zum Inisialisieren
	banksel lcd_port
	movwf 	lcd_port
	bsf 	lcd_enable
	nop
	bcf 	lcd_enable
	nop
	return

lcd_datenwort					; lcd nimmt jetzt Datenwoerter an
	banksel	lcd_rs_on	
	movlw	0xff
	movwf	lcd_rs_on
	return

lcd_steuerwort					; lcd nimmt jetzt Steuerwoerter an
	banksel	lcd_rs_on	
	movlw	0x00
	movwf	lcd_rs_on
	banksel	lcd_port
	bcf		lcd_rs
	return

lcd_home_l2						; Zeile 2 pos.1
	call	lcd_steuerwort
	movlw	0xc0
	call	lcd_ausgabe
	call	lcd_datenwort	
	return

lcd_clear_l2					; löscht die 2. Zeile vom Display
	call	lcd_home_l2
	banksel	mini_loop
	movlw	0x10
	movwf	mini_loop
clear_go
	movlw	' '
	call	lcd_ausgabe
	banksel	mini_loop
	decfsz	mini_loop
	goto	clear_go
	call	lcd_home_l2
	return 
	
;__________________________________________________________________________________


;***************************************************************************
; Pause enthaelt eine 100us Zeitschleife die man 1-255 mal durchlaufen kann
; lange_pause enthält eine ca 1s Warteschleife
;***************************************************************************
lange_pause
	movlw	.30
	banksel	loop3
	movwf	loop3
lange_pause_go
	movlw	.200
	call	pause
	movlw	.200
	call	pause
	movlw	.200
	call	pause
	movlw	.200
	call	pause
	movlw	.200
	call	pause
	banksel loop3
	decfsz	loop3, f
	goto	lange_pause_go
	return

pause
	banksel loop2
	movwf 	loop2		; wie oft X*100us
loop_1					; 100us pause
	movlw	1fh
	movwf	loop1
loop_0
	decfsz 	loop1,f
	goto	loop_0
	nop
	nop
	decfsz	loop2,f		; Multiplikator fuer loop_1 (100us)
	goto	loop_1
	banksel	lcd_port
	return
;__________________________________________________________________________________

		
;*********************************************************************************
; lcd-ausgabe in 2 Schritten damit man die 8 Bit Daten im 4 Bit Modus übertraegt
;*********************************************************************************
lcd_ausgabe
	banksel	lcd_data
	movwf	lcd_data
	call	lcd_busy		; busy-flag auslesen und solange warten bis wieder bereit ist

	banksel	lcd_data
	btfsc	lcd_rs_on, 1
	call	set_lcd_rs

	call	lcd_loesche_data
	banksel	lcd_data
	movf	lcd_data, w
	andlw	H'F0'
	movwf   lcd_data2
	rrcf	lcd_data2,0		; um 3 Stellen nach Rechts, damit D4-D7 angesprochen werden
	banksel	lcd_port
	iorwf	lcd_port,1		; Hi-Nibble Daten schreiben
	bsf	    lcd_enable
	nop
	bcf		lcd_enable
	nop
	call	lcd_loesche_data
	
	banksel	lcd_data	
	swapf	lcd_data, w
	andlw	H'F0'
	movwf   lcd_data2
	rrcf	lcd_data2,0		; um 3 Stellen nach Rechts, damit D4-D7 angesprochen werden
	banksel	lcd_port
	iorwf	lcd_port,1		; Lo-Nibble Daten schreiben
	bsf		lcd_enable
	nop
	bcf		lcd_enable
	nop
	call	lcd_loesche_data
	movlw	0x05
	call	pause			; Pause-Zeit damit Zeichen geschrieben werden
	return

lcd_loesche_data			; D4-D7 auf 0 setzen
	banksel	lcd_port
	bcf		lcd_port,3
	bcf		lcd_port,4
	bcf		lcd_port,5
	bcf		lcd_port,6
	return

set_lcd_rs
	banksel	lcd_port
	bsf		lcd_rs			; rs auf Datenwort
	return
;__________________________________________________________________________________


;***************************************************************************
; Ausgabe der Daten an die RS232 Schnittstelle
;***************************************************************************	
rs232_ausgabe
	banksel TXREG
	movwf	TXREG			; Byte Antwort
	banksel address
kurz_warten
	btfss	TXSTA, TRMT
	goto	kurz_warten
	return
;__________________________________________________________________________________


;**********************************************************************************
; lcd-Busy-Flag auslesen und warten bis das LCD wieder bereit ist
;**********************************************************************************
lcd_busy
    banksel lcd_tris		; lcd Port zum Eingang machen
	bsf		lcd_tris, 6		; D7 zum Eingang machen
    
busy_loop
	banksel	lcd_port
	bcf		lcd_rs		
	bsf		lcd_rw			; auf lesen umschalten
	bsf		lcd_enable
	nop
	movf	lcd_port, w		; port einlesen
	nop
	banksel	lcd_status
	movwf	lcd_status		; im lcd statusregister ablegen
	banksel	lcd_port
	bcf		lcd_enable
	
	banksel lcd_status
	btfsc	lcd_status, 6	; busy-flag auswerten
	goto	busy_loop		; solange wiederholen, bis lcd bereit ist

	banksel lcd_port
	bcf		lcd_rw			; auf Schreibmodus umstellen
	bcf		lcd_tris, 6		; D7 zum Ausgang wieder machen    
    return
;__________________________________________________________________________________	


;**********************************************************************************
; Mode auswahl der Frontplatte
;**********************************************************************************
mode_auswahl
	banksel	mode
	btfsc	mode_0
	goto	mode_0_routine
	btfsc	mode_U
	goto	mode_U_routine
	btfsc	mode_I
	goto	mode_I_routine
	btfsc	mode_P
	goto	mode_P_routine
	btfsc	mode_T
	goto	mode_T_routine
	btfsc	mode_R
	goto	mode_R_routine
	return

mode_0_routine
	call 	clr_home_l2
	call 	lcd_0
	return

mode_U_routine					; U max und U Ist am Display ausgeben
	call 	clr_home_l2
	movlw	'U'
	call	lcd_ausgabe
	movlw	'M'
	call	lcd_ausgabe
	banksel	bcd_U_4
	movf	bcd_U_4, w 
	call	lcd_ausgabe
	banksel	bcd_U_3
	movf	bcd_U_3, w
	call	lcd_ausgabe
	movlw	'.'
	call	lcd_ausgabe
	banksel	bcd_U_2
	movf	bcd_U_2, w
	call	lcd_ausgabe
	banksel	bcd_U_1
	movf	bcd_U_1, w
	call	lcd_ausgabe
	movlw	'V'
	call	lcd_ausgabe
	movlw	' '
	call	lcd_ausgabe
	movlw	'I'
	call	lcd_ausgabe
	banksel	U_ist_4
	movf	U_ist_4, w
	iorlw	0x30
	call	lcd_ausgabe
	banksel	U_ist_3
	movf	U_ist_3, w
	iorlw	0x30
	call	lcd_ausgabe
	movlw	'.'
	call	lcd_ausgabe
	banksel	U_ist_2
	movf	U_ist_2, w
	iorlw	0x30
	call	lcd_ausgabe
	banksel	U_ist_1
	movf	U_ist_1, w
	iorlw	0x30
	call	lcd_ausgabe
	movlw	'V'
	call	lcd_ausgabe
	return

mode_I_routine					; I max und I Ist am Display ausgeben
	call 	clr_home_l2
	movlw	'I'
	call	lcd_ausgabe
	movlw	'M'
	call	lcd_ausgabe
	banksel	bcd_I_4
	movf	bcd_I_4, w 
	call	lcd_ausgabe
	banksel	bcd_I_3
	movf	bcd_I_3, w
	call	lcd_ausgabe
	movlw	'.'
	call	lcd_ausgabe
	banksel	bcd_I_2
	movf	bcd_I_2, w
	call	lcd_ausgabe
	banksel	bcd_I_1
	movf	bcd_I_1, w
	call	lcd_ausgabe
	movlw	'A'
	call	lcd_ausgabe
	movlw	' '
	call	lcd_ausgabe
	movlw	'I'
	call	lcd_ausgabe
	banksel	I_ist_4
	movf	I_ist_4, w
	iorlw	0x30
	call	lcd_ausgabe
	banksel	I_ist_3
	movf	I_ist_3, w
	iorlw	0x30
	call	lcd_ausgabe
	movlw	'.'
	call	lcd_ausgabe
	banksel	I_ist_2
	movf	I_ist_2, w
	iorlw	0x30
	call	lcd_ausgabe
	banksel	I_ist_1
	movf	I_ist_1, w
	iorlw	0x30
	call	lcd_ausgabe
	movlw	'A'
	call	lcd_ausgabe
	return

mode_P_routine				; Ausgabe der Leistung am Display
	call 	clr_home_l2
	movlw	'L'
	call 	lcd_ausgabe
	movlw	'e'
	call 	lcd_ausgabe
	movlw	'i'
	call 	lcd_ausgabe
	movlw	's'
	call 	lcd_ausgabe
	movlw	't'
	call 	lcd_ausgabe
	movlw	'u'
	call 	lcd_ausgabe
	movlw	'n'
	call 	lcd_ausgabe
	movlw	'g'
	call 	lcd_ausgabe
	movlw	' '
	call	lcd_ausgabe
	movlw 	'0'
	call	lcd_ausgabe
	movlw	'.'
	call	lcd_ausgabe
	movlw	'0'
	call	lcd_ausgabe
	movlw	'W'
	call	lcd_ausgabe
	return
	
mode_T_routine
	call 	clr_home_l2
	movlw	'T'
	call	lcd_ausgabe
	movlw	'e'
	call	lcd_ausgabe
	movlw	'm'
	call	lcd_ausgabe
	movlw	'p'
	call	lcd_ausgabe
	movlw	' '
	call	lcd_ausgabe
	banksel bcd_T_2
	movf	bcd_T_2, w
	iorlw	0x30
	call	lcd_ausgabe
	banksel bcd_T_1
	movf	bcd_T_1, w
	iorlw	0x30
	call	lcd_ausgabe
	movlw	'C'
	call	lcd_ausgabe
	return

mode_R_routine
	call	clr_home_l2
	movlw	'R'
	call	lcd_ausgabe
	movlw	' '
	call	lcd_ausgabe
	banksel bcd_R_5
	movf	bcd_R_5, w
	call	lcd_ausgabe
	banksel bcd_R_4
	movf	bcd_R_4, w
	call	lcd_ausgabe
	banksel bcd_R_3
	movf	bcd_R_3, w
	call	lcd_ausgabe
	banksel bcd_R_2
	movf	bcd_R_2, w
	call	lcd_ausgabe
	banksel bcd_R_1
	movf	bcd_R_1, w
	call	lcd_ausgabe
	movlw	' '
	call	lcd_ausgabe
	movlw	'O'
	call	lcd_ausgabe
	movlw	'h'
	call	lcd_ausgabe
	movlw	'm'
	call	lcd_ausgabe
	return

clr_home_l2					; löscht Zeile2 und springt zum Anfang Zeile2
	call lcd_steuerwort		; lcd auf Steuerwort stellen
	call lcd_home_l2		; lcd auf Zeile 2 pos. 1
	call lcd_datenwort		; lcd auf Datenwort stellen
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	movlw	' '
	call lcd_ausgabe
	call lcd_steuerwort		; lcd auf Steuerwort stellen
	call lcd_home_l2		; lcd auf Zeile 2 pos. 1
	call lcd_datenwort		; lcd auf Datenwort stellen
	return
;__________________________________________________________________________________	


	end						; das Ende des Programms 
;__________________________________________________________________________________


