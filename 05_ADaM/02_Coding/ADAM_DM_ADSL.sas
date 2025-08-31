
*ADAM IG 1.0 ADSL 참고;

*1. 각 도메인에서 필요한 변수 추출;
*1) 무작위 배정일 추출;
data RANDOMIZATION(keep = USUBJID RANDDT); set RAND.RANDOMIZATION; run;

*2) 약 투여일, 무작위 배정 변수 추출;
data SDTM_EX(keep = USUBJID EXSTDTC EXENDTC EXTRT); set SDTM.SDTM_EX; run;

*3) 첫번째 진단일 체중, 키 변수 추출;
data SDTM_VS00(keep = USUBJID DATE VSTEST VSORRES); set SDTM.SDTM_VS; DATE = input(VSDTC,e8601da.); where VSTEST in ('HEIGHT' 'WEIGHT'); run;
data SDTM_VS01; 
set SDTM_VS00(WHERE = (VSTEST = 'HEIGHT') rename = (VSORRES = HEIGHT));
set SDTM_VS00(WHERE = (VSTEST = 'WEIGHT') rename = (VSORRES = WEIGHT));
run;

proc sort data = SDTM_VS01; by USUBJID DATE; run;

data SDTM_VS02(keep = USUBJID HEIGHT WEIGHT); set SDTM_VS01;

by USUBJID DATE;

if first.USUBJID and first.DATE then output;

run;

*4) HbA1c test 여부 추출;
data SDTM_LB00(KEEP = USUBJID LBTEST); set SDTM.SDTM_LB; where LBTEST = 'HbA1c'; run;
proc sort data = SDTM_LB00 nodupkey out = SDTM_LB01; by USUBJID LBTEST; run;

*5) 이중맹검 여부 추출;
data SDTM_TS(keep = STUDYID TSVAL); set SDTM.SDTM_TS;
where TSVAL ='DOUBLE-BLIND';
run;


*2. 데이터 결합;
*1) 무작위 배정일, EX, VS, LB 결합(USUBJID 기준);
data ADSL00; 
attrib
EXSTDTC length = $20. 
EXENDTC length = $20. 
RANDDT length = 8. format = e8601da.
HEIGHT length = $8.
WEIGHT length = $8.
LBTEST length = $8.
EXTRT length = $8.;

if _n_ = 1 then do;

call missing(RANDDT);
call missing(EXSTDTC);
call missing(EXENDTC);
call missing(EXTRT);
call missing(HEIGHT);
call missing(WEIGHT);
call missing(LBTEST);


declare hash a1(dataset:'RANDOMIZATION');
declare hash a2(dataset:'SDTM_EX');
declare hash a3(dataset:'SDTM_VS02');
declare hash a4(dataset:'SDTM_LB01');

%macro a(a);
a&a..definekey(key:'USUBJID');
a&a..definedata(all:"yes");
a&a..definedone();
%mend a;
%a(a = 1)
%a(a = 2)
%a(a = 3)
%a(a = 4)


end;
set SDTM.sdtm_dm; 

if a1.find() = 0 and a2.find() = 0 and a3.find() = 0 and a4.find() = 0 then output;

run;

*2) 연구요약(이중맹검 여부) 결합;
data ADSL01;
attrib
TSVAL length = $20.;

if _n_ = 1 then do;

call missing(TSVAL);

declare hash a(dataset:'SDTM_TS');

a.definekey(key:'STUDYID');
a.definedata(all:'yes');
a.definedone();

end;

set ADSL00;

rc = a.find();

drop rc;

run;


*3. 데이터 정제;
data ADSL02;
set ADSL01;
attrib
ADSL_ARM format = $20.
TRT01P format = $20.
EXSTDTC_NUM format = e8601da.
EXENDTC_NUM format = e8601da.
TRTSDT format = e8601da.
TRTEDT format = e8601da.
TR01SDT format = e8601da.
TR01EDT format = e8601da.
HEIGHTBL format = 8.
WEIGHTBL format = 8.1;

EXSTDTC_NUM = input(EXSTDTC,e8601da.);
EXENDTC_NUM = input(EXENDTC,e8601da.);

if ARM = 'Treatment A 10mg' then ADSL_ARM = 'Drug A';
else ADSL_ARM = 'Placebo';

*1차 치료만 수행한 연구;
TRT01P = ADSL_ARM; 

TRTSDT = EXSTDTC_NUM;
TRTEDT = EXENDTC_NUM;
TR01SDT = EXSTDTC_NUM; 
TR01EDT = EXENDTC_NUM;

*MHDUR: 투여종료일-투여시작일;
MHDUR = intck('day',EXSTDTC_NUM,EXENDTC_NUM);

*키, 체중 숫자형으로 변경;
HEIGHTBL = input(HEIGHT,8.);
WEIGHTBL = input(WEIGHT,8.);

*AGEU: 대문자에서 첫글자만 대문자로;
AGEU1 = propcase(AGEU);

*SEXN: 1(남자:M), 2(여자:F);
if SEX = 'M' then SEXN = 1;
else SEXN = 2;

*SAFFL(Safety Population Flag) 변수 생성;
*실제 당뇨약을 진단받은 사람(EXTRT = 'DRUG A');
if EXTRT = 'DRUG A' then SAFFL = 'Y';
else SAFFL = 'N';

*FASFL(Full Analysis Set Population Flag) 변수 생성;
*무작위배정 AND 이중맹검 AND HbA1c값 존재;
if 
EXTRT in ('DRUG A' 'PLACEBO') and 
TSVAL = 'DOUBLE-BLIND' and 
LBTEST = 'HbA1c' then FASFL = 'Y';
else FASFL = 'N';

run;


%let final_var = STUDYID USUBJID SITEID ARM TRT01P RANDDT
TRTSDT TRTEDT TR01SDT TR01EDT TR01SDT TR01EDT MHDUR
HEIGHTBL WEIGHTBL AGE AGEU1 SEXN SEX SAFFL FASFL;


data ADSL03(rename = (AGEU1 = AGEU)); 
retain &final_var;
set ADSL02;
keep &final_var;
run;


data ADAM.ADAM_DM_ADSL; set ADSL03; run;

