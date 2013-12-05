ON ERROR REPORT:PRINT " at line ";ERL:END
END=&8000+512*1024
h%=0
ON ERROR:ON ERROR OFF:PROCclose:ERROR EXT ERR,REPORT$+" at line "+STR$ERL
SYS "Wimp_SlotSize",-1,-1 TO base_slotsize%:membase%=HIMEM:memsize%=0
PROCcommand
PROCass
PROCread_files
PROCinit
PROCwrite_patts
PROCoptimise
IF third_needed% thirdpass%=TRUE:PROCwrite_patts
PROCwrite_samps
IF s3m% PROCwrite_s3m ELSE PROCwrite_dsym
PROCclose
END
:
DEF PROCclose
IF h% CLOSE#h%:h%=0:SYS "OS_File",18,out$,filetype%
ENDPROC
:
DEF PROCcommand
LOCAL com$,n%,syn_str$,flags%
blocksize%=512
DIM b% blocksize%-1
syn_str$="verbose=v/S,in=i/A,out=o/A,song=s/A/E,scream=c/S,name=n"
syn_str$+=",extend=x/S,blankpos=l/S,ignore=g,unaligned=u,patlen=p/E"
SYS "OS_GetEnv" TO com$
n%=INSTR(com$,CHR$34)
n%=INSTR(com$,CHR$34,n%+1)
n%+=2
SYS "XOS_ReadArgs",syn_str$,MID$(com$,n%),b%,blocksize% TO ;flags%
IF flags%AND1 THEN
  PRINT "Syntax: RJPConv [-Verbose] -In <filename> -Out <filename> ";
  PRINT "-Song <subsong_num> [-sCream] [-Name <name>] [-eXtend] [-bLankpos] ";
  PRINT "[-iGnore [0][1][2][3]] [-Unaligned [0][1][2][3]] [-Patlen <len>]"
  END
ENDIF
v%=!b%<>0
in$=FNterm(b%!4)
out$=FNterm(b%!8)
songnum%=?(b%!12+1)
s3m%=b%!16<>0
pal_clockrate%=3546895
IF s3m% THEN
  ds_clockrate%=14317056:filetype%=&1B0
ELSE
  ds_clockrate%=pal_clockrate%:filetype%=&10B
ENDIF
IF b%!20 songname$=FNterm(b%!20) ELSE songname$=""
extend%=b%!24<>0
blankpos%=b%!28<>0
basenote%=25
IF b%!32 ignore$=FNterm(b%!32) ELSE ignore$=""
IF b%!36 unaligned$=FNterm(b%!36) ELSE unaligned$=""
IF b%!40 patlen%=?(!(b%+40)+1) ELSE patlen%=0
IF patlen%>64 ERROR 1<<30,"Invalid pattern length (range 1-64)"
n%=LENin$:WHILE MID$(in$,n%,1)<>".":n%-=1:ENDWHILE
sin$=LEFT$(in$,n%)+"smp"+MID$(in$,n%+4)
ENDPROC
:
DEF FNterm(addr%)
LOCAL str$
WHILE ?addr%>31:str$+=CHR$?addr%:addr%+=1:ENDWHILE
=str$
:
DEF PROCread_files
PROCload(in$,tunedata%,len_smpdata%)
PROCload(sin$,adr_smpdata%,len_smpdata%)
adr_smpdata%+=4:len_smpdata%-=4
tunedata%+=8
PROCoffset(adr_smplist%,len_smplist%)
PROCoffset(adr_volumes%,len_volumes%)
PROCoffset(adr_subsongs%,len_subsongs%)
PROCoffset(adr_seqlist%,len_seqlist%)
PROCoffset(adr_patlist%,len_patlist%)
PROCoffset(adr_seqdata%,len_seqdata%)
PROCoffset(adr_patdata%,len_patdata%)
IF songnum%*4>=len_subsongs% THEN
  ERROR 1<<30,"Subsong doesn't exist (max &"+STR$~(len_subsongs%/4-1)+")"
ENDIF
ENDPROC
:
DEF PROCload(filename$,RETURN buf%,RETURN len%)
LOCAL obj_type%
SYS "OS_File",17,filename$ TO obj_type%,,,,len%
IF obj_type%<>1 ERROR 1<<30,filename$+" not found"
DIM buf% len%-1
SYS "OS_File",16,filename$,buf%
ENDPROC
:
DEF PROCoffset(RETURN adr%,RETURN len%)
len%=FNbe(tunedata%,4):tunedata%+=4
adr%=tunedata%:tunedata%+=len%
ENDPROC
:
DEF PROCinit
LOCAL rjp_endpos%(),rjp_seqlist%(),rjp_pat%()
DIM rjp_endpos%(3),rjp_seqlist%(len_seqlist%/4-1)
_p_used%=0:_p_evtknown%=1:_p_evtunknown%=2:_p_lastspd%=3
DIM rjp_pat%(len_patlist%/4-1,3)
PROCinit_samps
PROCinit_sequence
PROCinit_patterns
PROCinit_channels
PROCinit_subsong
ENDPROC
:
DEF PROCinit_samps
LOCAL smpptr%,smpnum%,n%,ptr%
_s_map%=0:_s_staoffs%=1:_s_stalen%=2:_s_repoffs%=3:_s_replen%=4
_s_vol%=5:_s_tremaddr%=6:_s_tremoffs%=7:_s_tremend%=8:_s_vol1%=9:_s_vol1dur%=10
_s_vol2%=11:_s_vol2dur%=12:_s_vol3%=13:_s_vol3dur%=14:_s_vibraddr%=15
_s_vibroffs%=16:_s_vibrend%=17:_s_blank%=18
DIM rjp_smp%(len_smplist%/32-1,18)
smpptr%=adr_smplist%
FOR smpnum%=0 TO DIM(rjp_smp%(),1)
  n%=adr_smpdata%+FNbe(smpptr%,4)
  rjp_smp%(smpnum%,_s_staoffs%)=n%+FNbe(smpptr%+16,2)*2
  rjp_smp%(smpnum%,_s_stalen%)=FNbe(smpptr%+18,2)*2
  rjp_smp%(smpnum%,_s_blank%)=rjp_smp%(smpnum%,_s_stalen%)<=2
  rjp_smp%(smpnum%,_s_repoffs%)=n%+FNbe(smpptr%+20,2)*2
  rjp_smp%(smpnum%,_s_replen%)=FNbe(smpptr%+22,2)*2
  IF rjp_smp%(smpnum%,_s_replen%)>2 THEN
    ptr%=rjp_smp%(smpnum%,_s_repoffs%)
    n%=rjp_smp%(smpnum%,_s_repoffs%)+rjp_smp%(smpnum%,_s_replen%)
    WHILE ?ptr%=0 AND ptr%<n%:ptr%+=1:ENDWHILE
    IF ptr%=n% rjp_smp%(smpnum%,_s_replen%)=0
  ENDIF
  IF NOT rjp_smp%(smpnum%,_s_blank%) AND rjp_smp%(smpnum%,_s_replen%)<=2 THEN
    ptr%=rjp_smp%(smpnum%,_s_staoffs%)
    n%=rjp_smp%(smpnum%,_s_staoffs%)+rjp_smp%(smpnum%,_s_stalen%)
    WHILE ?ptr%=0 AND ptr%<n%:ptr%+=1:ENDWHILE
    IF ptr%=n% rjp_smp%(smpnum%,_s_blank%)=TRUE
  ENDIF
  IF rjp_smp%(smpnum%,_s_replen%)>2 THEN
    n%=rjp_smp%(smpnum%,_s_repoffs%)+rjp_smp%(smpnum%,_s_replen%)
    IF n%=rjp_smp%(smpnum%,_s_staoffs%)+rjp_smp%(smpnum%,_s_stalen%) THEN
      n%=rjp_smp%(smpnum%,_s_repoffs%)-rjp_smp%(smpnum%,_s_staoffs%)
      IF n%>=0 rjp_smp%(smpnum%,_s_stalen%)=n%
    ENDIF
  ENDIF
  rjp_smp%(smpnum%,_s_vol%)=FNbe(smpptr%+14,2)
  ptr%=adr_volumes%+FNbe(smpptr%+12,2)
  rjp_smp%(smpnum%,_s_vol1%)=?ptr%
  rjp_smp%(smpnum%,_s_vol1dur%)=ptr%?2
  rjp_smp%(smpnum%,_s_vol2%)=ptr%?1
  rjp_smp%(smpnum%,_s_vol2dur%)=ptr%?4
  rjp_smp%(smpnum%,_s_vol3%)=ptr%?3
  rjp_smp%(smpnum%,_s_vol3dur%)=ptr%?5
  n%=FNbe(smpptr%+8,4)
  IF n% THEN
    rjp_smp%(smpnum%,_s_tremaddr%)=adr_smpdata%+n%
    rjp_smp%(smpnum%,_s_tremoffs%)=FNbe(smpptr%+28,2)*2
    rjp_smp%(smpnum%,_s_tremend%)=FNbe(smpptr%+30,2)*2
  ENDIF
  n%=FNbe(smpptr%+4,4)
  IF n% THEN
    rjp_smp%(smpnum%,_s_vibraddr%)=adr_smpdata%+n%
    rjp_smp%(smpnum%,_s_vibroffs%)=FNbe(smpptr%+24,2)*2
    rjp_smp%(smpnum%,_s_vibrend%)=FNbe(smpptr%+26,2)*2
  ENDIF
  smpptr%+=32
NEXT
ENDPROC
:
DEF PROCinit_sequence
LOCAL n%,numchan%,ptr%,seqsta%,finished%,byte%,rjp_chan%
FOR n%=0 TO DIM(rjp_seqlist%(),1)
  rjp_seqlist%(n%)=FNbe(adr_seqlist%+n%*4,4)
NEXT
DIM rjp_seq%(len_seqdata%-1)
numchan%=0
FOR rjp_chan%=0 TO 3
  ptr%=adr_subsongs%?(songnum%*4+rjp_chan%)
  IF ptr% AND ptr%<=DIM(rjp_seqlist%(),1) THEN
    ptr%=rjp_seqlist%(ptr%)
    numchan%+=1
    seqsta%=ptr%
    finished%=FALSE
    REPEAT
      byte%=adr_seqdata%?ptr%
      rjp_seq%(ptr%)=byte%
      IF byte%=0 AND ptr%<DIM(rjp_seq%(),1) THEN
        finished%=TRUE
        ptr%+=1:byte%=adr_seqdata%?ptr%
        CASE TRUE OF
          WHEN byte%=0:rjp_seq%(ptr%)=-1
          WHEN byte%<&80
            byte%=ptr%-byte%
            IF byte%>=seqsta% THEN
              rjp_seq%(ptr%)=byte%
            ELSE
              ERROR 1<<30,"Broken subsong"
            ENDIF
          WHEN byte%>=&80
            ptr%+=1
            rjp_seq%(ptr%-1)=rjp_seqlist%(adr_seqdata%?ptr%)
        ENDCASE
      ELSE
        IF byte% THEN
          rjp_pat%(byte%,_p_used%)=TRUE
        ELSE
          ERROR 1<<30,"Broken subsong"
        ENDIF
      ENDIF
      ptr%+=1
    UNTIL finished%
  ENDIF
NEXT
IF numchan%=0 ERROR 1<<30,"Blank subsong"
ENDPROC
:
DEF PROCinit_patterns
LOCAL patnum%,ptr%,patdelay%,smpnum%,volume%,speed%,finished%,byte%,n%
LOCAL rjp_smpused%()
DIM rjp_smpused%(DIM(rjp_smp%(),1))
_i_num%=0:_i_trempos%=1:_i_vibrpos%=2:_i_note%=3:_i_len%=4:_i_repsta%=5
_i_replen%=6:_i_addr%=7:_i_map%=8:_i_frm%=9:_i_nonote%=10
DIM ds_smp%(62,10),ds_names$(62)
ds_numsamps%=0:thirdpass%=FALSE
FOR patnum%=0 TO DIM(rjp_pat%(),1)
  IF rjp_pat%(patnum%,_p_used%) THEN
    rjp_pat%(patnum%,_p_used%)=FALSE
    ptr%=adr_patdata%+FNbe(adr_patlist%+patnum%*4,4)
    patdelay%=1:smpnum%=0:volume%=-1:speed%=-1
    REPEAT
      finished%=FALSE
      WHILE NOT finished%
        byte%=?ptr%:ptr%+=1
        CASE byte% OF
          WHEN &80,&81,&87:finished%=TRUE
          WHEN &82:speed%=?ptr%:ptr%+=1
          WHEN &83:patdelay%=?ptr%:ptr%+=1
          WHEN &84
            CASE TRUE OF
              WHEN ?ptr%=0
              WHEN ?ptr%=smpnum%
            OTHERWISE
              smpnum%=?ptr%
              IF smpnum%>DIM(rjp_smp%(),1) smpnum%=0
              volume%=-1
            ENDCASE
            ptr%+=1
          WHEN &85:volume%=?ptr%:ptr%+=2
          WHEN &86:ptr%+=5
        OTHERWISE
          finished%=TRUE
          CASE TRUE OF
            WHEN volume%=0
            WHEN volume%=-1 AND rjp_smp%(smpnum%,_s_vol%)=0
            WHEN rjp_smp%(smpnum%,_s_blank%)
          OTHERWISE
            rjp_pat%(patnum%,_p_used%)=TRUE
            IF NOT rjp_smpused%(smpnum%) THEN
              rjp_smpused%(smpnum%)=TRUE
              rjp_smp%(smpnum%,_s_map%)=smpnum%
              PROCcheck_smp(smpnum%)
            ENDIF
            n%=FNnoteconv(byte%)
            n%=FNget_smp(rjp_smp%(smpnum%,_s_map%),0,0,n%)
            third_needed%=FALSE
          ENDCASE
        ENDCASE
      ENDWHILE
      IF byte%<>&80 THEN
        IF speed%=-1 THEN
          rjp_pat%(patnum%,_p_evtunknown%)+=patdelay%
        ELSE
          rjp_pat%(patnum%,_p_evtknown%)+=speed%*patdelay%
        ENDIF
      ENDIF
    UNTIL byte%=&80
    rjp_pat%(patnum%,_p_lastspd%)=speed%
  ENDIF
NEXT
ENDPROC
:
DEF PROCcheck_smp(smpnum%)
LOCAL checksmp%,finished%,n%
WHILE checksmp%<=DIM(rjp_smp%(),1) AND NOT finished%
  CASE TRUE OF
    WHEN checksmp%=smpnum%
    WHEN NOT rjp_smpused%(checksmp%)
    WHEN rjp_smp%(checksmp%,_s_map%)<>checksmp%
  OTHERWISE
    n%=0
    WHILE n%<=DIM(rjp_smp%(),2) AND NOT finished%
      CASE TRUE OF
        WHEN n%=_s_vol%
        WHEN n%=_s_map%
        WHEN rjp_smp%(smpnum%,n%)=rjp_smp%(checksmp%,n%)
      OTHERWISE
        finished%=TRUE
      ENDCASE
      n%+=1
    ENDWHILE
    finished%=NOT finished%
    IF finished% THEN
      rjp_smp%(smpnum%,_s_map%)=checksmp%
      IF v% THEN
        PRINT "Sample &";~smpnum%;"->&";~checksmp%;
        PRINT " (vol &";~rjp_smp%(smpnum%,_s_vol%);")"
      ENDIF
    ELSE
    ENDIF
  ENDCASE
  checksmp%+=1
ENDWHILE
ENDPROC
:
DEF PROCinit_channels
LOCAL rjp_chan%,finished%,ptr%
ds_c%=0
FOR rjp_chan%=0 TO 3
  finished%=FALSE
  ptr%=adr_subsongs%?(songnum%*4+rjp_chan%)
  IF ptr% AND ptr%<=DIM(rjp_seqlist%(),1) THEN
    ptr%=rjp_seqlist%(ptr%)
    WHILE rjp_seq%(ptr%)
      CASE TRUE OF
        WHEN finished%
        WHEN NOT rjp_pat%(rjp_seq%(ptr%),_p_used%)
      OTHERWISE
        finished%=TRUE
        ds_c%+=1
      ENDCASE
      ptr%+=1
    ENDWHILE
  ENDIF
  IF finished% rjp_endpos%(rjp_chan%)=ptr%+1
NEXT
IF ds_c%=0 ERROR 1<<30,"Blank subsong"
ENDPROC
:
DEF PROCinit_subsong
LOCAL ds_seqlen%(),ds_seqini%(),loopsta%(),chan%,rjp_chan%,speed%,loop%,lcm%
LOCAL ptr%,unknown_evt%,patnum%
DIM ds_seqlen%(ds_c%-1),ds_seqini%(ds_c%-1),loopsta%(ds_c%-1)
DIM rjp_posini%(ds_c%-1),ignore%(ds_c%-1),unaligned%(ds_c%-1)
_d_note%=0:_d_smp%=1:_d_com%=2:_d_val%=3
chan%=0
FOR rjp_chan%=0 TO 3
  IF rjp_endpos%(rjp_chan%) THEN
    loopsta%(chan%)=rjp_seq%(rjp_endpos%(rjp_chan%))
    rjp_posini%(chan%)=rjp_seqlist%(adr_subsongs%?(songnum%*4+rjp_chan%))
    IF INSTR(ignore$,STR$rjp_chan%) THEN
      PROCclip(chan%,"user-specified")
    ELSE
      IF INSTR(unaligned$,STR$rjp_chan%) unaligned%(chan%)=TRUE
      speed%=-1:ptr%=rjp_posini%(chan%):unknown_evt%=0
      REPEAT
        patnum%=rjp_seq%(ptr%):loop%=FALSE
        IF loopsta%(chan%)<>-1 AND ptr%>=loopsta%(chan%) loop%=TRUE
        IF loop% THEN
          ds_seqlen%(chan%)+=rjp_pat%(patnum%,_p_evtknown%)
          IF speed%<>-1 THEN
            ds_seqlen%(chan%)+=rjp_pat%(patnum%,_p_evtunknown%)*speed%
          ELSE
            unknown_evt%+=rjp_pat%(patnum%,_p_evtunknown%)
          ENDIF
          IF extend% AND ptr%=loopsta%(chan%) loop%=FALSE
        ENDIF
        IF NOT loop% THEN
          ds_seqini%(chan%)+=rjp_pat%(patnum%,_p_evtknown%)
          IF speed%<>-1 THEN
            ds_seqini%(chan%)+=rjp_pat%(patnum%,_p_evtunknown%)*speed%
          ELSE
            ds_seqini%(chan%)+=rjp_pat%(patnum%,_p_evtunknown%)*6
          ENDIF
        ENDIF
        IF rjp_pat%(patnum%,_p_lastspd%)<>-1 THEN
          speed%=rjp_pat%(patnum%,_p_lastspd%)
        ENDIF
        ptr%+=1
      UNTIL rjp_seq%(ptr%)=0
      IF speed%=-1 speed%=6
      ds_seqlen%(chan%)+=unknown_evt%*speed%
    ENDIF
    chan%+=1
  ENDIF
NEXT
lcm%=FNcheck_seq
restart%=0:loop%=FALSE
FOR chan%=0 TO ds_c%-1
  IF NOT ignore%(chan%) THEN
    IF ds_seqini%(chan%)>restart% restart%=ds_seqini%(chan%)
    IF loopsta%(chan%)<>-1 loop%=TRUE
  ENDIF
NEXT
songlen%=restart%+lcm%
IF NOT loop% restart%=-1
prevevt%=0:firstevt%=0
ENDPROC
:
DEF FNcheck_seq
LOCAL chan%,factors%(),div%,numc%,numfac%,power%(),minval%,lcm%,maxc%,power%
DIM power%(ds_c%-1):power%()=ds_seqlen%()
FOR chan%=0 TO ds_c%-1
  IF power%(chan%)>minval% minval%=power%(chan%)
  IF power%(chan%) numc%+=1
NEXT
IF numc%>1 THEN
  DIM factors%(15,3)
  div%=2:numfac%=0:lcm%=1
  WHILE numc%>0 AND numfac%<=DIM(factors%(),1)
    FOR chan%=0 TO ds_c%-1
      IF power%(chan%)>1 AND power%(chan%)MODdiv%=0 THEN
        power%(chan%)=power%(chan%)/div%
        power%=1
        WHILE power%(chan%)MODdiv%=0
          power%(chan%)=power%(chan%)/div%
          power%+=1
        ENDWHILE
        CASE TRUE OF
          WHEN power%>factors%(numfac%,2)
            factors%(numfac%,3)=factors%(numfac%,2)
            factors%(numfac%,2)=power%
            factors%(numfac%,1)=chan%
          WHEN power%>factors%(numfac%,3)
            factors%(numfac%,3)=power%
        ENDCASE
        IF power%(chan%)=1 numc%-=1
      ENDIF
    NEXT
    IF factors%(numfac%,2)>0 THEN
      lcm%=lcm%*div%^factors%(numfac%,2)
      factors%(numfac%,0)=div%
      factors%(numfac%,2)-=factors%(numfac%,3)
      numfac%+=1
    ENDIF
    div%+=1
  ENDWHILE
  WHILE lcm%>minval%*6
    power%()=1:maxc%=0
    FOR chan%=0 TO ds_c%-1
      IF NOT ignore%(chan%) THEN
        FOR div%=0 TO numfac%-1
          IF factors%(div%,1)=chan% THEN
            power%(chan%)=power%(chan%)*factors%(div%,0)^factors%(div%,2)
          ENDIF
        NEXT
        IF power%(chan%)>power%(maxc%) maxc%=chan%
      ENDIF
    NEXT
    PROCclip(maxc%,"reduce by factor of "+STR$power%(maxc%))
    lcm%=lcm%/power%(maxc%)
  ENDWHILE
ELSE
  lcm%=minval%
ENDIF
=lcm%
:
DEF PROCclip(chan%,text$)
ignore%(chan%)=TRUE:unaligned%(chan%)=TRUE
IF v% PRINT "Warning: clipping channel ";chan%;" (";text$;")"
ENDPROC
:
DEF PROCwrite_patts
LOCAL ds_restartpos%,ds_restartspd%,ds_restartptr%,padptr%,patptr%,ds_spd%
LOCAL songfinished%,newspeed%,ds_patfrm%,songfrm%,chanlooping%,chan%,maxspd%
LOCAL end_patfrm%,num_patend%,patlooping%
LOCAL rjp_spdfreq%(),ds_per%(),ds_vol%(),rjp_pos%(),rjp_slidedepth%(),toggle%()
LOCAL newslide%(),ds_smpfrm%(),rjp_persrc%(),lastevt%(),rjp_pdly%(),rjp_pcnt%()
LOCAL rjp_psmp%(),rjp_subevt%(),trempos%(),rjp_pnote%(),ds_smpnum%(),ds_smplen()
LOCAL sparepitch%(),rjp_pptr%(),rjp_fading%(),rjp_per%(),rjp_spd%(),rjp_pfvol%()
LOCAL ds_volsrc%(),rjp_sliding%(),rjp_pvol%(),sparevol%(),silent%(),vibrpos%()
LOCAL rjp_psmpmap%(),ds_psmpmap%(),rjp_patlens%(),rjp_patfrm%(),ds_smplimit%()
_f_spd%=0:_f_evt%=1
DIM rjp_spdfreq%(5,1),rjp_patlens%(15)
DIM ds_per%(ds_c%-1),ds_vol%(ds_c%-1),rjp_pos%(ds_c%-1),rjp_slidedepth%(ds_c%-1)
DIM toggle%(ds_c%-1),newslide%(ds_c%-1),ds_smpfrm%(ds_c%-1),rjp_persrc%(ds_c%-1)
DIM lastevt%(ds_c%-1),rjp_pdly%(ds_c%-1),rjp_pcnt%(ds_c%-1),rjp_subevt%(ds_c%-1)
DIM trempos%(ds_c%-1),rjp_pnote%(ds_c%-1),ds_smpnum%(ds_c%-1),ds_smplen(ds_c%-1)
DIM vibrpos%(ds_c%-1),rjp_psmp%(ds_c%-1),rjp_pptr%(ds_c%-1),rjp_fading%(ds_c%-1)
DIM rjp_per%(ds_c%-1),rjp_spd%(ds_c%-1),rjp_pfvol%(ds_c%-1),sparepitch%(ds_c%-1)
DIM sparevol%(ds_c%-1),rjp_sliding%(ds_c%-1),rjp_pvol%(ds_c%-1),silent%(ds_c%-1)
DIM ds_volsrc%(ds_c%-1),rjp_psmpmap%(ds_c%-1),ds_psmpmap%(ds_c%-1)
DIM rjp_patfrm%(ds_c%-1),ds_smplimit%(ds_c%-1)
chanlooping%=ds_c%+SUM(ignore%()):patlooping%=ds_c%+SUM(unaligned%())
ds_pos%=0:ds_spd%=6:rjp_spd%()=ds_spd%:rjp_pcnt%()=1:rjp_pvol%()=-1
silent%()=TRUE:rjp_pos%()=rjp_posini%()
FOR chan%=0 TO ds_c%-1:rjp_pptr%(chan%)=FNpatadr(chan%):NEXT
patbase%=membase%:patsta%=patbase%:patptr%=patsta%
WHILE NOT songfinished%
  IF NOT thirdpass% PROCalloc(ds_c%*4+4)
  PROCprocess_notes
  PROCprocess_speed
  PROCprocess_slides
  PROCincrement_samps
  PROCincrement_rjp_ptr
  PROCincrement_ds_ptr
ENDWHILE
ENDPROC
:
DEF PROCprocess_notes
LOCAL chan%,ds_note%,ds_smpnum%,ds_com%,ds_val%,newvol%,smp%
FOR chan%=0 TO ds_c%-1
  patptr%!(chan%*4)=0
  ds_note%=0:ds_smpnum%=0:ds_com%=0:ds_val%=0
  rjp_pnote%(chan%)=0:rjp_pfvol%(chan%)=-1:newslide%(chan%)=FALSE
  IF rjp_subevt%(chan%)=0 AND rjp_pos%(chan%)<>-1 THEN
    PROCget_note(chan%)
    newvol%=rjp_pfvol%(chan%)
    IF newvol%<>-1 ds_vol%(chan%)=newvol%:ds_com%=&C:ds_val%=newvol%
    ds_note%=rjp_pnote%(chan%):smp%=rjp_psmp%(chan%)
    IF ds_note%=-1 THEN
      ds_note%=0:ds_volsrc%(chan%)=ds_vol%(chan%)
      rjp_fading%(chan%)=rjp_smp%(smp%,_s_vol3dur%)
    ENDIF
    IF ds_note% THEN
      ds_smpnum%=FNget_smp(smp%,trempos%(chan%),vibrpos%(chan%),ds_note%)
      ds_psmpmap%(chan%)=(ds_smp%(ds_smpnum%-1,_i_map%)AND&FF)+1
      ds_smpnum%=(ds_smp%(ds_psmpmap%(chan%)-1,_i_map%)>>8)+1
      IF newvol%=-1 ds_vol%(chan%)=rjp_smp%(smp%,_s_vol%)
      ds_per%(chan%)=periods_ds%!((ds_note%-1)*4)
    ENDIF
  ENDIF
  patptr%?(chan%*4+_d_note%)=ds_note%
  patptr%?(chan%*4+_d_smp%)=ds_smpnum%
  patptr%?(chan%*4+_d_com%)=ds_com%
  patptr%?(chan%*4+_d_val%)=ds_val%
NEXT
ENDPROC
:
DEF PROCget_note(chan%)
LOCAL pb%,finished%,ptr%,n%,smp%,newvol%,newsmp%
lastevt%(chan%)=FALSE
rjp_pcnt%(chan%)-=1
IF rjp_pcnt%(chan%)=0 THEN
  finished%=FALSE
  WHILE NOT finished%
    pb%=FNpb(chan%)
    CASE pb% OF
      WHEN &80:rjp_pptr%(chan%)=FNpatadr(chan%)
      WHEN &81:rjp_pnote%(chan%)=-1:toggle%(chan%)=0:finished%=TRUE
      WHEN &82:rjp_spd%(chan%)=FNpb(chan%)
      WHEN &83:rjp_pdly%(chan%)=FNpb(chan%)
      WHEN &84
        pb%=FNpb(chan%)
        IF pb% AND pb%<>rjp_psmpmap%(chan%) THEN
          rjp_psmpmap%(chan%)=pb%
          IF rjp_psmpmap%(chan%)>DIM(rjp_smp%(),1) rjp_psmpmap%(chan%)=0
          rjp_psmp%(chan%)=rjp_smp%(rjp_psmpmap%(chan%),_s_map%)
          rjp_pvol%(chan%)=rjp_smp%(rjp_psmpmap%(chan%),_s_vol%)
          IF rjp_pvol%(chan%)=rjp_smp%(rjp_psmp%(chan%),_s_vol%) THEN
            rjp_pvol%(chan%)=-1
          ENDIF
          newvol%=TRUE:newsmp%=TRUE
        ENDIF
      WHEN &85:rjp_pvol%(chan%)=FNpb(chan%):rjp_pptr%(chan%)+=1:newvol%=TRUE
      WHEN &86
        rjp_sliding%(chan%)=FNpb(chan%):newslide%(chan%)=TRUE:toggle%(chan%)=1
        rjp_slidedepth%(chan%)=FNbe(rjp_pptr%(chan%),4):rjp_pptr%(chan%)+=4
      WHEN &87:finished%=TRUE
    OTHERWISE
      finished%=TRUE:sparevol%(chan%)=0:rjp_fading%(chan%)=0:newvol%=FALSE
      smp%=rjp_psmpmap%(chan%):rjp_pfvol%(chan%)=0:silent%(chan%)=TRUE
      IF NOT newslide%(chan%) THEN
        sparepitch%(chan%)=0:rjp_sliding%(chan%)=0:rjp_slidedepth%(chan%)=0
      ENDIF
      CASE TRUE OF
        WHEN rjp_pvol%(chan%)=0
        WHEN smp%=0
        WHEN rjp_pvol%(chan%)=-1 AND rjp_smp%(smp%,_s_vol%)=0
        WHEN rjp_smp%(smp%,_s_blank%)
      OTHERWISE
        rjp_pnote%(chan%)=FNnoteconv(pb%)
        rjp_persrc%(chan%)=periods%!((rjp_pnote%(chan%)-1)*4)<<16
        rjp_per%(chan%)=rjp_persrc%(chan%)
        silent%(chan%)=FALSE:rjp_pfvol%(chan%)=rjp_pvol%(chan%)
      ENDCASE
      IF newsmp% THEN
        trempos%(chan%)=0:vibrpos%(chan%)=0
      ELSE
        IF rjp_smp%(smp%,_s_tremaddr%) THEN
          n%=trempos%(chan%)+ds_smpfrm%(chan%)
          IF n%>=rjp_smp%(smp%,_s_tremend%) OR n%<&40 n%=0
          trempos%(chan%)=n%
        ENDIF
        IF rjp_smp%(smp%,_s_vibraddr%) THEN
          n%=vibrpos%(chan%)+ds_smpfrm%(chan%)
          IF n%>=rjp_smp%(smp%,_s_vibrend%) OR n%<&40 n%=0
          vibrpos%(chan%)=n%
        ENDIF
      ENDIF
    ENDCASE
  ENDWHILE
  rjp_pcnt%(chan%)=rjp_pdly%(chan%)
  IF newvol% rjp_pfvol%(chan%)=rjp_pvol%(chan%)
  IF NOT unaligned%(chan%) THEN
    n%=0
    WHILE rjp_spdfreq%(n%,_f_spd%) AND rjp_spdfreq%(n%,_f_spd%)<>rjp_spd%(chan%)
      n%+=1
    ENDWHILE
    rjp_spdfreq%(n%,_f_spd%)=rjp_spd%(chan%)
    rjp_spdfreq%(n%,_f_evt%)+=rjp_spd%(chan%)*rjp_pdly%(chan%)
  ENDIF
ENDIF
IF rjp_pcnt%(chan%)=1 THEN
  ptr%=rjp_pptr%(chan%):finished%=FALSE
  WHILE NOT finished%
    pb%=?ptr%:ptr%+=1
    CASE pb% OF
      WHEN &80:lastevt%(chan%)=TRUE:finished%=TRUE
      WHEN &82,&83,&84:ptr%+=1
      WHEN &85:ptr%+=2
      WHEN &86:ptr%+=5
    OTHERWISE
      finished%=TRUE
    ENDCASE
  ENDWHILE
ENDIF
ENDPROC
:
DEF FNpb(chan%)
rjp_pptr%(chan%)+=1
=?(rjp_pptr%(chan%)-1)
:
DEF FNnoteconv(pb%)
pb%=pb% DIV 2
=12*(pb%DIV12+1)-pb%MOD12
:
DEF FNpatadr(chan%)
=adr_patdata%+FNbe(adr_patlist%+rjp_seq%(rjp_pos%(chan%))*4,4)
:
DEF FNget_smp(rjp_smpnum%,trempos%,vibrpos%,RETURN ds_note%)
LOCAL ds_smpnum%,nonote%,smp_test%,note_diff%,n%
CASE TRUE OF
  WHEN rjp_smp%(rjp_smpnum%,_s_vol1%)<>rjp_smp%(rjp_smpnum%,_s_vol2%)
  WHEN rjp_smp%(rjp_smpnum%,_s_vol2%)<>rjp_smp%(rjp_smpnum%,_s_vol3%)
  WHEN rjp_smp%(rjp_smpnum%,_s_tremaddr%)<>0
  WHEN rjp_smp%(rjp_smpnum%,_s_vibraddr%)<>0
OTHERWISE
  nonote%=TRUE
ENDCASE
note_diff%=-1:ds_smpnum%=-1
WHILE smp_test%<ds_numsamps%
  CASE TRUE OF
    WHEN ds_smp%(smp_test%,_i_num%)<>rjp_smpnum%
    WHEN nonote%:ds_smpnum%=smp_test%
    WHEN ds_smp%(smp_test%,_i_trempos%)<>trempos%
    WHEN ds_smp%(smp_test%,_i_vibrpos%)<>vibrpos%
  OTHERWISE
    n%=ds_note%-ds_smp%(smp_test%,_i_note%)
    IF n%<6 AND n%>-6 AND (ABSn%<note_diff% OR note_diff%=-1) THEN
      note_diff%=ABSn%:ds_smpnum%=smp_test%
    ENDIF
  ENDCASE
  smp_test%+=1
ENDWHILE
IF ds_smpnum%=-1 THEN
  ds_smpnum%=ds_numsamps%
  ds_smp%(ds_smpnum%,_i_num%)=rjp_smpnum%
  ds_smp%(ds_smpnum%,_i_note%)=ds_note%
  IF nonote% ds_smp%(ds_smpnum%,_i_nonote%)=TRUE
  ds_smp%(ds_smpnum%,_i_trempos%)=trempos%
  ds_smp%(ds_smpnum%,_i_vibrpos%)=vibrpos%
  IF v% THEN
    PRINT "Sample &";~(ds_smpnum%+1),~rjp_smpnum%;
    PRINT ~ds_smp%(ds_smpnum%,_i_note%),~trempos%,~vibrpos%
  ENDIF
  IF thirdpass% ERROR 1<<30,"Attempt to create sample on third pass"
  ds_smp%(ds_smpnum%,_i_map%)=ds_smpnum% OR (ds_smpnum%<<8)
  ds_numsamps%+=1
  third_needed%=TRUE
ENDIF
IF NOT ds_smp%(ds_smpnum%,_i_nonote%) THEN
  ds_note%=basenote%+ds_note%-ds_smp%(ds_smpnum%,_i_note%)
ENDIF
=ds_smpnum%+1
:
DEF PROCprocess_speed
LOCAL mincount%,chan%,n%,maxcount%
FOR chan%=0 TO ds_c%-1
  n%=rjp_spd%(chan%)-rjp_subevt%(chan%)
  IF rjp_pos%(chan%)<>-1 AND (mincount%>n% OR mincount%=0) mincount%=n%
NEXT
IF mincount% THEN
  IF songfrm%<restart% AND songfrm%+mincount%>restart% THEN
    mincount%=restart%-songfrm%
  ENDIF
  IF songfrm%<songlen% AND songfrm%+mincount%>songlen% THEN
    mincount%=songlen%-songfrm%
  ENDIF
  IF mincount%<>ds_spd% newspeed%=TRUE:ds_spd%=mincount%
ENDIF
IF songfrm%=restart% THEN
  ds_restartpos%=ds_pos%:ds_restartspd%=ds_spd%:ds_restartptr%=patptr%
ENDIF
n%=0
WHILE rjp_spdfreq%(n%,_f_spd%)
  CASE TRUE OF
    WHEN rjp_spdfreq%(n%,_f_evt%)<rjp_spdfreq%(maxcount%,_f_evt%)
    WHEN rjp_spdfreq%(n%,_f_evt%)>rjp_spdfreq%(maxcount%,_f_evt%)
      maxcount%=n%
    WHEN rjp_spdfreq%(n%,_f_spd%)>rjp_spdfreq%(maxcount%,_f_spd%)
      maxcount%=n%
  ENDCASE
  n%+=1
ENDWHILE
maxspd%=rjp_spdfreq%(maxcount%,_f_spd%)
ENDPROC
:
DEF PROCprocess_slides
LOCAL chan%,ds_com%,ds_val%,dur%,mul%,src%,tgt%,n%
FOR chan%=0 TO ds_c%-1
  IF silent%(chan%) THEN
    rjp_fading%(chan%)=0:rjp_sliding%(chan%)=0
    sparevol%(chan%)=0:sparepitch%(chan%)=0
  ENDIF
  ds_com%=patptr%?(chan%*4+_d_com%)
  ds_val%=patptr%?(chan%*4+_d_val%)
  IF rjp_fading%(chan%) THEN
    dur%=rjp_smp%(rjp_psmp%(chan%),_s_vol3dur%)
    mul%=ds_spd%
    IF mul%>rjp_fading%(chan%) mul%=rjp_fading%(chan%)
    src%=ds_volsrc%(chan%)*rjp_fading%(chan%)/dur%+sparevol%(chan%)
    rjp_fading%(chan%)-=mul%
    tgt%=ds_volsrc%(chan%)*rjp_fading%(chan%)/dur%
    IF toggle%(chan%) THEN
      sparevol%(chan%)=src%-tgt%
    ELSE
      IF ds_spd%>1 THEN
        ds_com%=&A
        ds_val%=(src%-tgt%) DIV (ds_spd%-1)
        IF ds_val%>15 ds_val%=15
        n%=ds_val%*(ds_spd%-1)
        ds_vol%(chan%)-=n%
        sparevol%(chan%)=src%-tgt%-n%
        IF ds_val%=0 ds_com%=0
      ELSE
        ds_com%=&C
        ds_val%=tgt%
        ds_vol%(chan%)=ds_val%
        sparevol%(chan%)=0
      ENDIF
    ENDIF
  ELSE
    IF sparevol%(chan%) THEN
      sparevol%(chan%)=0:ds_vol%(chan%)=0
      ds_com%=&C:ds_val%=0
    ENDIF
  ENDIF
  IF ds_com% THEN
    patptr%?(chan%*4+_d_com%)=ds_com%
    patptr%?(chan%*4+_d_val%)=ds_val%
    IF ds_vol%(chan%)=0 THEN
      rjp_fading%(chan%)=0:rjp_sliding%(chan%)=0
      sparevol%(chan%)=0:sparepitch%(chan%)=0
    ENDIF
    IF ds_com%=&C AND ds_val%=0 silent%(chan%)=TRUE
  ENDIF
  CASE TRUE OF
    WHEN rjp_sliding%(chan%)=0:toggle%(chan%)=0
    WHEN ds_com%=0:toggle%(chan%)=0
    WHEN rjp_pfvol%(chan%)<>-1:toggle%(chan%)=1
    WHEN rjp_fading%(chan%)=0:toggle%(chan%)=0
  OTHERWISE
    toggle%(chan%)=toggle%(chan%) EOR 1
  ENDCASE
  IF rjp_sliding%(chan%) THEN
    mul%=ds_spd%
    IF mul%>rjp_sliding%(chan%) mul%=rjp_sliding%(chan%)
    src%=rjp_per%(chan%)>>>16
    IF newslide%(chan%) rjp_per%(chan%)=rjp_persrc%(chan%)
    rjp_sliding%(chan%)-=mul%
    rjp_per%(chan%)+=rjp_slidedepth%(chan%)*mul%
    tgt%=rjp_per%(chan%)>>>16
    tgt%=(ds_per%(chan%)+sparepitch%(chan%))*tgt%/src%
    IF toggle%(chan%) THEN
      sparepitch%(chan%)=tgt%-ds_per%(chan%)
    ELSE
      PROCpslide(chan%,ds_com%,ds_val%,tgt%,ds_spd%-1)
    ENDIF
  ELSE
    IF sparepitch%(chan%) THEN
      PROCpslide(chan%,ds_com%,ds_val%,ds_per%(chan%)+sparepitch%(chan%),0)
    ENDIF
  ENDIF
  IF ds_com% THEN
    patptr%?(chan%*4+_d_com%)=ds_com%
    patptr%?(chan%*4+_d_val%)=ds_val%
  ENDIF
NEXT
IF newspeed% PROCpoke(patptr%,&F,ds_spd%):newspeed%=FALSE
ENDPROC
:
DEF PROCpslide(chan%,RETURN ds_com%,RETURN ds_val%,tgt%,mul%)
LOCAL up%,down%,limit%,n%
IF mul% up%=1:down%=2:limit%=&DF ELSE mul%=1:up%=&11:down%=&1B:limit%=&F
ds_val%=(tgt%-ds_per%(chan%)) DIV mul%
IF s3m% ds_val%=ds_val%/4
IF ABSds_val%>limit% ds_val%=limit%*SGNds_val%
n%=ds_val%*mul%
IF s3m% n%=n%*4
sparepitch%(chan%)=tgt%-ds_per%(chan%)-n%
ds_per%(chan%)+=n%
CASE SGNds_val% OF
  WHEN 0:ds_com%=0
  WHEN 1:ds_com%=down%
  WHEN -1:ds_com%=up%:ds_val%=-ds_val%
ENDCASE
ENDPROC
:
DEF PROCincrement_samps
LOCAL chan%,ds_com%,ds_val%,newsamp%,n%,per%,rjp_smpnum%
FOR chan%=0 TO ds_c%-1
  ds_com%=patptr%?(chan%*4+_d_com%)
  ds_val%=patptr%?(chan%*4+_d_val%)
  CASE TRUE OF
    WHEN silent%(chan%):newsamp%=-1
    WHEN patptr%?(chan%*4+_d_note%)=0:newsamp%=0
  OTHERWISE
    newsamp%=ds_psmpmap%(chan%)
  ENDCASE
  IF newsamp% THEN
    IF newsamp%=-1 newsamp%=0
    ds_smpnum%(chan%)=newsamp%
    ds_smpfrm%(chan%)=0
    ds_smplen(chan%)=0
  ENDIF
  IF newsamp% THEN
    rjp_smpnum%=ds_smp%(newsamp%-1,_i_num%):ds_smplimit%(chan%)=0
    IF rjp_smp%(rjp_smpnum%,_s_vol3%)=0 THEN
      n%=rjp_smp%(rjp_smpnum%,_s_vol1dur%)
      IF rjp_smp%(rjp_smpnum%,_s_vol2%) n%+=rjp_smp%(rjp_smpnum%,_s_vol2dur%)+1
      ds_smplimit%(chan%)=FNceil(n%*frequency/50)
    ENDIF
    CASE TRUE OF
      WHEN rjp_smp%(rjp_smpnum%,_s_vibraddr%)<>0
      WHEN rjp_smp%(rjp_smpnum%,_s_replen%)>2
    OTHERWISE
      n%=rjp_smp%(rjp_smpnum%,_s_stalen%)
      IF NOT ds_smp%(newsamp%-1,_i_nonote%) THEN
        per%=periods%!((ds_smp%(newsamp%-1,_i_note%)-1)*4)
        n%=FNceil(n%*frequency/(pal_clockrate%/per%))
      ENDIF
      IF n%<ds_smplimit%(chan%) OR ds_smplimit%(chan%)=0 ds_smplimit%(chan%)=n%
    ENDCASE
  ENDIF
  ds_smpfrm%(chan%)+=ds_spd%
  IF ds_smpnum%(chan%) THEN
    IF NOT thirdpass% THEN
      IF ds_smpfrm%(chan%)>ds_smp%(ds_smpnum%(chan%)-1,_i_frm%) THEN
        ds_smp%(ds_smpnum%(chan%)-1,_i_frm%)=ds_smpfrm%(chan%)
      ENDIF
    ENDIF
    IF ds_com%=1 OR ds_com%=2 THEN
      FOR n%=0 TO ds_spd%-1
        per%=n%*ds_val%*(3-ds_com%*2):IF s3m% per%=per%*4
        ds_smplen(chan%)+=(ds_clockrate%/(ds_per%(chan%)+per%))/50
      NEXT
    ELSE
      ds_smplen(chan%)+=((ds_clockrate%/ds_per%(chan%))/50)*ds_spd%
    ENDIF
    n%=FNceil(ds_smplen(chan%))
    IF n%>ds_smp%(ds_smpnum%(chan%)-1,_i_len%) THEN
      ds_smp%(ds_smpnum%(chan%)-1,_i_len%)=n%
    ENDIF
    IF ds_smplimit%(chan%) AND n%>ds_smplimit%(chan%) silent%(chan%)=TRUE
  ENDIF
  IF ds_vol%(chan%)=0 silent%(chan%)=TRUE
NEXT
ENDPROC
:
DEF PROCincrement_rjp_ptr
LOCAL chan%,n%
songfrm%+=ds_spd%:ds_patfrm%+=ds_spd%:patptr%!(ds_c%*4)=ds_patfrm%
patptr%+=ds_c%*4+4:num_patend%=0
FOR chan%=0 TO ds_c%-1
  IF rjp_pos%(chan%)<>-1 THEN
    IF NOT unaligned%(chan%) rjp_patfrm%(chan%)+=ds_spd%
    rjp_subevt%(chan%)+=ds_spd%
    IF rjp_subevt%(chan%)=rjp_spd%(chan%) THEN
      rjp_subevt%(chan%)=0
      IF lastevt%(chan%) THEN
        IF NOT unaligned%(chan%) THEN
          n%=-1
          REPEAT
            n%+=1
            IF rjp_patlens%(n%)MODrjp_patfrm%(chan%)=0 THEN
              rjp_patlens%(n%)=rjp_patfrm%(chan%)
            ENDIF
          UNTIL rjp_patfrm%(chan%)MODrjp_patlens%(n%)=0
          rjp_patfrm%(chan%)=0
        ENDIF
        rjp_pos%(chan%)+=1
        IF rjp_seq%(rjp_pos%(chan%))=0 THEN
          rjp_pos%(chan%)=rjp_seq%(rjp_pos%(chan%)+1)
        ENDIF
        CASE TRUE OF
          WHEN ignore%(chan%)
          WHEN rjp_pos%(chan%)<>-1:IF NOT unaligned%(chan%) num_patend%+=1
          WHEN chanlooping%>1
            chanlooping%-=1:IF NOT unaligned%(chan%) patlooping%-=1
        OTHERWISE
          padptr%=((patptr%-patsta%)/(ds_c%*4+4)+63ANDNOT63)-blankpos%*64
          padptr%=patsta%+padptr%*(ds_c%*4+4)
          chanlooping%=0:patlooping%=0:end_patfrm%=ds_patfrm%
        ENDCASE
      ENDIF
    ENDIF
  ENDIF
NEXT
ENDPROC
:
DEF PROCincrement_ds_ptr
LOCAL patfinished%,n%,evt%,endpat%,new_patfrm%,smallest%,bcom%,chan%
patfinished%=TRUE
CASE TRUE OF
  WHEN restart%<>-1 AND songfrm%=songlen%:songfinished%=TRUE
  WHEN chanlooping%=0 AND patptr%=padptr%:songfinished%=TRUE
  WHEN songfrm%=restart%
  WHEN num_patend%=patlooping% AND patlooping%>0
OTHERWISE
  patfinished%=FALSE
ENDCASE
IF patfinished% THEN
  IF v% THEN
    PRINT';~songfrm%;":";
    FOR chan%=0 TO ds_c%-1:PRINT TAB(8+chan%*8);~rjp_pos%(chan%);:NEXT:PRINT
  ENDIF
  IF patlen% THEN
    new_patfrm%=patlen%*maxspd%
  ELSE
    n%=0
    REPEAT
      CASE TRUE OF
        WHEN rjp_patlens%(n%)MODmaxspd%<>0
        WHEN rjp_patlens%(n%)>&40*maxspd%
          IF rjp_patlens%(n%)<smallest% OR smallest%=0 THEN
            smallest%=rjp_patlens%(n%)
          ENDIF
        WHEN rjp_patlens%(n%)<new_patfrm%
      OTHERWISE
        new_patfrm%=rjp_patlens%(n%)
      ENDCASE
      n%+=1
    UNTIL rjp_patlens%(n%)=0
    IF new_patfrm%=0 THEN
      IF prevevt% THEN
        new_patfrm%=prevevt%*maxspd%
      ELSE
        IF smallest% new_patfrm%=smallest% ELSE new_patfrm%=rjp_patlens%(0)
        WHILE new_patfrm%MOD2=0 AND new_patfrm%>&40*maxspd%
          new_patfrm%=new_patfrm%DIV2
        ENDWHILE
        IF new_patfrm%>&40*maxspd% new_patfrm%=&40*maxspd%
        firstevt%=new_patfrm%DIVmaxspd%
      ENDIF
    ENDIF
    WHILE new_patfrm%<=&20*maxspd%:new_patfrm%=new_patfrm%*2:ENDWHILE
  ENDIF
  prevevt%=new_patfrm%DIVmaxspd%
  evt%=0
  FOR n%=patsta%+ds_c%*4 TO patptr%-4 STEP ds_c%*4+4
    evt%+=1:endpat%=FALSE
    CASE TRUE OF
      WHEN !n%MODnew_patfrm%=0 AND (chanlooping%>0 OR !n%<end_patfrm%)
        endpat%=TRUE
      WHEN n%=patptr%-4:endpat%=TRUE
      WHEN evt%=64:endpat%=TRUE
    ENDCASE
    IF endpat% THEN
      IF v% PRINT "pos=";~ds_pos%;TAB(8);"evt=";~evt%;TAB(16);"frm=";~!n%
      IF restart%<>-1 AND songfrm%=songlen% AND n%=patptr%-4 THEN
        IF v% PRINT "Jump to ";~ds_restartpos%
        IF ds_restartspd%<>ds_spd% PROCpoke(ds_restartptr%,&F,ds_restartspd%)
        IF ds_restartpos% bcom%=TRUE
      ENDIF
      IF bcom% THEN
        PROCpoke(n%-ds_c%*4,&B,ds_restartpos%)
      ELSE
        IF evt%<64 PROCpoke(n%-ds_c%*4,&D,0)
      ENDIF
      !n%=!n%OR(1<<31):ds_pos%+=1:evt%=0
    ENDIF
  NEXT
  patsta%=patptr%:rjp_spdfreq%()=0:rjp_patlens%()=0:ds_patfrm%=0
ENDIF
ENDPROC
:
DEF PROCpoke(patptr%,ds_com%,ds_val%)
LOCAL chan%,tmp%(),max%,n%
DIM tmp%(ds_c%-1)
FOR chan%=0 TO ds_c%-1
  CASE patptr%?(chan%*4+_d_com%) OF
    WHEN 0:tmp%(chan%)=5
    WHEN 1,2,&11,&1B:tmp%(chan%)=1
    WHEN &A:tmp%(chan%)=2
    WHEN &C
      IF patptr%?(chan%*4+_d_val%) THEN
        tmp%(chan%)=3
      ELSE
        tmp%(chan%)=4
      ENDIF
    WHEN &B,&D:IF ds_com%=&B OR ds_com%=&D tmp%(chan%)=6
    WHEN &F:IF ds_com%=&F tmp%(chan%)=6
  ENDCASE
NEXT
max%=0:n%=0
FOR chan%=0 TO ds_c%-1
  IF tmp%(chan%)>max% max%=tmp%(chan%):n%=chan%
NEXT
patptr%?(n%*4+_d_com%)=ds_com%
patptr%?(n%*4+_d_val%)=ds_val%
ENDPROC
:
DEF PROCoptimise
LOCAL ds_smpnum%,volslide%,per%,len%,mcheck%,patptr%,n%,rjp_smpnum%
DIM ds_pat%(ds_pos%)
ds_pat%(0)=patbase%:n%=0
FOR patptr%=patbase%+ds_c%*4 TO patsta%-4 STEP ds_c%*4+4
  IF !patptr%<0 n%+=1:ds_pat%(n%)=patptr%+4
NEXT
IF firstevt% AND firstevt%<>prevevt% third_needed%=TRUE
new_numsamps%=0
FOR ds_smpnum%=0 TO ds_numsamps%-1
  rjp_smpnum%=ds_smp%(ds_smpnum%,_i_num%)
  volslide%=TRUE
  CASE TRUE OF
    WHEN ds_smp%(ds_smpnum%,_i_frm%)=0
    WHEN ds_smp%(ds_smpnum%,_i_nonote%)
    WHEN rjp_smp%(rjp_smpnum%,_s_vol1%)<>rjp_smp%(rjp_smpnum%,_s_vol2%)
    WHEN rjp_smp%(rjp_smpnum%,_s_vol2%)=rjp_smp%(rjp_smpnum%,_s_vol3%)
      volslide%=FALSE
    WHEN rjp_smp%(rjp_smpnum%,_s_vol1dur%)+2>=ds_smp%(ds_smpnum%,_i_frm%)
      volslide%=FALSE
    WHEN rjp_smp%(rjp_smpnum%,_s_vibraddr%)<>0
    WHEN rjp_smp%(rjp_smpnum%,_s_replen%)<=2
      per%=periods%!((ds_smp%(ds_smpnum%,_i_note%)-1)*4)
      len%=rjp_smp%(rjp_smpnum%,_s_stalen%)*frequency/(pal_clockrate%/per%)
      IF (frequency/50)*(rjp_smp%(rjp_smpnum%,_s_vol1dur%)+2)>=len% THEN
        volslide%=FALSE
      ENDIF
  ENDCASE
  mcheck%=ds_smpnum%
  CASE TRUE OF
    WHEN ds_smp%(ds_smpnum%,_i_frm%)=0
      ds_smp%(ds_smpnum%,_i_map%)=ds_smp%(ds_smpnum%,_i_map%)OR&FF
      third_needed%=TRUE
    WHEN ds_smp%(ds_smpnum%,_i_nonote%):volslide%=FALSE
    WHEN volslide%
    WHEN rjp_smp%(rjp_smpnum%,_s_tremaddr%)<>0
    WHEN rjp_smp%(rjp_smpnum%,_s_vibraddr%)<>0
  OTHERWISE
    ds_smp%(ds_smpnum%,_i_nonote%)=TRUE:third_needed%=TRUE
    mcheck%=-1
    REPEAT
      mcheck%+=1
    UNTIL ds_smp%(mcheck%,_i_num%)=rjp_smpnum% AND ds_smp%(mcheck%,_i_nonote%)
    ds_smp%(ds_smpnum%,_i_map%)=(ds_smp%(ds_smpnum%,_i_map%)AND&FF00)ORmcheck%
  ENDCASE
  ds_smp%(ds_smpnum%,_i_map%)=ds_smp%(ds_smpnum%,_i_map%)AND&FF
  ds_smp%(ds_smpnum%,_i_map%)=ds_smp%(ds_smpnum%,_i_map%)OR(new_numsamps%<<8)
  IF mcheck%=ds_smpnum% AND ds_smp%(ds_smpnum%,_i_frm%) new_numsamps%+=1
  ds_smp%(ds_smpnum%,_i_frm%)=volslide%
NEXT
IF new_numsamps%=0 ERROR 1<<30,"Blank subsong"
IF third_needed% THEN
  IF v% PRINT "Third pass needed!"
  FOR ds_smpnum%=0 TO ds_numsamps%-1:ds_smp%(ds_smpnum%,_i_len%)=0:NEXT
ENDIF
ENDPROC
:
DEF PROCwrite_samps
LOCAL ds_smpnum%,n%
smpsta%=patsta%
FOR ds_smpnum%=0 TO ds_numsamps%-1
  IF v% PRINT "Sample &";~ds_smpnum%+1;
  CASE TRUE OF
    WHEN (ds_smp%(ds_smpnum%,_i_map%)AND&FF)=&FF:IF v% PRINT " (blank)"
    WHEN (ds_smp%(ds_smpnum%,_i_map%)AND&FF)<>ds_smpnum%
      IF v% PRINT "->";~(ds_smp%(ds_smpnum%,_i_map%)AND&FF)+1
  OTHERWISE
    ds_smp%(ds_smpnum%,_i_len%)=(ds_smp%(ds_smpnum%,_i_len%)+1ANDNOT1)
    IF v% THEN
      PRINT " ==";~(ds_smp%(ds_smpnum%,_i_map%)>>8)+1;
      PRINT ~ds_smp%(ds_smpnum%,_i_len%);
    ENDIF
    PROCput_smp(ds_smpnum%)
    IF v% PRINT ~ds_smp%(ds_smpnum%,_i_len%)
    ds_names$(ds_smpnum%)="S"+STR$~ds_smp%(ds_smpnum%,_i_num%)
    IF NOT ds_smp%(ds_smpnum%,_i_nonote%) THEN
      ds_names$(ds_smpnum%)+="-N"+STR$~ds_smp%(ds_smpnum%,_i_note%)
    ENDIF
    IF rjp_smp%(ds_smp%(ds_smpnum%,_i_num%),_s_tremaddr%) THEN
      ds_names$(ds_smpnum%)+="-T"+STR$~ds_smp%(ds_smpnum%,_i_trempos%)
    ENDIF
    IF rjp_smp%(ds_smp%(ds_smpnum%,_i_num%),_s_vibraddr%) THEN
      ds_names$(ds_smpnum%)+="-V"+STR$~ds_smp%(ds_smpnum%,_i_vibrpos%)
    ENDIF
    FOR n%=0 TO DIM(ds_smp%(),2)
      ds_smp%(ds_smp%(ds_smpnum%,_i_map%)>>8,n%)=ds_smp%(ds_smpnum%,n%)
    NEXT
    ds_names$(ds_smp%(ds_smpnum%,_i_map%)>>8)=ds_names$(ds_smpnum%)
  ENDCASE
NEXT
ds_numsamps%=new_numsamps%
ENDPROC
:
DEF PROCput_smp(ds_smpnum%)
LOCAL finished%,ds_repsta%,ds_replen%,vol%,per%,endptr%,perbase%,maxlen%,init%
LOCAL tremsta%,trem%,vibrsta%,vibr%,wb%,fracptr,nonote%,tgtreplen%,len%,endvol%
LOCAL volcount%,voldur%,volsrc%,voltgt%,volstage%,ticklen%,result%,newfreq,vlen%
LOCAL rjp_smpnum%
rjp_smpnum%=ds_smp%(ds_smpnum%,_i_num%):ds_smp%(ds_smpnum%,_i_replen%)=2
trem%=ds_smp%(ds_smpnum%,_i_trempos%):vibr%=ds_smp%(ds_smpnum%,_i_vibrpos%)
PROCalloc(1):?smpsta%=0:smpsta%+=1:smpptr%=smpsta%:fracptr=smpptr%
newfreq=frequency:nonote%=ds_smp%(ds_smpnum%,_i_nonote%)
perbase%=periods%!((ds_smp%(ds_smpnum%,_i_note%)-1)*4)
ds_replen%=0:ds_repsta%=-1
chanblock%!_a_repaddr%=rjp_smp%(rjp_smpnum%,_s_repoffs%)
chanblock%!_a_replen%=rjp_smp%(rjp_smpnum%,_s_replen%)>>1
chanblock%!_a_staaddr%=rjp_smp%(rjp_smpnum%,_s_staoffs%)
chanblock%!_a_stalen%=rjp_smp%(rjp_smpnum%,_s_stalen%)>>1
chanblock%!_a_highpos%=0:chanblock%!_a_lowpos%=0
?rjp_smp%(rjp_smpnum%,_s_staoffs%)=0:rjp_smp%(rjp_smpnum%,_s_staoffs%)?1=0
volsrc%=rjp_smp%(rjp_smpnum%,_s_vol1%):voltgt%=rjp_smp%(rjp_smpnum%,_s_vol2%)
voldur%=rjp_smp%(rjp_smpnum%,_s_vol1dur%):volcount%=voldur%
IF ds_smp%(ds_smpnum%,_i_frm%) volstage%=2 ELSE volstage%=0
vibrsta%=rjp_smp%(rjp_smpnum%,_s_vibraddr%)
tremsta%=rjp_smp%(rjp_smpnum%,_s_tremaddr%)
maxlen%=ds_smp%(ds_smpnum%,_i_len%)
CASE TRUE OF
  WHEN tremsta%<>0,vibrsta%<>0
  WHEN volstage%=0:vlen%=0:endvol%=volsrc%
  WHEN voltgt%=rjp_smp%(rjp_smpnum%,_s_vol3%) AND voldur%*frequency/50<maxlen%
    vlen%=voldur%*frequency/50:endvol%=voltgt%
  WHEN (voldur%+1+rjp_smp%(rjp_smpnum%,_s_vol3%))*frequency/50<maxlen%
    vlen%=(voldur%+1+rjp_smp%(rjp_smpnum%,_s_vol3%))*frequency/50
    endvol%=rjp_smp%(rjp_smpnum%,_s_vol3%)
OTHERWISE
  vlen%=maxlen%:endvol%=rjp_smp%(rjp_smpnum%,_s_vol3%)
ENDCASE
IF endvol%=0 AND vlen%<maxlen% maxlen%=vlen%
len%=rjp_smp%(rjp_smpnum%,_s_replen%)
CASE TRUE OF
  WHEN tremsta%<>0,vibrsta%<>0
  WHEN nonote%:chanblock%!_a_increment%=&1000000:tgtreplen%=len%
  WHEN len%<=2
OTHERWISE
  tgtreplen%=INT(len%*frequency*perbase%/pal_clockrate%/2+0.5)*2
  IF tgtreplen%<600 len%=len%*FNceil(600/tgtreplen%)
  init%=rjp_smp%(rjp_smpnum%,_s_stalen%)*frequency*perbase%/pal_clockrate%
  IF vlen%>init% init%=vlen%
  IF init%+len%<maxlen% THEN
    tgtreplen%=INT(len%*frequency*perbase%/pal_clockrate%/2+0.5)*2
    newfreq=tgtreplen%*pal_clockrate%/perbase%/len%
  ENDIF
ENDCASE
WHILE NOT finished%
  IF volstage% THEN
    vol%=voltgt%+(volcount%/voldur%)*(volsrc%-voltgt%):volcount%-=1
    IF volcount%<0 THEN
      volstage%-=1:voldur%=rjp_smp%(rjp_smpnum%,_s_vol2dur%):volcount%=voldur%
      volsrc%=voltgt%:voltgt%=rjp_smp%(rjp_smpnum%,_s_vol3%)
      IF volsrc%=voltgt% volstage%=0
    ENDIF
  ELSE
    vol%=voltgt%
    IF vol%=0 finished%=TRUE:ds_repsta%=-1:ds_replen%=0
  ENDIF
  IF tremsta% THEN
    vol%+=(((tremsta%?trem%<<24)>>24)*vol%)/128:trem%+=1
    IF trem%=rjp_smp%(rjp_smpnum%,_s_tremend%) THEN
      trem%=rjp_smp%(rjp_smpnum%,_s_tremoffs%)
    ENDIF
  ENDIF
  IF vol%<0 vol%=0 ELSE IF vol%>&40 vol%=&40
  chanblock%!_a_vol%=vol%
  IF NOT nonote% THEN
    per%=perbase%
    IF vibrsta% THEN
      wb%=(vibrsta%?vibr%<<24)>>24:vibr%+=1
      IF wb%<=0 per%=per%*(1-wb%/128) ELSE per%=per%*(1-wb%/256)
      IF vibr%=rjp_smp%(rjp_smpnum%,_s_vibrend%) THEN
        vibr%=rjp_smp%(rjp_smpnum%,_s_vibroffs%)
      ENDIF
    ENDIF
    IF per%<2 per%=2 ELSE IF per%>&FFFF per%=&FFFF
    chanblock%!_a_increment%=((pal_clockrate%/per%)/newfreq)*&1000000
  ENDIF
  chanblock%!_a_repeated%=0
  IF NOT finished% THEN
    !buf_chanbuf%=fracptr:fracptr+=newfreq/50:!buf_size%=fracptr
    ticklen%=!buf_size%-!buf_chanbuf%
    PROCalloc(ticklen%)
    result%=USR(buf_code%)
    CASE TRUE OF
      WHEN result%=smpptr%+ticklen%
      WHEN result%>=smpptr%
        result%-=smpptr%:ds_replen%=0:ds_repsta%=-1:finished%=TRUE
      WHEN tremsta%<>0,vibrsta%<>0,volstage%<>0
      WHEN ds_repsta%<>-1
        ds_replen%=smpptr%-smpsta%+result%-ds_repsta%:finished%=TRUE
      WHEN chanblock%!_a_repeated%=0
        ds_repsta%=smpptr%-smpsta%+result%
    OTHERWISE
      ds_repsta%=smpptr%-smpsta%+result%
      ds_replen%=chanblock%!_a_repeated%-result%
      result%=chanblock%!_a_repeated%
      finished%=TRUE
    ENDCASE
    IF ds_replen% AND ds_replen%<tgtreplen% finished%=FALSE
    IF NOT finished% result%=ticklen%
    smpptr%+=result%
  ENDIF
  IF smpptr%-smpsta%>ds_smp%(ds_smpnum%,_i_len%) THEN
    finished%=TRUE:ds_replen%=0:ds_repsta%=-1
    endptr%=smpsta%+ds_smp%(ds_smpnum%,_i_len%)
  ELSE
    endptr%=smpptr%
  ENDIF
ENDWHILE
IF ds_replen% THEN
  endptr%-=1
  WHILE ?endptr%=0 AND endptr%>smpsta%+ds_repsta%:endptr%-=1:ENDWHILE
  IF ?endptr%=0 ds_repsta%=-1:ds_replen%=0 ELSE endptr%=smpptr%
ENDIF
IF ds_replen%=0 THEN
  IF endptr%>smpsta% THEN
    endptr%-=1:WHILE ?endptr%=0 AND endptr%>smpsta%:endptr%-=1:ENDWHILE
    IF ?endptr% endptr%+=1
  ENDIF
  IF endptr%-smpsta%AND1 smpsta%-=1
ELSE
  IF ds_repsta%AND1 smpsta%-=1:ds_repsta%+=1
  ds_replen%=tgtreplen%ANDNOT1
  ds_smp%(ds_smpnum%,_i_repsta%)=ds_repsta%
  ds_smp%(ds_smpnum%,_i_replen%)=ds_replen%
  endptr%=smpsta%+ds_repsta%+ds_replen%
ENDIF
ds_smp%(ds_smpnum%,_i_len%)=endptr%-smpsta%
IF ds_smp%(ds_smpnum%,_i_len%)=0 ds_smp%(ds_smpnum%,_i_replen%)=0
PROCalloc(result%-ticklen%+endptr%-smpptr%)
ds_smp%(ds_smpnum%,_i_addr%)=smpsta%:smpsta%=endptr%
ENDPROC
:
DEF FNceil(n)
IF n=INTn =n ELSE =INT(n+1)
:
DEF PROCwrite_s3m
LOCAL s3m_patmap%(),blankpat%,src%,srcsta%,srclen%,tgt%,tgt2%,tgtsta%,tgtlen%,n%
LOCAL chan%,notequal%,s3m_savepat%,s3m_pos%,endheader%,pattable%,patendptr%,evt%
LOCAL ds_note%,ds_smp%,ds_com%,ds_val%,half%,smp%,smpendptr%
DIM s3m_patmap%(ds_pos%-1)
FOR src%=0 TO ds_pos%-1:s3m_patmap%(src%)=src%:NEXT
blankpat%=-1
FOR src%=0 TO ds_pos%-1
  srcsta%=ds_pat%(src%):srclen%=ds_pat%(src%+1)-ds_pat%(src%)
  IF s3m_patmap%(src%)=src% THEN
    IF blankpat%=-1 THEN
      blankpat%=src%:n%=0
      REPEAT
        chan%=0
        REPEAT
          IF srcsta%!(n%+chan%*4) blankpat%=-1
          chan%+=1
        UNTIL chan%=ds_c% OR blankpat%=-1
        n%+=ds_c%*4+4
      UNTIL n%=srclen% OR blankpat%=-1
    ENDIF
    FOR tgt2%=0 TO ds_pos%-1
      IF tgt2%<>src% THEN
        tgt%=s3m_patmap%(tgt2%)
        tgtsta%=ds_pat%(tgt%):tgtlen%=ds_pat%(tgt%+1)-ds_pat%(tgt%)
        IF tgtlen%=srclen% THEN
          n%=0:notequal%=FALSE
          REPEAT
            chan%=0
            REPEAT
              IF tgtsta%!(n%+chan%*4)<>srcsta%!(n%+chan%*4) notequal%=TRUE
              chan%+=1
            UNTIL chan%=ds_c% OR notequal%
            n%+=ds_c%*4+4
          UNTIL n%=tgtlen% OR notequal%
          IF NOT notequal% s3m_patmap%(tgt2%)=src%
        ENDIF
      ENDIF
    NEXT
  ENDIF
NEXT
s3m_savepat%=0
FOR n%=0 TO ds_pos%-1
  IF s3m_patmap%(n%)=n% s3m_patmap%(n%)=(s3m_savepat%OR&100):s3m_savepat%+=1
NEXT
FOR n%=0 TO ds_pos%-1
  IF (s3m_patmap%(n%)AND&100)=0 THEN
    s3m_patmap%(n%)=s3m_patmap%(s3m_patmap%(n%))AND&FF
  ENDIF
  IF v% PRINT "Pattern &";~n%;"->&";~(s3m_patmap%(n%)AND&FF)
NEXT
IF NOT blankpos% AND blankpat%<>-1 THEN
  blankpat%=(s3m_patmap%(blankpat%)AND&FF)
  IF v% PRINT "Blank pattern &";~blankpat%
  WHILE (s3m_patmap%(ds_pos%-1)AND&FF)=blankpat%:ds_pos%-=1:ENDWHILE
ENDIF
s3m_pos%=((ds_pos%+2)ANDNOT1)
songname$=LEFT$(songname$,28)
h%=OPENOUT(out$)
BPUT#h%,songname$;
PTR#h%=28
BPUT#h%,&1A
BPUT#h%,16
PROCle(2,0)
PROCle(2,s3m_pos%)
PROCle(2,ds_numsamps%)
PROCle(2,s3m_savepat%)
PROCle(2,16)
PROCle(2,&1320)
PROCle(2,2)
BPUT#h%,"SCRM";
BPUT#h%,&40
BPUT#h%,&6
BPUT#h%,&7D
BPUT#h%,&C0
BPUT#h%,&0
BPUT#h%,&0
PROCle(4,0)
PROCle(4,0)
PROCle(2,0)
FOR chan%=0 TO ds_c%-1:BPUT#h%,(chan%>>1)+((chan%AND1)<<3):NEXT
FOR chan%=ds_c% TO 31:BPUT#h%,255:NEXT
endheader%=((&6F+s3m_pos%+ds_numsamps%*2+s3m_savepat%*2)ANDNOT&F)
FOR n%=0 TO ds_pos%-1:BPUT#h%,(s3m_patmap%(n%)AND&FF):NEXT
FOR n%=ds_pos% TO s3m_pos%-1:BPUT#h%,255:NEXT
FOR n%=0 TO ds_numsamps%-1:PROCle(2,(endheader%+n%*&50)>>4):NEXT
pattable%=PTR#h%:patendptr%=endheader%+ds_numsamps%*&50
FOR src%=0 TO ds_pos%-1
  IF s3m_patmap%(src%)AND&100 THEN
    PROCle(2,patendptr%>>4):pattable%+=2
    PTR#h%=patendptr%+2
    srcsta%=ds_pat%(src%):srclen%=ds_pat%(src%+1)-ds_pat%(src%)
    evt%=0
    WHILE evt%<srclen%
      FOR chan%=0 TO ds_c%-1
        ds_note%=srcsta%?(evt%+chan%*4+_d_note%)
        ds_smp%=srcsta%?(evt%+chan%*4+_d_smp%)
        ds_com%=srcsta%?(evt%+chan%*4+_d_com%)
        ds_val%=srcsta%?(evt%+chan%*4+_d_val%)
        n%=chan%
        IF ds_note% n%=n%OR32
        IF ds_com%=&C n%=n%OR64 ELSE IF ds_com% n%=n%OR128
        IF n%<>chan% BPUT#h%,n%
        IF ds_note% THEN
          n%=48-(basenote%-1)+(ds_note%-1)
          BPUT#h%,(n%DIV12<<4)+n%MOD12
          BPUT#h%,ds_smp%
        ENDIF
        IF ds_com% THEN
          IF ds_com%<>&C THEN
            CASE ds_com% OF
              WHEN &1:ds_com%=6
              WHEN &2:ds_com%=5
              WHEN &A:ds_com%=4
              WHEN &B:ds_com%=2
              WHEN &D:ds_com%=3
              WHEN &F:ds_com%=1
              WHEN &11:ds_com%=6:ds_val%=ds_val%OR&F0
              WHEN &1B:ds_com%=5:ds_val%=ds_val%OR&F0
            ENDCASE
            BPUT#h%,ds_com%
          ENDIF
          BPUT#h%,ds_val%
        ENDIF
      NEXT
      BPUT#h%,0
      evt%+=ds_c%*4+4
    ENDWHILE
    WHILE evt%<(ds_c%*4+4)*64:BPUT#h%,0:evt%+=ds_c%*4+4:ENDWHILE
    n%=patendptr%:patendptr%=PTR#h%
    PTR#h%=n%:PROCle(2,patendptr%-(n%+2))
    patendptr%=(patendptr%+&F)ANDNOT&F
    PTR#h%=pattable%
  ENDIF
NEXT
IF ds_numsamps%>1 THEN
  n%=0
  FOR smp%=0 TO ds_numsamps%-2:n%+=((ds_smp%(smp%,_i_len%)+&F)ANDNOT&F):NEXT
  IF patendptr%+n%>=&100000 THEN
    half%=TRUE
    PRINT "Warning: file too large"
    FOR smp%=0 TO ds_numsamps%-1
      ds_smp%(smp%,_i_len%)=ds_smp%(smp%,_i_len%)DIV2
      ds_smp%(smp%,_i_repsta%)=ds_smp%(smp%,_i_repsta%)DIV2
      ds_smp%(smp%,_i_replen%)=ds_smp%(smp%,_i_replen%)DIV2
    NEXT
  ENDIF
ENDIF
PTR#h%=endheader%:smpendptr%=patendptr%
FOR smp%=0 TO ds_numsamps%-1
  ds_names$(smp%)=LEFT$(ds_names$(smp%),28)
  IF ds_smp%(smp%,_i_replen%)<=2 ds_smp%(smp%,_i_replen%)=0
  BPUT#h%,1
  PTR#h%=endheader%+smp%*&50+&E
  PROCle(2,smpendptr%>>4):smpendptr%+=((ds_smp%(smp%,_i_len%)+&F)ANDNOT&F)
  PROCle(4,ds_smp%(smp%,_i_len%))
  PROCle(4,ds_smp%(smp%,_i_repsta%))
  PROCle(4,ds_smp%(smp%,_i_repsta%)+ds_smp%(smp%,_i_replen%))
  BPUT#h%,rjp_smp%(ds_smp%(smp%,_i_num%),_s_vol%)
  BPUT#h%,0
  BPUT#h%,0
  IF ds_smp%(smp%,_i_replen%) BPUT#h%,1 ELSE BPUT#h%,0
  IF half% THEN
    PROCle(4,frequency/2)
  ELSE
    PROCle(4,frequency)
  ENDIF
  PROCle(4,0)
  PROCle(2,0)
  PROCle(2,0)
  PROCle(4,0)
  BPUT#h%,ds_names$(smp%);
  PTR#h%=endheader%+smp%*&50+&4C
  BPUT#h%,"SCRS";
NEXT
PTR#h%=patendptr%
FOR smp%=0 TO ds_numsamps%-1
  WHILE (PTR#h%AND&F):BPUT#h%,&80:ENDWHILE
  n%=0:IF half% ds_smp%(smp%,_i_len%)=ds_smp%(smp%,_i_len%)*2
  WHILE n%<ds_smp%(smp%,_i_len%)
    BPUT#h%,((ds_smp%(smp%,_i_addr%)?n%)EOR&80)
    n%+=1-half%
  ENDWHILE
NEXT
ENDPROC
:
DEF PROCwrite_dsym
LOCAL ds_patmap%(),src%,n%,tgt%,tgt2%,ds_savepat%,chan%,smp%
LOCAL srcsta%,srclen%,tgtsta%,tgtlen%,evt%
DIM ds_patmap%(ds_pos%*ds_c%-1)
FOR src%=0 TO ds_pos%*ds_c%-1:ds_patmap%(src%)=src%:NEXT
FOR src%=0 TO ds_pos%*ds_c%-1
  srcsta%=ds_pat%(src%DIVds_c%)+(src%MODds_c%)*4
  srclen%=ds_pat%(src%DIVds_c%+1)-ds_pat%(src%DIVds_c%)
  n%=0:WHILE srcsta%!n%=0 AND n%<srclen%-(ds_c%*4+4):n%+=ds_c%*4+4:ENDWHILE
  CASE TRUE OF
    WHEN srcsta%!n%=0:ds_patmap%(src%)=&1000
    WHEN ds_patmap%(src%)<>src%
  OTHERWISE
    FOR tgt2%=0 TO ds_pos%*ds_c%-1
      IF ds_patmap%(tgt2%)<>&1000 AND tgt2%<>src% THEN
        tgt%=ds_patmap%(tgt2%)
        tgtsta%=ds_pat%(tgt%DIVds_c%)+(tgt%MODds_c%)*4
        tgtlen%=ds_pat%(tgt%DIVds_c%+1)-ds_pat%(tgt%DIVds_c%)
        IF tgtlen%<=srclen% THEN
          n%=0
          WHILE tgtsta%!n%=srcsta%!n% AND n%<tgtlen%-(ds_c%*4+4)
            n%+=ds_c%*4+4
          ENDWHILE
          IF tgtsta%!n%=srcsta%!n% ds_patmap%(tgt2%)=src%
        ENDIF
      ENDIF
    NEXT
  ENDCASE
NEXT
ds_savepat%=0
FOR n%=0 TO ds_pos%*ds_c%-1
  IF ds_patmap%(n%)=n% ds_patmap%(n%)=(ds_savepat%OR&2000):ds_savepat%+=1
NEXT
FOR n%=0 TO ds_pos%*ds_c%-1
  IF (ds_patmap%(n%)AND&3000)=0 THEN
    ds_patmap%(n%)=ds_patmap%(ds_patmap%(n%))AND&1FFF
  ENDIF
  IF v% PRINT "Pattern &";~n%;"->&";~(ds_patmap%(n%)AND&1FFF)
NEXT
IF NOT blankpos% THEN
  n%=(ds_pos%-1)*ds_c%
  REPEAT
    chan%=ds_c%-1:WHILE ds_patmap%(n%+chan%)=&1000 AND chan%>0:chan%-=1:ENDWHILE
    IF ds_patmap%(n%+chan%)=&1000 ds_pos%-=1:n%-=ds_c%
  UNTIL ds_patmap%(n%+chan%)<>&1000 OR ds_pos%=0
ENDIF
IF ds_pos%=0 ERROR 1<<30,"Blank subsong"
songname$=LEFT$(songname$,32)
h%=OPENOUT(out$)
BPUT#h%,2
BPUT#h%,1
BPUT#h%,19
BPUT#h%,19
BPUT#h%,20
BPUT#h%,18
BPUT#h%,1
BPUT#h%,11
BPUT#h%,1
BPUT#h%,ds_c%
PROCle(2,ds_pos%)
PROCle(2,ds_savepat%)
PROCle(3,0)
smp%=0
WHILE smp%<ds_numsamps%
  ds_names$(smp%)=LEFT$(ds_names$(smp%),22)
  IF ds_smp%(smp%,_i_len%) THEN
    BPUT#h%,LENds_names$(smp%):PROCle(3,ds_smp%(smp%,_i_len%)>>1)
  ELSE
    BPUT#h%,LENds_names$(smp%)OR&80
  ENDIF
  smp%+=1
ENDWHILE
WHILE smp%<63:BPUT#h%,&80:smp%+=1:ENDWHILE
BPUT#h%,LENsongname$:BPUT#h%,songname$;
PROCle(4,-1):PROCle(4,-1)
BPUT#h%,0:FOR n%=0 TO ds_pos%*ds_c%-1:PROCle(2,ds_patmap%(n%)AND&1FFF):NEXT
BPUT#h%,0
FOR src%=0 TO ds_pos%*ds_c%-1
  IF ds_patmap%(src%)AND&2000 THEN
    srcsta%=ds_pat%(src%DIVds_c%)+(src%MODds_c%)*4
    srclen%=ds_pat%(src%DIVds_c%+1)-ds_pat%(src%DIVds_c%)
    evt%=0
    WHILE evt%<srclen%
      n%=srcsta%?(evt%+_d_note%)
      n%+=srcsta%?(evt%+_d_smp%)<<6
      n%+=srcsta%?(evt%+_d_com%)<<14
      n%+=srcsta%?(evt%+_d_val%)<<20
      PROCle(4,n%)
      evt%+=ds_c%*4+4
    ENDWHILE
    WHILE evt%<(ds_c%*4+4)*64:PROCle(4,0):evt%+=ds_c%*4+4:ENDWHILE
  ENDIF
NEXT
FOR smp%=0 TO ds_numsamps%-1
  BPUT#h%,ds_names$(smp%);
  IF ds_smp%(smp%,_i_len%) THEN
    PROCle(3,ds_smp%(smp%,_i_repsta%)>>1)
    PROCle(3,ds_smp%(smp%,_i_replen%)>>1)
    BPUT#h%,rjp_smp%(ds_smp%(smp%,_i_num%),_s_vol%)
    BPUT#h%,0
    BPUT#h%,2
    SYS "OS_GBPB",2,h%,ds_smp%(smp%,_i_addr%),ds_smp%(smp%,_i_len%)
  ENDIF
NEXT
WHILE (PTR#h%AND3):BPUT#h%,0:ENDWHILE
ENDPROC
:
DEF FNbe(addr%,bytes%)
LOCAL value%,n%
bytes%-=1
FOR n%=0 TO bytes%:value%+=addr%?n%<<((bytes%-n%)*8):NEXT
=value%
:
DEF PROCle(bytes%,word%)
LOCAL n%
FOR n%=0 TO bytes%-1:BPUT#h%,((word%>>>(n%*8))AND255):NEXT
ENDPROC
:
DEF PROCalloc(size%)
memsize%+=size%:SYS "Wimp_SlotSize",base_slotsize%+memsize%,-1
ENDPROC
:
DEF PROCass
LOCAL code%,codelimit%,pass%,buf_main_loop%,buf_repend%,buf_end%
LOCAL n%,s3m_periods%(),note%
DIM s3m_periods%(11)
s3m_periods%()=1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,0960,0907
codelimit%=4096
DIM code% codelimit%-1
FOR pass%=8 TO 10 STEP 2
P%=code%:L%=code%+codelimit%
[OPT pass%
.periods%
  EQUD &358
  EQUD &328
  EQUD &2FA
  EQUD &2D0
  EQUD &2A6
  EQUD &280
  EQUD &25C
  EQUD &23A
  EQUD &21A
  EQUD &1FC
  EQUD &1E0
  EQUD &1C5
  EQUD &1AC
  EQUD &194
  EQUD &17D
  EQUD &168
  EQUD &153
  EQUD &140
  EQUD &12E
  EQUD &11D
  EQUD &10D
  EQUD &FE
  EQUD &F0
  EQUD &E2
  EQUD &D6
  EQUD &CA
  EQUD &BE
  EQUD &B4
  EQUD &AA
  EQUD &A0
  EQUD &97
  EQUD &8F
  EQUD &87
  EQUD &7F
  EQUD &78
  EQUD &71
.periods_ds%
]
frequency=pal_clockrate%/periods%!((basenote%-1)*4)
IF s3m% THEN
  FOR n%=0 TO 35
    note%=48-(basenote%-1)+n%
    [OPT pass%:EQUD 16*(s3m_periods%(note%MOD12)>>(note%DIV12))*8363/frequency:]
  NEXT
ELSE
  FOR n%=0 TO 35:[OPT pass%:EQUD periods%!(n%*4):]:NEXT
ENDIF
_a_repaddr%=0
_a_replen%=4
_a_staaddr%=8
_a_stalen%=12
_a_increment%=16
_a_vol%=20
_a_highpos%=24
_a_lowpos%=28
_a_repeated%=32
[OPT pass%
.chanblock%
  EQUD 0 ; 0 = new address of start of sample data
  EQUD 0 ; 4 = new sample repeat length (in halfwords)
  EQUD 0 ; 8 = current address
  EQUD 0 ; 12 = current repeat length (in halfwords)
  EQUD 0 ; 16 = sample increment value
  EQUD 0 ; 20 = sample volume
  EQUD 0 ; 24 = sample offset high word (whole)
  EQUD 0 ; 28 = sample offset low word (fractional)
  EQUD 0 ; 32 = repeat length if applicable
.buf_chanbuf%
  EQUD 0
.buf_code%
  ; during code:
  ; R0,R1 = scratch space
  ; R3 = address of current position in buffer
  ; R4 = address of start of sample data
  ; R5 = offset of repeat end position
  ; R6 = sample increment value
  ; R7 = sample volume
  ; R8 = high word of sample position (whole)
  ; R9 = low word of sample position (fractional)
  ; R10 = byte read
  ; R12 = status; -1=normal, other=loop offset
  ; on exit:
  ; sample offsets updated
  ; 0 <= R3 < length - a loop took place at offset R3
  ; buffer < R3 < buffer+length - reached the end of an unlooped
  ; sample, R3 points to end of data actually written
  ; R3 = buffer+length - data written normally
  STMFD R13!,{R14}
  ADR   R0,chanblock%+_a_staaddr%
  LDMIA R0,{R4-R9}
  MOV   R5,R5,LSL #1
  LDR   R3,buf_chanbuf%
  MVN   R12,#0
.buf_main_loop%
  CMP   R8,R5 ; have we passed the repeat end position?
    BLT   buf_repend%
  SUB   R8,R8,R5 ; keep any overflow bytes
  LDR   R5,chanblock%+_a_replen%
  CMP   R5,#1 ; is the new length <=2 bytes?
    BLE   buf_end% ; if so, there is no repeat - finish
  STR   R5,chanblock%+_a_stalen% ; transfer new length to our copy
  MOV   R5,R5,LSL #1
  LDR   R4,chanblock%+_a_repaddr% ; transfer new start address to our copy
  STR   R4,chanblock%+_a_staaddr%
  LDR   R0,buf_chanbuf% ; we've passed a repeat marker - write status info
  SUB   R0,R3,R0 ; note where the repeat occurred
  CMN   R12,#1
    MOVEQ R12,R0 ; if we haven't repeated yet, it's a start
    STRNE R0,chanblock%+_a_repeated% ; otherwise, it's a finish
.buf_repend%
  LDRB  R10,[R4,R8] ; get our byte from the sample data
  MOV   R10,R10,LSL #24 ; sign-extend
  MOV   R10,R10,ASR #24
  MUL   R10,R7,R10 ; scale by volume
  MOV   R10,R10,ASR #6
  ADDS  R9,R9,R6,LSL #8 ; increment our counters
  ADCS  R8,R8,R6,LSR #24
  STRB  R10,[R3],#1 ; store byte read in buffer
  LDR   R0,buf_size% ; until we reach the end of the buffer
  CMP   R3,R0
    BLT   buf_main_loop%
.buf_end%
  CMN   R12,#1
    MOVNE R3,R12
  STR   R8,chanblock%+_a_highpos%
  STR   R9,chanblock%+_a_lowpos%
  MOV   R0,R3
  LDMFD R13!,{PC}
.buf_size%
  EQUD  0
]
NEXT
ENDPROC
