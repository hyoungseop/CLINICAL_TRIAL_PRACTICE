
*TE 프로토콜 -> SDTM TE;
*SDTM IG Version 3.1.3 참고;

proc transpose data = proto.protocol_te out = TE00;
id TE_VARIABLES;
var TE_EXAMPLE;
run;


data SDTM.SDTM_TE(keep = STUDYID DOMAIN ETCD ELEMENT TESTRL TEENRL TEDUR);

retain STUDYID DOMAIN ETCD ELEMENT TESTRL TEENRL TEDUR;

set TE00;

attrib
DOMAIN format = $2.
ETCD format = $8.
ELEMENT format = $10.
TESTRL format = $40.
TEENRL format = $40.
TEDUR format = $8.;

*1. 도메인 생성;
DOMAIN = 'TE';

*2. 각 element 별 변수 생성;
if index(ELEMCD,'SCREEN') ne 1 then do; 
ETCD = 'SCRN'; ELEMENT = 'Screen'; TESTRL = 'Informed consent'; 
TEENRL = '1 week after start of Element'; TEDUR = 'P7D'; output; end;

if index(ELEMCD,'PLACEBO') then do; 
ETCD = 'P'; ELEMENT = 'Placebo'; TESTRL = 'First dose of study drug, where drug is placebo'; 
TEENRL = '2 weeks after start of Element'; TEDUR = 'P14D'; output; end;

if index(ELEMCD,'DRUG A') then do; 
ETCD = 'A'; ELEMENT = 'Drug A'; TESTRL = 'First dose of study drug, where drug is Drug A'; 
TEENRL = '2 weeks after start of Element'; TEDUR = 'P14D'; output; end;


run;

