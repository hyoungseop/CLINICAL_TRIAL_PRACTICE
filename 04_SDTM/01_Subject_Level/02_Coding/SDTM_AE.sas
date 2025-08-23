
*SDTM AE ������ ������ SDTM 3.1.2VER ���̵������ ���� ����;

**DM �����ο��� AE ������ ������ �ʿ��� ID(TRIAL_ID, USER_ID, STUDY_ID), ������������(STUDY_START_DATE) �ҷ�����;
***�����������ڴ� ����������(STUDY_START_DATE)�� ����;
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

*DM DOMAIN�� ��Ī �� Ű���� AE�� ���� ��� �α� ���;
if _iorc_ = %sysrc(_dsenom) then do;
put "AE�����ΰ� DM������ �� ID ����ġ";
end;

*1. DOMAIN ����;
DOMAIN = 'AE';

*2. ID ����;
**1) STUDYID ����;
STUDYID = TRIAL_ID;
**2) SUBJID ����;
SUBJID = USER_ID;
**3) USUBJID ����;
USUBJID = CATX('-',TRIAL_ID,SITEID,USER_ID);

*3. �̻���� ������, ������ ����(������e8601da);
AESTDTC = put(input(tranwrd(AE_START_DATE,"/","-"),e8601da.),e8601da.);
AEENDTC = put(input(tranwrd(AE_END_DATE,"/","-"),e8601da.),e8601da.);

*4. �̻���� ���� ������ ���� �̻���� ������ ��¥ ������ ���� �߰�;
AESTDT = input(tranwrd(AE_START_DATE,"/","-"),e8601da.);

run;


*ID �� �̻���� ���� ������ ���� ����;
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

*5. id�� �̻���� ���� ����;
if first.USUBJID then AESEQ = 1;
else AESEQ + 1;

*6. AETERM ����;
**ȯ�ڳ� �����ڰ� ������ ���� �� ����;
**�� CRF�� ���� ���� VERBATIM�� ���� + ȯ�ڷκ����� ���� ����;
**AE_VERBATIM ������ ù��° ���ڿ� ���;
AETERM = scan(AE_VERBATIM,1);

*7. AEDECOD ����;
AEDECOD = scan(AE_VERBATIM,1);

*8. AESEV ����;
AESEV = upcase(AE_SEVERITY);

*9. AESER ����;
*�Ʒ� ���� �� �ϳ��� ���ϸ� AESER�� �����ϳ�,
 CRF ���� �� �Ʒ��� ���ؿ� �����ϴ� ��� AE_SERIOUS��
 �з��Ͽ��ٰ� �����Ͽ� ������ ����
	AESDTH = "Y": ����� �ʷ�
	AESLIFE = "Y": ������ ����
	AESHOSP = "Y": �Կ��� ���ϰų� �Կ��Ⱓ ����
	AESDISAB = "Y": �������̰ų� �ߴ��� ���/���ɷ� �ʷ�
	AESCONG = "Y": ��õ�� �̻�/�������
	AESMIE = "Y": ��Ÿ ���������� �߿��� �ɰ��� ���
	AESCAN = "Y": �ϰ� ����
;
AESER = AE_SERIOUS;

*10. AEACN(�̻���� �� ��ġ) ����;
**No action taken -> NOT APPLICABLE : SDTM IG �����Ͽ� ����;
if AE_ACTION_TAKEN = 'No action taken' then 
AEACN = 'NOT APPLICABLE';
else AEACN = upcase(AE_ACTION_TAKEN);

*11. AESTDY, AEENDY ����;
**�̻��� �߻����ڿ� �������ڸ� ���� �����Ϸκ��� ����� �ϼ��� ���;
**����
AESTDY = (AESTDT ? RFSTDTC) + 1
AEENDY = (AEENDT ? RFSTDTC) + 1
;
AESTDY = (input(AESTDTC,e8601da.) - input(tranwrd(STUDY_START_DATE,"/","-"),e8601da.)) + 1;
AEENDY = (input(AEENDTC,e8601da.) - input(tranwrd(STUDY_START_DATE,"/","-"),e8601da.)) + 1;

run;

*12. SDTM_AE ���� ����;
data SDTM.SDTM_AE;
retain STUDYID DOMAIN USUBJID AESEQ AETERM AESTDTC AEENDTC
AEDECOD AESEV AESER AEACN AESTDY AEENDY;
set AE01;
keep STUDYID DOMAIN USUBJID AESEQ AETERM AESTDTC AEENDTC
AEDECOD AESEV AESER AEACN AESTDY AEENDY;
run;