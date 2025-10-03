
option validvarname = any;
option validmemname = extend;

data DM(index = (USUBJID) keep = USUBJID TRT01P SEXN AGE); set ADAM.ADAM_DM_ADSL; run;

data LB; 
set ADAM.ADAM_LB_BDS;
set DM key = USUBJID/unique;

PCHG = (((AVAL - BASE)/BASE)*100);

run;


%macro a(a);
proc means data = LB;
where paramcd = "&a.";
class trt01p avisit;
var aval;
ods output summary = LB_AVG;
run;

%if &a. = GLUCOSE %then %do;
ods pdf file="/home/a010489956630/sap에서제출까지/ANALSYS/output/Before and after treatment comparison of blood glucose.pdf";
%end;

%else %do;
ods pdf file="/home/a010489956630/sap에서제출까지/ANALSYS/output/Before and after treatment comparison of hba1c.pdf";
%end;

*복용 전후 혈당, 당화혈색소 비교;
*그룹간 평균 혈당, 당화혈색소 값을 먼저 구한 뒤 sgplot series에 값을 넣어야 함;
proc sgplot data = LB_AVG;
%if &a. = GLUCOSE %then %do; title "Before and after treatment comparison of blood glucose"; %end;
%else %do; title "Before and after treatment comparison of hba1c"; %end;
series x = avisit y = aval_mean/group = trt01p;
xaxis label = "drug administration";
yaxis label = "&a.";
refline 0 / axis = y lineattrs=(color = red pattern = dash);
run;
ods pdf close;

*복용 후 그룹 간 혈당, 당화혈색소 비교;
%if &a. = GLUCOSE %then %do;
ods pdf file="/home/a010489956630/sap에서제출까지/ANALSYS/output/after treatment comparison of blood glucose.pdf";
%end;

%else %do;
ods pdf file="/home/a010489956630/sap에서제출까지/ANALSYS/output/after treatment comparison of hba1c.pdf";
%end;
proc sgplot data = LB;
%if &a. = GLUCOSE %then %do; title "after treatment comparison of blood glucose"; %end;
%else %do; title "after treatment comparison of hba1c"; %end;
where paramcd = "&a.";
vbar trt01p / response = aval stat = mean datalabel group = trt01p;
xaxis label = "drug administration";
yaxis label = "after drug administration &a.";
run;
ods pdf close;
%mend a;
%a(a = GLUCOSE)
%a(a = HbA1c)

*참고;
*title에서 font = 'Arial Unicode MS' 를 지정해야 한글이 안깨짐;

* vbar 옵션
group=group_variable: 그룹별 막대를 다른 색상으로 나누어 표현
groupdisplay=cluster: 그룹에 따라 막대를 옆으로 나란히 클러스터로 표시
groupdisplay=stack: 그룹별 막대를 쌓아 올림 (stacked bar)
;