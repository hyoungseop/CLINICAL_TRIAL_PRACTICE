
*TE 프로토콜 -> SDTM TE;
*SDTM IG Version 3.1.3 참고;

proc transpose data = proto.protocol_ta out = TA00;
id TA_VARIABLES;
var TA_EXAMPLE;
run;


data PLACEBO DRUG; set TA00;

format DOMAIN $2.;

*1. 도메인 생성;
DOMAIN = 'TA';

run;

*ELEMENT VS EPOCH;
*ELEMENT : 각 ARM 내에서 수행되는 세부 절차 단계;
*EPOCH : 연구 전반에 걸친 큰 시간 구분;

*TABRANCH : 해당 ELEMENT 종료 시 어디로 분기할지 EX) 스크리닝 종료 후 무작위배정 분기;
*TATRANS : 순차적이지 않은 ELEMENT 간 직접 이동 정의 EX) 비반응자는 건너뛰기;

%macro a(a);
data &a.1(KEEP = STUDYID DOMAIN ARMCD ARM TAETORD ETCD ELEMENT TABRANCH TATRANS EPOCH); 

retain STUDYID DOMAIN ARMCD ARM TAETORD ETCD ELEMENT TABRANCH TATRANS EPOCH;

set &a.;

attrib
ARMCD format = $2.
ARM format = $10.
TAETORD format = 2.
ETCD format = $8.
ELEMENT format = $10.
TABRANCH format = $40.
TATRANS format = $10.
EPOCH format = $10.
;

*2. 각 ELEMENT별 변수 생성;
if index(ARMCD,"&a.") then do;
%if &a. = PLACEBO %then %do;
ARMCD = 'P'; ARM = 'Placebo'; TAETORD = 1; ETCD = 'SCRN'; ELEMENT = 'Screen';
TABRANCH = ''; TATRANS = ''; EPOCH = 'Screen'; output; 
ARMCD = 'P'; ARM = 'Placebo'; TAETORD = 2; ETCD = 'RI'; ELEMENT = 'Run-In';
TABRANCH = 'Randomized to Placebo'; TATRANS = '';  EPOCH = 'Run-In'; output; 
ARMCD = 'P'; ARM = 'Placebo'; TAETORD = 3; ETCD = 'P'; ELEMENT = 'Placebo';
TABRANCH = ''; TATRANS = '';  EPOCH = 'Treatment'; output; 
%end;

%else %do;
ARMCD = 'A'; ARM = 'A'; TAETORD = 1; ETCD = 'SCRN'; ELEMENT = 'Screen';
TABRANCH = ''; TATRANS = ''; EPOCH = 'Screen'; output; 
ARMCD = 'A'; ARM = 'A'; TAETORD = 2; ETCD = 'RI'; ELEMENT = 'Run-In';
TABRANCH = 'Randomized to Drug A'; TATRANS = '';  EPOCH = 'Run-In'; output; 
ARMCD = 'A'; ARM = 'A'; TAETORD = 3; ETCD = 'P'; ELEMENT = 'Placebo';
TABRANCH = ''; TATRANS = '';  EPOCH = 'Treatment'; output; 
%end;

end;

run;
%mend a;
%a(a = PLACEBO)
%a(a = DRUG)

data SDTM.SDTM_TA; set PLACEBO1 DRUG1; run;

