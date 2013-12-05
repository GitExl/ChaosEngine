
	incdir	"Includes:"
	include	"misc/DeliPlayer6.i"

;
;
	SECTION Player,Code
;
;

	PLAYERHEADER PlayerTagArray

	dc.b '$VER: VectorDean player module V1.0 (12 Aug 94)',0
	even

PlayerTagArray
	dc.l	DTP_RequestDTVersion,17
	dc.l	DTP_PlayerVersion,01<<16+00
	dc.l	DTP_PlayerName,PName
	dc.l	DTP_Creator,CName
;	dc.l	DTP_DeliBase,delibase
	dc.l	DTP_Check2,Chk
	dc.l	DTP_CheckLen,ChkLen
	dc.l	DTP_ExtLoad,Load
	dc.l	DTP_SubSongRange,SubSong
	dc.l	DTP_SubSongTest,SubSongTst
;	dc.l	DTP_Flags,PLYF_SONGEND
	dc.l	DTP_Interrupt,lbC023DBC
	dc.l	DTP_InitPlayer,InitPlay
	dc.l	DTP_EndPlayer,EndPlay
	dc.l	DTP_InitSound,InitSnd
	dc.l	DTP_EndSound,RemSnd
	dc.l	DTP_Volume,SetVolBal
	dc.l	DTP_Balance,SetVolBal
	dc.l	TAG_DONE

*-----------------------------------------------------------------------*
;
; Player/Creatorname und lokale Daten

PName	dc.b 'VectorDean',0
CName	dc.b 'coded by Andi Smithers, VectorDean,',10
	dc.b '(C) Millennium 1992.',10
	dc.b 'adapted by Delirium',0
	even

SamplesTxt	dc.b '.ins',0
	even

; delibase	dc.l 0

SongData	dc.l 0
InstData	dc.l 0
MaxSong		dc.w 0				; max. subsongnumber
	even

*-----------------------------------------------------------------------*
;
; Testet, ob es sich um ein VectorDean-Modul handelt

Chk
	move.l	dtg_ChkData(a5),a0		; ^module
	move.l	(a0)+,d0
	subi.l	#"RJP1",d0
	bne.s	ChkErr
	move.l	(a0)+,d0
	subi.l	#"SMOD",d0
ChkErr
	rts

ChkLen = *-Chk

*-----------------------------------------------------------------------*
;
; Sample laden

Load
	move.l	dtg_PathArrayPtr(a5),a0
	clr.b	(a0)				; clear Path

	move.l	dtg_CopyDir(a5),a0		; copy dir into patharray
	jsr	(a0)

	move.l	dtg_CopyFile(a5),a0		; append filename
	jsr	(a0)

	move.l	dtg_CutSuffix(a5),a0		; remove '.pp' suffix if necessary
	jsr	(a0)

	move.l	dtg_PathArrayPtr(a5),a0		; search end of string
	moveq	#1,d0
Search	addq.l	#1,d0
	tst.b	(a0)+
	bne.s	Search

Suffix	subq.l	#1,d0				; search suffix
	beq.s	NoSuffix
	cmpi.b	#".",-(a0)
	bne.s	Suffix
	clr.b	(a0)				; remove suffix
NoSuffix
	lea	SamplesTxt(pc),a0		; join '.ins'
	move.l	dtg_CopyString(a5),a1
	jsr	(a1)

	move.l	dtg_LoadFile(a5),a0
	jsr	(a0)				; returncode is already set !
LoadEnd
	rts

*-----------------------------------------------------------------------*
;
; Set min. & max. subsong number

SubSong
	moveq	#0,d0				; min.
	move.w	MaxSong(pc),d1			; max.
	rts

*-----------------------------------------------------------------------*
;
; Test given subsong number

SubSongTst
	move.l	SongData(pc),a0			; skip bad subsongs
	addq.l	#8,a0
	add.l	(a0)+,a0
	add.l	(a0)+,a0
	move.w	dtg_SndNum(a5),d0
	lsl.w	#2,d0
	tst.l	4(a0,d0.w)
	beq.s	SubSngErr
	moveq	#0,d0				; no error
	bra.s	SubSngEnd
SubSngErr
	moveq	#-1,d0				; set error
SubSngEnd
	rts

*-----------------------------------------------------------------------*
;
; Init Player

InitPlay
	moveq	#0,d0
	move.l	dtg_GetListData(a5),a0		; Function
	jsr	(a0)
	move.l	a0,SongData

	moveq	#1,d0
	move.l	dtg_GetListData(a5),a0		; Function
	jsr	(a0)
	move.l	a0,InstData

	move.l	SongData(pc),a0
	addq.l	#8,a0
	add.l	(a0)+,a0
	add.l	(a0)+,a0
	move.l	(a0)+,d0
	lsr.l	#2,d0
	subq.l	#1,d0
	move.w	d0,MaxSong			; store max. Subsong

	move.l	SongData(pc),a0
	move.l	InstData(pc),a1
	jsr	lbC023DC0

	move.l	dtg_AudioAlloc(a5),a0		; Function
	jsr	(a0)				; returncode is already set !
	rts

*-----------------------------------------------------------------------*
;
; End Player

EndPlay
	move.l	dtg_AudioFree(a5),a0		; Function
	jsr	(a0)
	rts

*-----------------------------------------------------------------------*
;
; Init Sound

InitSnd
	moveq	#$D,d0
	bsr	lbC023DD8
	move.w	dtg_SndNum(a5),d0
	bsr	lbC023DC8			; Init Sound
	rts

*-----------------------------------------------------------------------*
;
; Remove Sound

RemSnd
	bsr	lbC023DD4			; End Sound
	rts

*-----------------------------------------------------------------------*
;
; Set Volume

SetVolBal
	move.w	dtg_SndVol(a5),d1		; left Volume
	mulu.w	dtg_SndLBal(a5),d1
	lsr.w	#6,d1
	moveq	#0,d0
	bsr	lbC023DD0
	moveq	#3,d0
	bsr	lbC023DD0
	move.w	dtg_SndVol(a5),d1		; right Volume
	mulu.w	dtg_SndRBal(a5),d1
	lsr.w	#6,d1
	moveq	#1,d0
	bsr	lbC023DD0
	moveq	#2,d0
	bsr	lbC023DD0
	rts

*-----------------------------------------------------------------------*
;
; VectorDean Replay (Cannon Fodder)

lbC023DBC
	bra	DoInterrupt		; Interrupt

lbC023DC0
	bra	InitModule		; Init Module

lbC023DC4
	bra	lbC024076		; ???

lbC023DC8
	bra	SetSubSong		; Set Subsong

lbC023DCC
	bra	lbC02400A		; ???

lbC023DD0
	bra	SetVolume		; Set Volume

lbC023DD4
	bra	ShutDown		; Shutdown

lbC023DD8
	bra	lbC023F96		; ???

	dc.b	'CODED BY ANDI SMITHERS, VECTORDEAN (C) MILLENNIUM 1992',0,0

InitModule
	movem.l	d0-d7/a0-a6,-(sp)
	lea	StateData(pc),a5
	addq.l	#$04,a1
	move.l	a1,(a5)
	addq.l	#$08,a0
	lea	$0004(a5),a1
	moveq	#$06,d0
lbC023E30
	move.l	(a0)+,d7
	move.l	a0,(a1)+
	add.l	d7,a0
	dbra	d0,lbC023E30
	move.w	#$0040,$0020(a5)
	move.b	#$40,$0028(a5)
	move.b	#$40,$0029(a5)
	move.b	#$40,$002A(a5)
	move.b	#$40,$002B(a5)
	move.w	#$000D,$0022(a5)
	clr.b	$0024(a5)
	clr.b	$0025(a5)
	st	$0026(a5)
	st	$0027(a5)
	move.l	$0004(a5),a2
	move.l	(a5),a3
	move.l	-$0004(a2),d1
lbC023E80
	move.l	(a2),d0
	add.l	a3,d0
	move.l	d0,(a2)
	move.l	$0004(a2),d0
	beq.s	lbC023E8E
	add.l	a3,d0
lbC023E8E
	move.l	d0,$0004(a2)
	move.l	$0008(a2),d0
	beq.s	lbC023E9A
	add.l	a3,d0
lbC023E9A
	move.l	d0,$0008(a2)
	move.w	$0010(a2),d0
	add.w	d0,d0
	move.w	d0,$0010(a2)
	lea	$0020(a2),a2
	sub.w	#$0020,d1
	bne.s	lbC023E80
lbC023EB2
	lea	ChannelData1(pc),a0
	bsr.s	lbC023F18
	move.l	#$00DFF0A0,(a0)
	move.w	#$0001,$002E(a0)
	move.w	#$0001,$0086(a0)
	lea	ChannelData2(pc),a0
	bsr.s	lbC023F18
	move.l	#$00DFF0B0,(a0)
	move.w	#$0002,$002E(a0)
	move.w	#$0002,$0086(a0)
	lea	ChannelData3(pc),a0
	bsr.s	lbC023F18
	move.l	#$00DFF0C0,(a0)
	move.w	#$0004,$002E(a0)
	move.w	#$0004,$0086(a0)
	lea	ChannelData4(pc),a0
	bsr.s	lbC023F18
	move.l	#$00DFF0D0,(a0)
	move.w	#$0008,$002E(a0)
	move.w	#$0008,$0086(a0)
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbC023F18
	move.l	a0,a1
	moveq	#$00,d0
	moveq	#$57,d1
lbC023F1E
	move.w	d0,(a1)+
	dbra	d1,lbC023F1E
	rts

ShutDown
	movem.l	d0/a5/a6,-(sp)
	lea	StateData(pc),a5
	lea	$00DFF000,a6
	moveq	#$00,d0
	move.w	d0,$0020(a5)
	move.w	d0,$0022(a5)
	move.w	#$000F,$0096(a6)
	move.w	d0,$00A8(a6)
	move.w	d0,$00B8(a6)
	move.w	d0,$00C8(a6)
	move.w	d0,$00D8(a6)
	movem.l	(sp)+,d0/a5/a6
	rts

void SetVolume(channel, volume) {
	if (volume != 0x40) {
		volume &= 0x3f;
	}

	if (channel != 0) {
		channel &= 0x3;
		StateData[0x28 + channel] = volume;
	} else {
		StateData[0x28] = volume;
		StateData[0x29] = volume;
		StateData[0x2A] = volume;
		StateData[0x2B] = volume;
	}
}

lbC023F96(d0) {
	lea	StateData(pc),a5

	d0 &= 0xf;
	StateData[0x22] = d0;

	sf	$0025(a5)
	st	$0026(a5)
	st	$0027(a5)
	
	if (d0 == 0x3) {
		sf	$0026(a5)
	} else if (d0 == 0x2) {
		sf	$0027(a5)
	}
}

SetSubSong
	movem.l	d0/d1/a0/a5,-(sp)
	and.w	#$003F,d0
	lea	StateData(pc),a5
	move.l	$000C(a5),a0
	d0 += d0;
	d0 += d0;
	add.w	d0,a0
	moveq	#$00,d1
	move.b	(a0)+,d1
	beq.s	lbC023FEC
	moveq	#$00,d0
	bsr.s	lbC02400A
lbC023FEC
	move.b	(a0)+,d1
	beq.s	lbC023FF4
	moveq	#$01,d0
	bsr.s	lbC02400A
lbC023FF4
	move.b	(a0)+,d1
	beq.s	lbC023FFC
	moveq	#$02,d0
	bsr.s	lbC02400A
lbC023FFC
	move.b	(a0)+,d1
	beq.s	lbC024004
	moveq	#$03,d0
	bsr.s	lbC02400A
lbC024004
	movem.l	(sp)+,d0/d1/a0/a5
	rts

lbC02400A
	movem.l	d0/d1/a0-a2/a5,-(sp)
	lea	StateData(pc),a5
	lea	ChannelData1(pc),a0
	bset	d0,$002C(a5)
	mulu	#$00B0,d0
	add.w	d0,a0
	move.l	$0010(a5),a1
	add.w	d1,d1
	add.w	d1,d1
	beq.s	lbC024068
	move.l	$00(a1,d1.w),a1
	add.l	$0018(a5),a1
	moveq	#$00,d1
	move.b	(a1)+,d1
	move.l	a1,$004E(a0)
	add.w	d1,d1
	add.w	d1,d1
	move.l	$0014(a5),a2
	move.l	$00(a2,d1.w),a2
	add.l	$001C(a5),a2
	move.l	a2,$0052(a0)
	move.b	#$06,$0056(a0)
	moveq	#$01,d0
	move.b	d0,$0057(a0)
	move.b	d0,$0059(a0)
	st	$005B(a0)
	movem.l	(sp)+,d0/d1/a0-a2/a5
	rts

lbC024068
	clr.b	$005B(a0)
	bsr	lbC0241C8
	movem.l	(sp)+,d0/d1/a0-a2/a5
	rts

lbC024076
	movem.l	d0/d1/a0/a1/a5,-(sp)
	lea	StateData(pc),a5
	btst	#$02,$0023(a5)
	beq.s	lbC0240BC
	lea	ChannelData1(pc),a0
	addq.w	#$04,d0
	bset	d0,$002C(a5)
	subq.w	#$04,d0
	mulu	#$00B0,d0
	add.w	d0,a0
	add.w	d1,d1
	add.w	d1,d1
	move.l	$0014(a5),a1
	move.l	$00(a1,d1.w),a1
	add.l	$001C(a5),a1
	move.l	a1,$00A6(a0)
	move.b	#$06,$00AA(a0)
	moveq	#$01,d0
	move.b	d0,$00AB(a0)
	move.b	d0,$00AD(a0)
lbC0240BC
	movem.l	(sp)+,d0/d1/a0/a1/a5
	rts

DoInterrupt() {
	a6 = $00DFF000
	
	d0 = StateData[0x22];
	d0 &= 0x3;
	if (d0 != 0)
		StateData[0x25] |= 0x1;
		d0 = 0x1;
	}
	d0 -= 1;
	StateData[0x24] = d0;

	StateData[0x28] = StateData[0x21];
	StateData[0x2d] = 0x0;
	UpdateChannel(ChannelData1);

	StateData[0x29] = StateData[0x21];
	StateData[0x2d] = 0x1;
	UpdateChannel(ChannelData2);

	StateData[0x2a] = StateData[0x21];
	StateData[0x2d] = 0x2;
	UpdateChannel(ChannelData3);

	StateData[0x2b] = StateData[0x21];
	StateData[0x2d] = 0x3;
	UpdateChannel(ChannelData4);

	d0 = StateData[0x2c];
}

UpdateChannel(ChannelData) {
	if (ChannelData[0xa6] == 0)
	tst.l	$00A6(a0)
	beq.s	lbC02416A
	tst.b	$0027(a5)
	beq.s	lbC02416A
	bsr	lbC024518
	bsr	lbC024540
	bsr	lbC0241D4
	bsr	lbC02455A
	bsr	lbC024608
	bsr	lbC024726
	return;

lbC02416A
	tst.b	$0026(a5)
	beq.s	lbC024184
	tst.b	$005B(a0)
	beq.s	lbC024184
	bsr.s	lbC024186
	bsr.s	lbC0241AE
	bsr.s	lbC0241D4
	bsr	lbC0242CE
	bsr	lbC0243E8
lbC024184
	return;

lbC024186
	bclr	#$00,$0039(a0)
	beq.s	lbC0241A6
	move.l	$0004(a0),a1
	moveq	#$00,d0
	move.w	$0016(a0),d0
	add.l	d0,d0
	add.l	d0,a1
	move.l	(a0),a2
	move.l	a1,(a2)
	move.w	$0018(a0),$0004(a2)
lbC0241A6
	moveq	#$00,d7
	move.b	$0024(a5),d7
	return;

lbC0241AE
	bclr	#$00,$0038(a0)
	beq.s	lbC0241C6
	st	$0039(a0)
	move.w	#$8200,d0
	or.w	$002E(a0),d0
	move.w	d0,$0096(a6)
lbC0241C6
	return;

lbC0241C8
	moveq	#$00,d0
	or.w	$002E(a0),d0
	move.w	d0,$0096(a6)
	return;

lbC0241D4
	move.l	$0052(a0),d0
	beq.s	lbC02421E
	tst.b	$0025(a5)
	bne.s	lbC02421E
	subq.b	#$01,$0057(a0)
	bne.s	lbC02421E
	subq.b	#$01,$0059(a0)
	bne.s	lbC024218
	move.l	d0,a1
	bra.s	lbC0241F6
lbC0241F0
	add.b	d0,d0
	jmp	lbC024224(pc,d0.w)
lbC0241F6
	moveq	#$00,d0
	move.b	(a1)+,d0
	bmi.s	lbC0241F0
	lea	NoteData(pc),a2
	move.w	$00(a2,d0.w),d1
	tst.l	$00A6(a0)
	bne.s	lbC02420E
	bsr	lbC024446
lbC02420E
	move.l	a1,$0052(a0)
	move.b	$0058(a0),$0059(a0)
lbC024218
	move.b	$0056(a0),$0057(a0)
lbC02421E
	dbra	d7,lbC0241D4
	rts
lbC024224
	bra.s	lbC024272

	bra.s	lbC024234

	bra.s	lbC02423A

	bra.s	lbC024240

	bra.s	lbC024246

	bra.s	lbC024250

	bra.s	lbC024258

	bra.s	lbC02420E

lbC024234
	bsr	lbC0243C4
	bra.s	lbC02420E

lbC02423A
	move.b	(a1)+,$0056(a0)
	bra.s	lbC0241F6

lbC024240
	move.b	(a1)+,$0058(a0)
	bra.s	lbC0241F6

lbC024246
	move.b	(a1)+,d0
	beq.s	lbC02424E
	bsr	lbC0244A6
lbC02424E
	bra.s	lbC0241F6

lbC024250
	move.b	(a1)+,d0
	move.w	d0,$0030(a0)
	bra.s	lbC0241F6

lbC024258
	move.b	(a1)+,$0040(a0)
	move.b	(a1)+,$0042(a0)
	move.b	(a1)+,$0043(a0)
	move.b	(a1)+,$0044(a0)
	move.b	(a1)+,$0045(a0)
	clr.l	$0046(a0)
	bra.s	lbC0241F6

lbC024272
	move.l	$004E(a0),a2
	move.b	#$01,$0058(a0)
lbC02427C
	moveq	#$00,d0
	move.b	(a2)+,d0
	beq.s	lbC02429A
	move.l	a2,$004E(a0)
	move.l	$0014(a5),a1
	add.w	d0,d0
	add.w	d0,d0
	move.l	$00(a1,d0.w),a1
	add.l	$001C(a5),a1
	bra	lbC0241F6

lbC02429A
	moveq	#$00,d0
	move.b	(a2),d0
	beq.s	lbC0242BC
	bmi.s	lbC0242A6
	sub.w	d0,a2
	bra.s	lbC02427C

lbC0242A6
	move.b	$0001(a2),d0
	move.l	$0010(a5),a2
	add.w	d0,d0
	add.w	d0,d0
	move.l	$00(a2,d0.w),a2
	add.l	$0018(a5),a2
	bra.s	lbC02427C

lbC0242BC
	sub.l	a1,a1
	clr.b	$005B(a0)
	move.b	$002D(a5),d0
	bclr	d0,$002C(a5)
	bra	lbC02420E
}

lbC0242CE
	move.l	(a0),a2
	bsr.s	lbC024332
	bsr.s	lbC024300
	bsr.s	lbC0242D8
	rts

lbC0242D8
	move.w	$0032(a0),d0
	muls	$0030(a0),d0
	asr.w	#$06,d0
	muls	$0020(a5),d0
	asr.w	#$06,d0
	move.w	d0,$0032(a0)
	cmp.w	#$0040,d0
	bls.s	lbC0242FA
	bgt.s	lbC0242F8
	moveq	#$00,d0
	bra.s	lbC0242FA

lbC0242F8
	moveq	#$40,d0
lbC0242FA
	move.w	d0,$0008(a2)
	rts

lbC024300
	move.l	$000C(a0),d0
	beq.s	lbC024330
	move.l	d0,a1
	move.l	$002A(a0),d0
	move.b	$00(a1,d0.l),d1
	ext.w	d1
	muls	$0032(a0),d1
	asr.w	#$07,d1
	add.w	d1,$0032(a0)
	addq.l	#$01,d0
	cmp.l	$0026(a0),d0
	bne.s	lbC02432C
	moveq	#$00,d0
	move.w	$0024(a0),d0
	add.l	d0,d0
lbC02432C
	move.l	d0,$002A(a0)
lbC024330
	rts

lbC024332
	tst.b	$003A(a0)
	beq.s	lbC02437A
	move.w	#$00FF,d2
	move.b	$003B(a0),d0
	ext.w	d0
	beq.s	lbC024358
	move.b	$003C(a0),d1
	beq.s	lbC02438A
	and.w	d2,d1
	muls	d1,d0
	move.b	$003D(a0),d1
	beq.s	lbC02438A
	and.w	d2,d1
	divs	d1,d0
lbC024358
	moveq	#$00,d1
	move.b	$003E(a0),d1
	sub.b	d0,d1
	move.b	d1,$003F(a0)
	subq.b	#$01,$003C(a0)
	cmp.b	$003C(a0),d2
	bne.s	lbC02437A
	moveq	#$00,d0
	move.b	$003A(a0),d0
	bmi.s	lbC024396
	jsr	lbC024384(pc,d0.w)
lbC02437A
	moveq	#$00,d0
	move.b	$003F(a0),d0
	move.w	d0,$0032(a0)
lbC024384
	rts

	bra.s	lbC024396

	bra.s	lbC02439C

lbC02438A
	moveq	#$00,d0
	bra.s	lbC024358

	move.w	#$0040,$0032(a0)
	rts

lbC024396
	clr.b	$003A(a0)
	rts

lbC02439C
	move.l	$0010(a0),a1
	move.b	$0003(a1),d0
	move.b	d0,$003E(a0)
	sub.b	$0001(a1),d0
	move.b	d0,$003B(a0)
	move.b	$0004(a1),d0
	move.b	d0,$003D(a0)
	move.b	d0,$003C(a0)
	move.b	#$02,$003A(a0)
	rts

lbC0243C4
	move.l	$0010(a0),a2
	moveq	#$00,d0
	move.b	d0,$003E(a0)
	sub.b	$003F(a0),d0
	move.b	d0,$003B(a0)
	move.b	$0005(a2),d0
	move.b	d0,$003D(a0)
	move.b	d0,$003C(a0)
	st	$003A(a0)
	rts

lbC0243E8
	move.l	$0008(a0),d0
	beq.s	lbC024422
	move.l	d0,a1
	move.l	$0020(a0),d0
	move.b	$00(a1,d0.l),d1
	ext.w	d1
	muls	$0034(a0),d1
	asr.l	#$07,d1
	neg.w	d1
	bpl.s	lbC024406
	asr.w	#$01,d1
lbC024406
	add.w	$0034(a0),d1
	move.w	d1,$0036(a0)
	addq.l	#$01,d0
	cmp.l	$001C(a0),d0
	bne.s	lbC02441E
	moveq	#$00,d0
	move.w	$001A(a0),d0
	add.l	d0,d0
lbC02441E
	move.l	d0,$0020(a0)
lbC024422
	move.l	(a0),a2
	tst.b	$0040(a0)
	beq.s	lbC024436
	move.l	$0042(a0),d0
	add.l	d0,$0046(a0)
	subq.b	#$01,$0040(a0)
lbC024436
	moveq	#$00,d0
	move.w	$0046(a0),d0
	add.w	$0036(a0),d0
	move.w	d0,$0006(a2)
	rts

lbC024446
	move.l	$004A(a0),a2
	move.w	d1,$0034(a0)
	move.w	d1,$0036(a0)
	clr.l	$0046(a0)
	move.l	$0008(a5),a3
	add.w	$000C(a2),a3
	move.l	a3,$0010(a0)
	move.b	$0001(a3),d0
	move.b	d0,$003E(a0)
	sub.b	(a3),d0
	move.b	d0,$003B(a0)
	move.b	$0002(a3),d0
	move.b	d0,$003D(a0)
	move.b	d0,$003C(a0)
	move.b	#$04,$003A(a0)
	move.w	$002E(a0),$0096(a6)
	move.l	(a0),a3
	move.l	$0004(a0),a4
	moveq	#$00,d0
	move.w	$0010(a2),d0
	add.l	d0,a4
	clr.w	(a4)
	move.l	a4,(a3)
	move.w	$0012(a2),$0004(a3)
	st	$0038(a0)
	rts

lbC0244A6
	cmp.b	$005A(a0),d0
	bne.s	lbC0244AE
	rts

lbC0244AE
	move.b	d0,$005A(a0)
	move.l	a2,-(sp)
	move.l	$0004(a5),a2
	asl.w	#$05,d0
	add.w	d0,a2
	move.l	a2,$004A(a0)
	move.w	$0012(a2),$0014(a0)
	move.w	$0014(a2),$0016(a0)
	move.w	$0016(a2),$0018(a0)
	move.w	$000E(a2),$0030(a0)
	move.w	$0018(a2),$001A(a0)
	moveq	#$00,d0
	move.l	d0,$0020(a0)
	move.w	$001A(a2),d0
	add.l	d0,d0
	move.l	d0,$001C(a0)
	move.w	$001C(a2),$0024(a0)
	moveq	#$00,d0
	move.l	d0,$002A(a0)
	move.w	$001E(a2),d0
	add.l	d0,d0
	move.l	d0,$0026(a0)
	move.l	(a2),$0004(a0)
	move.l	$0004(a2),$0008(a0)
	move.l	$0008(a2),$000C(a0)
	move.l	(sp)+,a2
	rts

lbC024518
	bclr	#$00,$0091(a0)
	beq.s	lbC024538
	move.l	$005C(a0),a1
	moveq	#$00,d0
	move.w	$006E(a0),d0
	add.l	d0,d0
	add.l	d0,a1
	move.l	(a0),a2
	move.l	a1,(a2)
	move.w	$0070(a0),$0004(a2)
lbC024538
	moveq	#$00,d7
	move.b	$0024(a5),d7
	rts

lbC024540
	bclr	#$00,$0090(a0)
	beq.s	lbC024558
	st	$0091(a0)
	move.w	#$8200,d0
	or.w	$0086(a0),d0
	move.w	d0,$0096(a6)
lbC024558
	rts

lbC02455A
	btst	#$02,$0023(a5)
	beq.s	lbC0245AA
	move.l	$00A6(a0),d0
	beq.s	lbC0245AA
	tst.b	$0025(a5)
	bne.s	lbC0245AA
	subq.b	#$01,$00AB(a0)
	bne.s	lbC0245AA
	subq.b	#$01,$00AD(a0)
	bne.s	lbC0245A4
	move.l	d0,a1
	bra.s	lbC024584

lbC02457E
	add.b	d0,d0
	jmp	lbC0245AC(pc,d0.w)

lbC024584
	moveq	#$00,d0
	move.b	(a1)+,d0
	bmi.s	lbC02457E
	lea	NoteData(pc),a2
	move.w	$00(a2,d0.w),d1
	move.b	$00AE(a0),d0
	bsr	lbC024784
lbC02459A
	move.l	a1,$00A6(a0)
	move.b	$00AC(a0),$00AD(a0)
lbC0245A4
	move.b	$00AA(a0),$00AB(a0)
lbC0245AA
	rts

lbC0245AC
	bra.s	lbC0245FA

	bra.s	lbC0245BC

	bra.s	lbC0245C2

	bra.s	lbC0245C8

	bra.s	lbC0245CE

	bra.s	lbC0245D8

	bra.s	lbC0245E0

	bra.s	lbC02459A

lbC0245BC
	bsr	lbC024702
	bra.s	lbC02459A

lbC0245C2
	move.b	(a1)+,$00AA(a0)
	bra.s	lbC024584

lbC0245C8
	move.b	(a1)+,$00AC(a0)
	bra.s	lbC024584

lbC0245CE
	move.b	(a1)+,d0
	beq.s	lbC0245D6
	bsr	lbC0247E4
lbC0245D6
	bra.s	lbC024584

lbC0245D8
	move.b	(a1)+,d0
	move.w	d0,$0088(a0)
	bra.s	lbC024584

lbC0245E0
	move.b	(a1)+,$0098(a0)
	move.b	(a1)+,$009A(a0)
	move.b	(a1)+,$009B(a0)
	move.b	(a1)+,$009C(a0)
	move.b	(a1)+,$009D(a0)
	clr.l	$009E(a0)
	bra.s	lbC024584

lbC0245FA
	sub.l	a1,a1
	move.b	$002D(a5),d0
	addq.b	#$04,d0
	bclr	d0,$002C(a5)
	bra.s	lbC02459A

lbC024608
	move.l	(a0),a2
	bsr	lbC024670
	bsr	lbC02463E
	bsr.s	lbC024616
	rts

lbC024616
	move.w	$008A(a0),d0
	muls	$0088(a0),d0
	asr.w	#$06,d0
	muls	$0020(a5),d0
	asr.w	#$06,d0
	move.w	d0,$008A(a0)
	cmp.w	#$0040,d0
	bls.s	lbC024638
	bgt.s	lbC024636
	moveq	#$00,d0
	bra.s	lbC024638

lbC024636
	moveq	#$40,d0
lbC024638
	move.w	d0,$0008(a2)
	rts

lbC02463E
	move.l	$0064(a0),d0
	beq.s	lbC02466E
	move.l	d0,a1
	move.l	$0082(a0),d0
	move.b	$00(a1,d0.l),d1
	ext.w	d1
	muls	$008A(a0),d1
	asr.w	#$07,d1
	add.w	d1,$008A(a0)
	addq.l	#$01,d0
	cmp.l	$007E(a0),d0
	bne.s	lbC02466A
	moveq	#$00,d0
	move.w	$007C(a0),d0
	add.l	d0,d0
lbC02466A
	move.l	d0,$0082(a0)
lbC02466E
	rts

lbC024670
	tst.b	$0092(a0)
	beq.s	lbC0246B8
	move.w	#$00FF,d2
	move.b	$0093(a0),d0
	beq.s	lbC024696
	ext.w	d0
	move.b	$0094(a0),d1
	beq.s	lbC0246C8
	and.w	d2,d1
	muls	d1,d0
	move.b	$0095(a0),d1
	beq.s	lbC0246C8
	and.w	d2,d1
	divs	d1,d0
lbC024696
	moveq	#$00,d1
	move.b	$0096(a0),d1
	sub.b	d0,d1
	move.b	d1,$0097(a0)
	subq.b	#$01,$0094(a0)
	cmp.b	$0094(a0),d2
	bne.s	lbC0246B8
	moveq	#$00,d0
	move.b	$0092(a0),d0
	bmi.s	lbC0246D4
	jsr	lbC0246C2(pc,d0.w)
lbC0246B8
	moveq	#$00,d0
	move.b	$0097(a0),d0
	move.w	d0,$008A(a0)
lbC0246C2
	rts

	bra.s	lbC0246D4

	bra.s	lbC0246DA

lbC0246C8
	moveq	#$00,d0
	bra.s	lbC024696

	move.w	#$0040,$008A(a0)
	rts

lbC0246D4
	clr.b	$0092(a0)
	rts

lbC0246DA
	move.l	$0068(a0),a1
	move.b	$0003(a1),d0
	move.b	d0,$0096(a0)
	sub.b	$0001(a1),d0
	move.b	d0,$0093(a0)
	move.b	$0004(a1),d0
	move.b	d0,$0095(a0)
	move.b	d0,$0094(a0)
	move.b	#$02,$0092(a0)
	rts

lbC024702
	move.l	$0068(a0),a2
	moveq	#$00,d0
	move.b	d0,$0096(a0)
	sub.b	$0097(a0),d0
	move.b	d0,$0093(a0)
	move.b	$0005(a2),d0
	move.b	d0,$0095(a0)
	move.b	d0,$0094(a0)
	st	$0092(a0)
	rts

lbC024726
	move.l	$0060(a0),d0
	beq.s	lbC024760
	move.l	d0,a1
	move.l	$0078(a0),d0
	move.b	$00(a1,d0.l),d1
	ext.w	d1
	muls	$008C(a0),d1
	asr.l	#$07,d1
	neg.w	d1
	bpl.s	lbC024744
	asr.w	#$01,d1
lbC024744
	add.w	$008C(a0),d1
	move.w	d1,$008E(a0)
	addq.l	#$01,d0
	cmp.l	$0074(a0),d0
	bne.s	lbC02475C
	moveq	#$00,d0
	move.w	$0072(a0),d0
	add.l	d0,d0
lbC02475C
	move.l	d0,$0078(a0)
lbC024760
	move.l	(a0),a2
	tst.b	$0098(a0)
	beq.s	lbC024774
	move.l	$009A(a0),d0
	add.l	d0,$009E(a0)
	subq.b	#$01,$0098(a0)
lbC024774
	moveq	#$00,d0
	move.w	$009E(a0),d0
	add.w	$008E(a0),d0
	move.w	d0,$0006(a2)
	rts

lbC024784
	move.l	$00A2(a0),a2
	move.w	d1,$008C(a0)
	move.w	d1,$008E(a0)
	clr.l	$009E(a0)
	move.l	$0008(a5),a3
	add.w	$000C(a2),a3
	move.l	a3,$0068(a0)
	move.b	$0001(a3),d0
	move.b	d0,$0096(a0)
	sub.b	(a3),d0
	move.b	d0,$0093(a0)
	move.b	$0002(a3),d0
	move.b	d0,$0095(a0)
	move.b	d0,$0094(a0)
	move.b	#$04,$0092(a0)
	move.w	$0086(a0),$0096(a6)
	move.l	(a0),a3
	move.l	$005C(a0),a4
	moveq	#$00,d0
	move.w	$0010(a2),d0
	add.l	d0,a4
	clr.w	(a4)
	move.l	a4,(a3)
	move.w	$0012(a2),$0004(a3)
	st	$0090(a0)
	rts

lbC0247E4
	cmp.b	$00AE(a0),d0
	bne.s	lbC0247EC
	rts

lbC0247EC
	move.b	d0,$00AE(a0)
	move.l	a2,-(sp)
	move.l	$0004(a5),a2
	asl.w	#$05,d0
	add.w	d0,a2
	move.l	a2,$00A2(a0)
	move.w	$0012(a2),$006C(a0)
	move.w	$0014(a2),$006E(a0)
	move.w	$0016(a2),$0070(a0)
	move.w	$000E(a2),$0088(a0)
	move.w	$0018(a2),$0072(a0)
	moveq	#$00,d0
	move.l	d0,$0078(a0)
	move.w	$001A(a2),d0
	add.l	d0,d0
	move.l	d0,$0074(a0)
	move.w	$001C(a2),$007C(a0)
	moveq	#$00,d0
	move.l	d0,$0082(a0)
	move.w	$001E(a2),d0
	add.l	d0,d0
	move.l	d0,$007E(a0)
	move.l	(a2),$005C(a0)
	move.l	$0004(a2),$0060(a0)
	move.l	$0008(a2),$0064(a0)
	move.l	(sp)+,a2
	rts

NoteData
	dc.w	$01C5
	dc.w	$01E0
	dc.w	$01FC
	dc.w	$021A
	dc.w	$023A
	dc.w	$025C
	dc.w	$0280
	dc.w	$02A6
	dc.w	$02D0
	dc.w	$02FA
	dc.w	$0328
	dc.w	$0358
	dc.w	$00E2
	dc.w	$00F0
	dc.w	$00FE
	dc.w	$010D
	dc.w	$011D
	dc.w	$012E
	dc.w	$0140
	dc.w	$0153
	dc.w	$0168
	dc.w	$017D
	dc.w	$0194
	dc.w	$01AC
	dc.w	$0071
	dc.w	$0078
	dc.w	$007F
	dc.w	$0087
	dc.w	$008F
	dc.w	$0097
	dc.w	$00A0
	dc.w	$00AA
	dc.w	$00B4
	dc.w	$00BE
	dc.w	$00CA
	dc.w	$00D6
ChannelData1
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
ChannelData2
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
ChannelData3
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
ChannelData4
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
StateData
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000

