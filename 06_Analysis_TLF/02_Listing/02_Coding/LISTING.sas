
%macro aa(aa);
%if %index(&aa.,adam) %then %do;
data &aa.; set adam.&aa.; run;
%end;

%else %if %index(&aa.,sdtm) %then %do;
data &aa.; set sdtm.&aa.; run;
%end;

proc sql noprint; select name into: &&aa._var separated by " " from dictionary.columns 
where libname = upcase('work') and memname = upcase("&aa."); quit;

%put &&&aa._var;

ods pdf file="/home/a010489956630/sap에서제출까지/ANALSYS/output/&&aa..pdf";
options orientation=landscape; /*결과 출력: 가로*/

proc report data = &aa. nowd;
title "DIAA-2025-001";
columns &&&aa._var;
%macro a;
%do i = 1 %to %sysfunc(countw(&&&aa._var));
%let x = %scan(&&&aa._var,&i);
define &x./display;
%end;
%mend a;
%a
%if %index(&aa., adam) %then %do;
%if %index(&aa.,ae) %then %do; footnote "AE = ADVERSE EVENT OCCDS"; %end;
%else %if %index(&aa.,dm) %then %do; footnote "DM = DEMOGRAPHY ADSL"; %end;
%else %if %index(&aa.,ex) %then %do; footnote "EX = EXPOSURE ADEXSUM"; %end;
%else %if %index(&aa.,lb) %then %do; footnote "LB = LABORATORY BDS"; %end;
%else %if %index(&aa.,vs) %then %do; footnote "VS = VITAL SIGN BDS"; %end;
%end;

%else %if %index(&aa., sdtm) %then %do;
%if %index(&aa., ae) %then %do; footnote "AE = ADVERSE EVENT SDTM"; %end;
%else %if %index(&aa., dm) %then %do; footnote "DM = DEMOGRAPHY SDTM"; %end;
%else %if %index(&aa., ex) %then %do; footnote "EX = EXPOSURE SDTM"; %end;
%else %if %index(&aa., lb) %then %do; footnote "LB = LABORATORY SDTM"; %end;
%else %if %index(&aa., ta) %then %do; footnote "TA = TRIAL ARMS SDTM"; %end;
%else %if %index(&aa., te) %then %do; footnote "TE = TRIAL ELEMENTS SDTM"; %end;
%else %if %index(&aa., ts) %then %do; footnote "TS = TRIAL SUMMARY SDTM"; %end;
%else %if %index(&aa., vs) %then %do; footnote "VS = VITAL SIGN SDTM"; %end;
%end;
run;
ods pdf close;

%mend aa;
%aa(aa = adam_ae_occds)
%aa(aa = adam_dm_adsl)
%aa(aa = adam_ex_adexsum)
%aa(aa = adam_lb_bds)
%aa(aa = adam_vs_bds)

%aa(aa = sdtm_ae)
%aa(aa = sdtm_dm)
%aa(aa = sdtm_ex)
%aa(aa = sdtm_lb)
%aa(aa = sdtm_ta)
%aa(aa = sdtm_te)
%aa(aa = sdtm_ts)
%aa(aa = sdtm_vs)

