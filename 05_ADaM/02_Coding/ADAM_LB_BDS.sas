
**ADaMIG_v1.3 참고;


data SDTM_LB; set SDTM.SDTM_LB; run;
data ADSL(keep = USUBJID SITEID FASFL); set ADAM.ADAM_DM_ADSL; run; *SITEID가 누락되어 결합;
data SDTM_EX(keep = USUBJID EXTRT); set SDTM.SDTM_EX; run; *투여 시작일 결합;

*데이터 결합;
*LB, ADSL, EX;
data ADLB00;

length SITEID $8. EXTRT $10. FASFL $2.;

if _n_ = 1 then do;

call missing(SITEID);
call missing(EXTRT);
call missing(FASFL);

declare hash a1(dataset:'ADSL');
declare hash a2(dataset:'SDTM_EX');

%macro a(a);
&a..definekey(key:"USUBJID");
&a..definedata(all:"yes");
&a..definedone();
%mend a;
%a(a = a1)
%a(a = a2)

end;

set SDTM_LB;

if a1.find() = 0 and a2.find() = 0 then output;


run;


data ADLB01;

set ADLB00;
attrib
PARAMCD format = $10.
PARAM format = $20.
ADT format = e8601da.;

PARAMCD = LBTESTCD;
PARAM = LBTEST;

ADT = input(LBDTC, e8601da.);

AVAL = LBSTRESC;

if EXTRT = 'DRUG A' then SAFFL = 'Y';
else SAFFL = 'N';

run;

proc sort data = ADLB01; by USUBJID LBTEST ADT; run;

data ADLB02;

set ADLB01;

attrib
AVISIT format = $20.
SAFFL format = $2.;

retain BASE;

by USUBJID LBTEST ADT;

if first.USUBJID or first.LBTEST then do; AVISIT = 'Baseline'; BASE = AVAL; end;
else do; AVISIT = 'End of Treatment'; BASE = BASE; end;

CHG = AVAL - BASE; 


run;

%let a = STUDYID USUBJID PARAMCD PARAM AVISIT ADT AVAL BASE CHG SAFFL FASFL;

data ADAM.ADAM_LB_BDS;
retain &a.;
set ADLB02;
keep &a.;
run;


