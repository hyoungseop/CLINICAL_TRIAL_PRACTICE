
data DM00; set CRF.DM; run;

*변수 값 확인;
*id 중복없음, 결측 없음;
proc freq data = DM00; run;

*CRF 변수 확인;
proc sql noprint; select name into: CRF_VAR separated by " " from dictionary.columns where libname = 'CRF' and memname = 'DM'; quit;

%put &CRF_VAR;
/*TRIAL_ID USER_ID SEX AGE RACE BIRTH STUDY_START_DATE STUDY_END_DATE SITEID*/

data DM01; set DM00;
attrib
DOMAIN format = $2.
STUDYID format = $20.
SUBJID format = $20.
USUBJID format = $40.
AGE format = 3.
AGEU format = $8.
INVNAM format = $30.
;

*1. 도메인 생성;
DOMAIN = 'DM';

*2. ID 생성;
**1) STUDYID 생성;
STUDYID = TRIAL_ID;
**2) SUBJID 생성;
SUBJID = USER_ID;
**3) USUBJID 생성;
USUBJID = CATX('-',TRIAL_ID,SITEID,USER_ID);

*3. RESTDTC, REENDTC(문자형) 생성;
RFSTDTC = put(input(tranwrd(STUDY_START_DATE,"/","-"),e8601da.),e8601da.);
RFENDTC = put(input(tranwrd(STUDY_END_DATE,"/","-"),e8601da.),e8601da.);

*4. BRTHDTC 생성;
BRTHDTC = put(input(tranwrd(BIRTH,"/","-"),e8601da.),e8601da.);

*5. AGE 생성;
*임상시험 참조 시작일 - 피험자 생년월일;
**본 실험에서는 첫 방문일을 임상시험 참조 시작일로 하기로 함;
AGE = intck('year',input(tranwrd(BIRTH,"/","-"),e8601da.),input(tranwrd(STUDY_START_DATE,"/","-"),e8601da.),"c");

*6. AGEU 생성;
AGEU = 'YEARS';

*7. RACE 대문자로 수정;
RACE = upcase(RACE);

*8. INVNAM 생성;
**임상시험 책임자는 그냥 내 이름 사용;
INVNAM = 'PARK.H.S';

run;

*임상시험 무작위 배정 데이터셋 정제;
data RAND00(index = (USUBJID) rename = (USUBJID1 = USUBJID) drop = STUDYID SITEID SUBJID); set ETC.RANDOMIZATION;
attrib
USUBJID1 format = $40.; 
drop USUBJID;
USUBJID1 = catt(STUDYID,'-',SITEID,'-SUB-',SUBJID);
run;

*DM DOMAIN과 임상시험 무작위 배정 데이터셋 결합;
data DM02;

set DM01;
set RAND00 key = usubjid/unique;

if _iorc_ = %sysrc(_dsenom) then do; call missing(of _all_); end;

run;

*변수 순서 정리 및 제거;
data DM03(keep = STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC SITEID INVNAM BRTHDTC AGE AGEU SEX RACE ARMCD ARM);
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC SITEID INVNAM BRTHDTC AGE AGEU SEX RACE ARMCD ARM;
set DM02;
run;

data SDTM.DM; set DM03; run;