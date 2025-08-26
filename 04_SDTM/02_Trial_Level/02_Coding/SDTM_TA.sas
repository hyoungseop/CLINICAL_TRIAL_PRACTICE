
*TE �������� -> SDTM TE;
*SDTM IG Version 3.1.3 ����;

proc transpose data = proto.protocol_ta out = TA00;
id TA_VARIABLES;
var TA_EXAMPLE;
run;


data PLACEBO DRUG; set TA00;

format DOMAIN $2.;

*1. ������ ����;
DOMAIN = 'TA';

run;

*ELEMENT VS EPOCH;
*ELEMENT : �� ARM ������ ����Ǵ� ���� ���� �ܰ�;
*EPOCH : ���� ���ݿ� ��ģ ū �ð� ����;

*TABRANCH : �ش� ELEMENT ���� �� ���� �б����� EX) ��ũ���� ���� �� ���������� �б�;
*TATRANS : ���������� ���� ELEMENT �� ���� �̵� ���� EX) ������ڴ� �ǳʶٱ�;

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

*2. �� ELEMENT�� ���� ����;
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

