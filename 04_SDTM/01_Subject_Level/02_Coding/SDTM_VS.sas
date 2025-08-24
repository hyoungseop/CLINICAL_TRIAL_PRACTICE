
*SDTM VS 도메인 생성은 SDTM 3.1.2VER 가이드라인의 예시 참고;

**DM 도메인에서 LB 도메인 정제에 필요한 ID(TRIAL_ID, USER_ID, STUDY_ID) 불러오기;
***연구기준일자는 연구시작일(STUDY_START_DATE)로 지정;
data DM_ID(index = (USER_ID)); set CRF.DM;
keep TRIAL_ID SITEID USER_ID;
run;


data VS00; 
attrib
DOMAIN format = $2.
STUDYID format = $20.
SUBJID format = $20.
USUBJID format = $40.
;

set CRF.VS;
set DM_ID key = USER_ID/unique;

*DM DOMAIN과 매칭 시 키값이 VS에 없는 경우 로그 출력;
if _iorc_ = %sysrc(_dsenom) then do;
put "LB도메인과 DM도메인 간 ID 불일치";
end;

*1. DOMAIN 생성;
DOMAIN = 'VS';

*2. ID 생성;
**1) STUDYID 생성;
STUDYID = TRIAL_ID;
**2) SUBJID 생성;
SUBJID = USER_ID;
**3) USUBJID 생성;
USUBJID = CATX('-',TRIAL_ID,SITEID,USER_ID);

*3. VSSEQ 생성
**1) 정렬을 위한 VS_DATE(날짜형) 변수 생성;
VS_DATE_N = input(tranwrd(VS_DATE,'/','-'),e8601da.);
run;

**2) USUBJID, VSTEST, VS_DATE_N 기준 정렬;
**단, 순서 부여는 ID 기준;
proc sort data = VS00; by USUBJID VSTEST VS_DATE_N; run;


data VS01; set VS00;
attrib
VSORRES format = $20.
VSSTRESC format = $20.;

retain VSSEQ;

by USUBJID VSTEST VS_DATE_N;

**3) ID 기준 SEQ 생성;
if first.USUBJID then VSSEQ = 1;
else VSSEQ + 1;

*4. VSTESTCD 생성;
if VSTEST = 'DIABP' then VSTESTCD = 'Diastolic Blood Pressure';
else if VSTEST = 'SYSBP' then VSTESTCD = 'Systolic Blood Pressure';
else if VSTEST = 'Pulse' then VSTESTCD = 'Pulse	Rate';
else if VSTEST = 'Weight' then VSTESTCD = 'Weight';
else if VSTEST = 'Height' then VSTESTCD = 'Height';

*5. VSTEST 생성;
VSTEST1 = upcase(VSTEST);

*6. VSORRES(문자형) 생성;
if VSTEST1 = 'DIABP' then do;
if VS_OUTPUT >= 80 then VSORRES = ">=80";
else VSORRES = put(VS_OUTPUT,4.);
end;

else if VSTEST1 = 'SYSBP' then do;
if VS_OUTPUT >= 140 then VSORRES = ">=140";
else VSORRES = put(VS_OUTPUT,4.);
end;

else if VSTEST1 = 'PULSE' then do;
if VS_OUTPUT < 60 then VSORRES = "< 60";
else if VS_OUTPUT > 100 then VSORRES = '> 100';
else VSORRES = put(VS_OUTPUT,4.);
end;

else VSORRES = put(VS_OUTPUT,4.1);

*7. VSORRESU 생성;
VSORRESU = VS_OUTPUT_UNIT;

*8. VSDTC 생성;
VSDTC = put(input(tranwrd(VS_DATE,'/','-'),e8601da.),e8601da.);

*9. VSSTRESC 생성;
if VSTEST1 in ('DIABP' 'SYSBP' 'PULSE') then VSSTRESC = put(VS_OUTPUT,4.);
else VSSTRESC = put(VS_OUTPUT,4.1);

*10. VSSTRESN 생성;
VSSTRESN = VS_OUTPUT;

*11. VSSTRESU 생성;
VSSTRESU = VS_OUTPUT_UNIT;

drop VSTEST;
run;


data SDTM.SDTM_VS(keep = STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSDTC);
retain STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST1 VSORRES VSORRESU VSSTRESC VSSTRESN VSSTRESU VSDTC;
set VS01;

*12. VSTEST1(대문자) -> VSTEST로 변수명 변경;
rename VSTEST1 = VSTEST;
run;


