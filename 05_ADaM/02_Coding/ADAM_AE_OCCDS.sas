

**AE 도메인 정제;
data SDTM_AE; set SDTM.SDTM_AE; run;
data ADSL(drop = STUDYID); set ADAM.ADAM_DM_ADSL; run; 

proc sql;
create table ADAM_AE00 as
select *
from SDTM_AE as A inner join ADSL as B
on a.USUBJID = b.USUBJID;
quit;


proc freq data = ADAM_AE00; table AEDECOD; run;

*
Diarrhea: Gastrointestinal disorders

Dizziness: Nervous system disorders

Fatigue: General disorders and administration site conditions

Headache: Nervous system disorders

Insomnia: Psychiatric disorders

Nausea: Gastrointestinal disorders

Diarrhea: Gastrointestinal disorders
;


*
TRTEMFL (Treatment Emergent Flag)
치료 노출 시작(TRTSDT) 이후에 발생한 이상반응(ASTDT)인지 여부를 표시하는 플래그
Y : 치료 시작 이후 발생한 이상반응
N : 치료 전이나 치료 기간 외에 발생한 이상반응 

PREFL (Pre-treatment Flag)
이상반응이 치료 시작 전에 발생했는지를 나타내는 플래그
Y : 이상반응이 치료 시작 전에 발생
N : 분석 시 치료 전 이상반응을 구분
;

*
AOCCFL (Any Occurrence Flag)
환자별로 해당 이상반응(이상반응 용어 수준, 전체 이상반응)에 대한 발생 여부
Y : 환자가 그 이상반응을 한 번이라도 경험

;


data ADAM_AE01;
set ADAM_AE00;
attrib
ASTDT format = e8601da.
AENDT format = e8601da.
AEBODSYS format = $80.
ASTDTF format = $2.
AENDTF format = $2.
TRTEMFL format = $2.
PREFL format = $2.
AOCCFL format = $2.;


*TIMING PARAMETER 생성;
ASTDT = input(AESTDTC, e8601da.);
AENDT = input(AEENDTC, e8601da.);

*AEBODSYS 생성;
if AEDECOD = propcase('diarhea') then AEBODSYS = propcase("gastrointestinal disorders");
else if AEDECOD = propcase('dizziness') then AEBODSYS = propcase("nervous system disorders");
else if AEDECOD = propcase('fatigue') then AEBODSYS = propcase("general disorders and administration site conditions");
else if AEDECOD = propcase('headache') then AEBODSYS = propcase("nervous system disorders");
else if AEDECOD = propcase('insomnia') then AEBODSYS = propcase("psychiatric disorders");
else if AEDECOD = propcase('nausea') then AEBODSYS = propcase("gastrointestinal disorders");
else if AEDECOD = propcase('diarrhea') then AEBODSYS = propcase("gastrointestinal disorders");

*ASTDTF 생성;
if missing(ASTDT) and '01JAN1990'd > ASTDT and ASTDT > '01JAN2100'd then ASTDTF = 'N';
else ASTDTF = 'Y';

*AENDTF 생성;
if missing(AENDT) and '01JAN1990'd > AENDT and AENDT > '01JAN2100'd then AENDTF = 'N';
else AENDTF = 'Y';

*ASTDY 생성;
ASTDY = AESTDY;

*AENDY 생성;
AENDY = AEENDY;

*TRTEMFL 생성;
if intck('day',TRTSDT,ASTDT) > 0 then TRTEMFL = 'Y';
else TRTEMFL = 'N'; 

*PREFL 생성;
if ASTDY < 0 or AENDY < 0 then PREFL = 'Y';
else PREFL = 'N';

*AOCCFL 생성;
if not missing(AEDECOD) then AOCCFL = 'Y';
else AOCCFL = 'N';

*SAFFL(Safety Population Flag) 변수 생성;
*실제 당뇨약을 진단받은 사람(TRT01P = 'DRUG A');
if TRT01P = 'DRUG A' then SAFFL = 'Y';
else SAFFL = 'N';

*ASSEVN 생성;
if AESEV = 'MILD' then AESEVN = 1;
else if AESEV = 'MODERATE' then AESEVN = 2;
else if AESEV = 'SEVERE' then AESEVN = 3;

run;

%let a = 
STUDYID USUBJID SITEID AESEQ 
AEDECOD AEBODSYS TRT01P
AESTDTC ASTDT ASTDTF ASTDY AENDT AENDTF AENDY 
TRTEMFL PREFL SAFFL
AOCCFL
AESER AESEV AESEVN AEACN;



data ADAM_AE02;
retain &a.;
set ADAM_AE01;
keep &a.;
run;

proc sort data = ADAM_AE02; by USUBJID AESEQ; run;

data ADAM.ADAM_AE_OCCDS;
set ADAM_AE02;
run;
