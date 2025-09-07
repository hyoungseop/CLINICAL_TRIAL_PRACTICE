

*1. TEMPLATE;
data ADAM_TEMPLATE00; set SDTM.SDTM_EX; 

attrib
EXSTDT format = e8601da.
EXENDT format = e8601da.;

EXSTDT = input(EXSTDTC,e8601da.);
EXENDT = input(EXENDTC,e8601da.);

if not missing(EXSTDT) and not missing(EXENDT) then DUR = intck("day",EXSTDT,EXENDT) + 1;

*EXOCCUR변수 생성;
if not missing(EXSTDTC) and not missing(EXDOSE) then EXOCCUR = 'Y';
else EXOCCUR = 'N';

run;

*생성 파라미터 매크로;
%let a = STUDYID USUBJID PARAMCD AVAL;

*2. TRTDURD; *약물 투여 기간;
data ADAM_TRTDURD00; set ADAM_TEMPLATE00(where = (EXOCCUR = 'Y')); 
attrib
PARAMCD format = $20.;

PARAMCD = 'TRTDURD';
AVAL = DUR;

keep &a.;

run;


*3. NADMIN; *실제 약물 투여 횟수;
proc sql;
create table ADAM_NADMIN00 as
select STUDYID, USUBJID, count(USUBJID) as SUM_EX
from ADAM_TEMPLATE00
where EXOCCUR = 'Y'
group by USUBJID;
quit;


data ADAM_NADMIN01; set ADAM_NADMIN00;
attrib
PARAMCD format = $20.;

AVAL = SUM_EX;
PARAMCD = 'NADMIN';

keep &a.;

run;


*4. TOTPLDOS; *계획된 총 투여 용량;
data ADAM_TOTPLDOS00; set ADAM_TEMPLATE00(where = (EXOCCUR = 'Y'));
attrib
PARAMCD format = $20.;

AVAL = 10;
PARAMCD = 'TOTPLDOS';

keep &a.;
run;


*5. TOTACDOS; * 실제 총 투여 용량;
proc sql;
create table ADAM_TOTACDOS00 as
select STUDYID, USUBJID, sum(EXDOSE) as SUM_DOSE
from ADAM_TEMPLATE00
where EXOCCUR = 'Y'
group by USUBJID;
quit;


data ADAM_TOTACDOS01; set ADAM_TOTACDOS00;
attrib
PARAMCD format = $20.;

AVAL = SUM_DOSE;

PARAMCD = 'TOTACDOS';

keep &a.;

run;



*6. RDOSINT;
proc sort data = ADAM_TOTPLDOS00; by STUDYID USUBJID; run;
proc sort data = ADAM_TOTACDOS01; by STUDYID USUBJID; run;


data ADAM_RDOSINT00;
merge 
ADAM_TOTPLDOS00(keep = STUDYID USUBJID AVAL rename = (AVAL = AVAL_PLAN))
ADAM_TOTACDOS01(keep = STUDYID USUBJID AVAL rename = (AVAL = AVAL_ACTUAL));

by STUDYID USUBJID;

run;

data ADAM_RDOSINT01;
set ADAM_RDOSINT00;
attrib
PARAMCD format = $20.;

PARAMCD = 'RDOSINT';

if not missing(AVAL_PLAN) and not missing(AVAL_ACTUAL) then AVAL = round((AVAL_ACTUAL/AVAL_PLAN)*100,0.01);

keep &a.;

run;


*7. 결합;
data ADAM_EX00;
set 
ADAM_TRTDURD00(in = a1)
ADAM_NADMIN01(in = a2)
ADAM_TOTPLDOS00(in = a3)
ADAM_TOTACDOS01(in = a4)
ADAM_RDOSINT01(in = a5);

length PARAM $200.;

if a1 then do; PARAMN = 1; PARAM = "Treatment Duration in days"; end;
if a2 then do; PARAMN = 2; PARAM = "Nr of Actual Study Drug Administrations"; end;
if a3 then do; PARAMN = 3; PARAM = "Total Planned Dose (mg)"; end;
if a4 then do; PARAMN = 4; PARAM = "Total Actual Dose (mg)"; end;
if a5 then do; PARAMN = 5; PARAM = "Relative Dose Intensity (%)"; end;

run;


proc freq data = ADAM_EX00; table PARAMCD -- PARAMN; run;

proc sort data = ADAM_EX00; by STUDYID SUSBJID PARAMN; run;

%let variables = STUDYID USUBJID PARAM PARAMCD PARAMN AVAL;

data ADAM_EX_ADEXSUM;

retain &variables.;

set ADAM_EX00;

keep &variables.;

run;

data ADAM.ADAM_EX_ADEXSUM;
set ADAM_EX_ADEXSUM;
run;