
*SDTM LB 도메인 생성은 SDTM 3.1.2VER 가이드라인의 예시 참고;

**DM 도메인에서 LB 도메인 정제에 필요한 ID(TRIAL_ID, USER_ID, STUDY_ID) 불러오기;
***연구기준일자는 연구시작일(STUDY_START_DATE)로 지정;
data DM_ID(index = (USER_ID)); set CRF.DM;
keep TRIAL_ID SITEID USER_ID;
run;


data LB00; 
attrib
DOMAIN format = $2.
STUDYID format = $20.
SUBJID format = $20.
USUBJID format = $40.
;

set CRF.LB;
set DM_ID key = USER_ID/unique;

*DM DOMAIN과 매칭 시 키값이 LB에 없는 경우 로그 출력;
if _iorc_ = %sysrc(_dsenom) then do;
put "LB도메인과 DM도메인 간 ID 불일치";
end;

*1. DOMAIN 생성;
DOMAIN = 'LB';

*2. ID 생성;
**1) STUDYID 생성;
STUDYID = TRIAL_ID;
**2) SUBJID 생성;
SUBJID = USER_ID;
**3) USUBJID 생성;
USUBJID = CATX('-',TRIAL_ID,SITEID,USER_ID);

*3. LBSEQ 생성
**1) 정렬을 위한 LB_DATE(날짜형) 변수 생성;
LB_DATE_N = input(LB_DATE,e8601da.);
run;

**2) USUBJID, LB_TEST, LB_DATE_N 기준 정렬;
**단, 순서 부여는 ID 기준;
proc sort data = LB00; by USUBJID LB_TEST LB_DATE_N; run;


data LB01; set LB00;
attrib
LBORRES format = $20.
LBSTRESC format = $20.
;

retain LBSEQ;

by USUBJID LB_TEST LB_DATE_N;

**3) ID 기준 SEQ 생성;
if first.USUBJID then LBSEQ = 1;
else LBSEQ + 1;

*4. LBTESTCD 생성;
if LB_TEST = 'Fasting glucose' then LBTESTCD = 'GLUCOSE';
else if LB_TEST = 'HbA1c' then LBTESTCD = 'HbA1c';

*5. LBTEST 생성;
LBTEST = LB_TEST;

*6. LBORRES(문자형) 생성;
if LBTEST = 'Fasting glucose' then do;
if LB_OUTPUT >= 126 then LBORRES = ">=126";
else LBORRES = put(LB_OUTPUT,4.);
end;

if LBTEST = 'HbA1c' then do;
if LB_OUTPUT >= 6.5 then LBORRES = ">=6.5";
else LBORRES = put(LB_OUTPUT,4.1);
end;


*7. LBORRESU 생성;
LBORRESU = LB_OUTPUT_UNIT;

*8. LBDTC 생성;
LBDTC = put(input(LB_DATE,e8601da.),e8601da.);

*9. LBSTRESC 생성;
if LBTEST = 'Fasting glucose' then LBSTRESC = put(LB_OUTPUT,4.);
else LBSTRESC = put(LB_OUTPUT,4.1);

*10. LBSTRESN 생성;
LBSTRESN = LB_OUTPUT;

*11. LBSTRESU 생성;
LBSTRESU = LB_OUTPUT_UNIT;

run;


data SDTM.SDTM_LB(keep = STUDYID DOMAIN USUBJID LBSEQ LBTESTCD LBTEST LBORRES LBORRESU LBSTRESC LBSTRESN LBSTRESU LBDTC);
retain STUDYID DOMAIN USUBJID LBSEQ LBTESTCD LBTEST LBORRES LBORRESU LBSTRESC LBSTRESN LBSTRESU LBDTC;
set LB01;
run;









