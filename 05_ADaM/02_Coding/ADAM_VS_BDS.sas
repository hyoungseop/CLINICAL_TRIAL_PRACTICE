
**ADaMIG_v1.3 참고;


/*
데이터 구조		 주요 용도
BDS				 파라미터별 연속 측정값 분석, 투여 전후 기준값 및 변화량 계산
ADFEV			 사건(event) 타임라인 분석, 발생 시점별 특성 및 값 기록
ADFEVAUC		 PK 농도–시간 곡선 아래 면적(AUC) 계산, 약동학 노출 평가
*/

data SDTM_VS; set SDTM.SDTM_VS; run;
data ADSL(keep = STUDYID TRTSDT index = (STUDYID)); set ADAM.ADAM_DM_ADSL; run; *투여 시작일 결합;

data ADAM_VS00;

set SDTM_VS;
set ADSL key = STUDYID/unique;

if _iorc_ = %sysrc(_dsenom) then do;
call missing(of _all_);
put "error";
end;

run;


proc sql;
select distinct VSTESTCD
from ADAM_VS00;
quit;

*
DIABP
HEIGHT
PULSE
SYSBP
WEIGHT
;

data ADAM_VS01;

set ADAM_VS00;
attrib
PARAMCD format = $30.
PARAMN format = 2.
ADT format = e8601da.
;


PARAMCD = VSTESTCD;

if PARAMCD = 'DIABP' then do; PARAM = 'Diastolic Blood Pressure (mm Hg)'; PARAMN = 1; end;
else if PARAMCD = 'SYSBP' then do; PARAM = 'Systolic Blood Pressure (mm Hg)'; PARAMN = 2; end;
else if PARAMCD = 'HEIGHT' then do; PARAM = 'Height (cm)'; PARAMN = 3; end;
else if PARAMCD = 'WEIGHT' then do; PARAM = 'Weight (kg)'; PARAMN = 4; end;
else do; PARAM = 'Pulse (BPM)'; PARAMN = 5; end;

ADT = input(VSDTC, e8601da.); *ADT = VS 진단일;

ADY = intck('day',TRTSDT,ADT) + 1;

*ADY가 음수면 SAFRFL은 결측 처리;
if ADY >= 1 then SAFRFL = 'Y';
else SAFRFL = '';

run;


proc sort data = ADAM_VS01; by USUBJID; run;

data ADSL_1(index = (USUBJID)); set ADAM.ADAM_DM_ADSL; run;

data ADAM_VS02; 
set ADAM_VS01;
set ADSL_1 key = USUBJID/unique; 

if _iorc_ = %sysrc(_dsenom) then do;
call missing(of _all_);
put "확인 필요";
end;
run;


%let a = STUDYID USUBJID PARAM PARAMCD PARAMN ADT ADY SITEID AGE AGEU SEX SAFFL FASFL;

data ADAM.ADAM_VS_BDS;
retain &a;
set ADAM_VS02(keep = &a);
run;

