
*SDTM EX 도메인 생성은 SDTM 3.1.2VER 가이드라인의 예시 참고;

**DM 도메인에서 EX 도메인 정제에 필요한 ID(TRIAL_ID, USER_ID, STUDY_ID) 불러오기;
***연구기준일자는 연구시작일(STUDY_START_DATE)로 지정;
data DM_ID(index = (USER_ID)); set CRF.DM;
keep TRIAL_ID SITEID USER_ID STUDY_START_DATE;
run;


data EX00; 
attrib
DOMAIN format = $2.
STUDYID format = $20.
SUBJID format = $20.
USUBJID format = $40.
EXTRT format = $10.
;

set CRF.EX;
set DM_ID key = USER_ID/unique;

*DM DOMAIN과 매칭 시 키값이 EX에 없는 경우 로그 출력;
if _iorc_ = %sysrc(_dsenom) then do;
put "EX도메인과 DM도메인 간 ID 불일치";
end;

*1. DOMAIN 생성;
DOMAIN = 'EX';

*2. ID 생성;
**1) STUDYID 생성;
STUDYID = TRIAL_ID;
**2) SUBJID 생성;
SUBJID = USER_ID;
**3) USUBJID 생성;
USUBJID = CATX('-',TRIAL_ID,SITEID,USER_ID);

*3. EXSEQ 생성;
*한 id당 한번의 약물을 투여했기 때문에 순서대로 EXSEQ 값 부여;
EXSEQ = _n_;

*4. EXTRT 생성;
if DOSE_CODE = 'DrugA' then EXTRT = 'DRUG A';
else EXTRT = upcase(DOSE_CODE);

*5. EXDOSE 생성;
EXDOSE = compress(DOSE_CONCENTRATION,,'kd') * 1;

*6. EXDOSU 생성;
EXDOSU = scan(compress(DOSE_CONCENTRATION,,'d'),1,"/");

*7. EXSTDTC, EXENDTC 생성;
EXSTDTC = put(input(tranwrd(DOSE_START_DATE,'/','-'),e8601da.),e8601da.);
EXENDTC = put(input(tranwrd(DOSE_END_DATE,'/','-'),e8601da.),e8601da.);

*8. EXSTDY,EXENDY 생성;
EXSTDY = input(tranwrd(DOSE_START_DATE,'/','-'),e8601da.) - input(tranwrd(STUDY_START_DATE,'/','-'),e8601da.) + 1;
EXENDY = input(tranwrd(DOSE_END_DATE,'/','-'),e8601da.) - input(tranwrd(STUDY_START_DATE,'/','-'),e8601da.) + 1;


run;


data SDTM.SDTM_EX;
retain STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXSTDTC EXENDTC EXSTDY EXENDY;
set EX00;
keep STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXSTDTC EXENDTC EXSTDY EXENDY;
run;