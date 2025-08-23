
*SDTM AE 도메인 생성은 SDTM 3.1.2VER 가이드라인의 예시 참고;

**DM 도메인에서 AE 도메인 정제에 필요한 ID(TRIAL_ID, USER_ID, STUDY_ID), 연구기준일자(STUDY_START_DATE) 불러오기;
***연구기준일자는 연구시작일(STUDY_START_DATE)로 지정;
data DM_ID(index = (USER_ID)); set CRF.DM;
keep TRIAL_ID SITEID USER_ID STUDY_START_DATE;
run;


data AE00; 
attrib
DOMAIN format = $2.
STUDYID format = $20.
SUBJID format = $20.
USUBJID format = $40.
;

set CRF.AE;
set DM_ID key = USER_ID/unique;

*DM DOMAIN과 매칭 시 키값이 AE에 없는 경우 로그 출력;
if _iorc_ = %sysrc(_dsenom) then do;
put "AE도메인과 DM도메인 간 ID 불일치";
end;

*1. DOMAIN 생성;
DOMAIN = 'AE';

*2. ID 생성;
**1) STUDYID 생성;
STUDYID = TRIAL_ID;
**2) SUBJID 생성;
SUBJID = USER_ID;
**3) USUBJID 생성;
USUBJID = CATX('-',TRIAL_ID,SITEID,USER_ID);

*3. 이상반응 시작일, 종료일 정제(문자형e8601da);
AESTDTC = put(input(tranwrd(AE_START_DATE,"/","-"),e8601da.),e8601da.);
AEENDTC = put(input(tranwrd(AE_END_DATE,"/","-"),e8601da.),e8601da.);

*4. 이상반응 순서 지정을 위한 이상반응 시작일 날짜 숫자형 변수 추가;
AESTDT = input(tranwrd(AE_START_DATE,"/","-"),e8601da.);

run;


*ID 당 이상반응 순서 지정을 위한 정렬;
proc sort data = AE00; by USUBJID AESTDT; run;


data AE01; set AE00;
attrib
AESEQ format = 3.
AETERM format = $20.
AEDECOD format = $20.
AESEV format = $40.
AESER format = $40.
AEACN format = $40.
;

retain AESEQ;

by USUBJID AESTDT;

*5. id별 이상반응 순서 지정;
if first.USUBJID then AESEQ = 1;
else AESEQ + 1;

*6. AETERM 생성;
**환자나 연구자가 보고한 원본 용어를 정제;
**본 CRF를 통해 얻은 VERBATIM이 증상 + 환자로부터의 보고 형식;
**AE_VERBATIM 변수의 첫번째 문자열 출력;
AETERM = scan(AE_VERBATIM,1);

*7. AEDECOD 생성;
AEDECOD = scan(AE_VERBATIM,1);

*8. AESEV 생성;
AESEV = upcase(AE_SEVERITY);

*9. AESER 생성;
*아래 변수 중 하나라도 속하면 AESER로 구분하나,
 CRF 수집 시 아래의 기준에 부합하는 경우 AE_SERIOUS로
 분류하였다고 가정하여 데이터 정제
	AESDTH = "Y": 사망을 초래
	AESLIFE = "Y": 생명을 위협
	AESHOSP = "Y": 입원을 요하거나 입원기간 연장
	AESDISAB = "Y": 지속적이거나 중대한 장애/무능력 초래
	AESCONG = "Y": 선천적 이상/출생결함
	AESMIE = "Y": 기타 의학적으로 중요한 심각한 사건
	AESCAN = "Y": 암과 관련
;
AESER = AE_SERIOUS;

*10. AEACN(이상반응 후 조치) 생성;
**No action taken -> NOT APPLICABLE : SDTM IG 참고하여 수정;
if AE_ACTION_TAKEN = 'No action taken' then 
AEACN = 'NOT APPLICABLE';
else AEACN = upcase(AE_ACTION_TAKEN);

*11. AESTDY, AEENDY 생성;
**이상사례 발생일자와 종료일자를 연구 기준일로부터 상대적 일수로 계산;
**계산식
AESTDY = (AESTDT ? RFSTDTC) + 1
AEENDY = (AEENDT ? RFSTDTC) + 1
;
AESTDY = (input(AESTDTC,e8601da.) - input(tranwrd(STUDY_START_DATE,"/","-"),e8601da.)) + 1;
AEENDY = (input(AEENDTC,e8601da.) - input(tranwrd(STUDY_START_DATE,"/","-"),e8601da.)) + 1;

run;

*12. SDTM_AE 파일 생성;
data SDTM.SDTM_AE;
retain STUDYID DOMAIN USUBJID AESEQ AETERM AESTDTC AEENDTC
AEDECOD AESEV AESER AEACN AESTDY AEENDY;
set AE01;
keep STUDYID DOMAIN USUBJID AESEQ AETERM AESTDTC AEENDTC
AEDECOD AESEV AESER AEACN AESTDY AEENDY;
run;