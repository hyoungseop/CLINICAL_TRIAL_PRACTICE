
option minoperator;

data null; run;

data DM(index = (USUBJID) keep = USUBJID TRT01P SEXN AGE); set ADAM.ADAM_DM_ADSL; run;

data LB; 
set ADAM.ADAM_LB_BDS;
set DM key = USUBJID/unique;

PCHG = (((AVAL - BASE)/BASE)*100);

run;

%let a = USUBJID SEXN TRT01P AGE PARAMCD AVAL BASE CHG PCHG AVISIT FASFL;

data LB1;
retain USUBJID SEXN TRT01P AGE FASFL;
merge 
LB(keep = &a.  where = (PARAMCD = 'GLUCOSE' and AVISIT = 'End of Treatment')
rename = (aval = glu_aval base = glu_base chg = glu_chg pchg = glu_pchg))
LB(keep = &a.  where = (PARAMCD = 'HbA1c' and AVISIT = 'End of Treatment')
rename = (aval = hb_aval base = hb_base chg = hb_chg pchg = hb_pchg));

if 19 <= age <= 40 then age_g = 1;
else if 40 < age < 64 then age_g = 2;
else age_g = 8;

drop paramcd avisit;
RUN;

proc freq data = lb1; table age_G; run;

***전체***;
*1. 혈당, HBA1C 전후 비교;
proc sort data = LB1; by TRT01P; run;

**N이 100이라서 SHAPIRO-WILK TEST 채용**;
*WILCOXON SIGNED-RANK TEST 수행;
ods trace on;
%macro a(a,b);
proc univariate data = LB1 normal cibasic;
where FASFL = 'Y';
%if &b. = 1 %then %do; by TRT01P; %end;
%else %do; %end;
var &a.;
histogram &a. / normal;
qqplot &a. / normal(mu = est sigma = est);
ods output moments = moment_&a.&b.;
ods output BasicIntervals = interval_&a.&b.;
ods output TestsForLocation = signed_&a.&b.;
run;
%mend a;
%a(a = glu_chg, b = 1) 
/*DRUG A -- SHAPIRO: 0.0003, signed-rank test: < 0.0001*/
/*PLACEBO -- SHAPIRO: 0.0203, signed-rank test: < 0.0039*/
%a(a = hb_chg, b = 1) 
/*DRUG A -- SHAPIRO: 0.0008, signed-rank test: < 0.0001*/
/*PLACEBO -- SHAPIRO: 0.0008, signed-rank test: < 0.0039*/

%a(a = glu_chg, b = 0) 
/*total -- SHAPIRO: <0.0001, signed-rank test: < 0.0001*/

%a(a = hb_chg, b = 0) 
/*total -- SHAPIRO: <0.0001, signed-rank test: < 0.0001*/

/****DRUG A, PLACEBO 약 투여 전후 혈당, 헤모글로빈 a1c이 유의미하게 차이가 있었음(감소)****/

%macro aa(aa);
proc transpose data = moment_&aa. out = moment_&aa._1(keep = trt01p n mean 'std deviation'n);
by trt01p;
id label1;
var cvalue1;
run;


data interval_&aa._1(keep = trt01p estimate lowercl uppercl); set interval_&aa.;
where parameter = 'Mean';
run;

data signed_&aa._1(keep = trt01p pvalue); set signed_&aa.;
where testlab = 'S';
run;


data &aa.;
length trt01p $20.;

if _n_ = 1 then do;

call missing(estimate);
call missing(lowercl);
call missing(uppercl);
call missing(pvalue);

declare hash a1(dataset:"interval_&aa._1");
declare hash a2(dataset:"signed_&aa._1");

%macro a(a);
a&a..definekey(key:"trt01p");
a&a..definedata(all:"yes");
a&a..definedone();
%mend a;
%a(a = 1)
%a(a = 2)

end;

set moment_&aa._1;

if a1.find() = 0 and a2.find() = 0 then output;

run;



data &aa._1(keep = 'Treatment Group'n n 'Mean Change(SD)'n '95% CI'n 'p-value'n);
retain 'Treatment Group'n n 'Mean Change(SD)'n '95% CI'n 'p-value'n;
set &aa.(rename = (pvalue ='p-value'n trt01p = 'Treatment Group'n));

format 'p-value'n pvalue6.4;

'Mean Change(SD)'n = catt(strip(put(round(input(mean,8.2),0.01),8.2)),"(",strip(put(round(input('std deviation'n,8.2),0.01),8.2)),")");

'95% CI'n = catt(strip(put(round(input(lowercl,8.1),0.1),8.1)),"~",strip(put(round(input(uppercl,8.1),0.1),8.1)));

run;

%mend aa;
%aa(aa = glu_chg1)
%aa(aa = hb_chg1)



%macro aa(aa);
proc transpose data = moment_&aa. out = moment_&aa._1(keep = n mean 'std deviation'n);
id label1;
var cvalue1;
run;


data interval_&aa._1(keep = estimate lowercl uppercl); set interval_&aa.;
where parameter = 'Mean';
run;

data signed_&aa._1(keep = pvalue); set signed_&aa.;
where testlab = 'S';
run;

data &aa.(keep = 'Treatment Group'n n 'Mean Change(SD)'n '95% CI'n 'p-value'n);
retain 'Treatment Group'n n 'Mean Change(SD)'n '95% CI'n 'p-value'n;
merge moment_&aa._1 interval_&aa._1 signed_&aa._1(rename = (pvalue ='p-value'n));

format 'p-value'n pvalue6.4;

'Treatment Group'n = 'Difference (Active - Placebo)';

'Mean Change(SD)'n = catt(strip(put(round(input(mean,8.2),0.01),8.2)),"(",strip(put(round(input('std deviation'n,8.2),0.01),8.2)),")");

'95% CI'n = catt(strip(put(round(input(lowercl,8.1),0.1),8.1)),"~",strip(put(round(input(uppercl,8.1),0.1),8.1)));

run;

%mend aa;
%aa(aa = glu_chg0)
%aa(aa = hb_chg0)

data output1;
format 'Treatment Group'n $50.;
set null(in = a) glu_chg1_1 glu_chg0 null(in = b) hb_chg1_1 hb_chg0; 

if a then 'Treatment Group'n = 'Glucose';
if b then 'Treatment Group'n = 'HbA1c';

run; 


*2. 약물 투여 후 혈당, HBA1C 비교;
%macro a(a);
proc univariate data = LB1 normal;
where FASFL = 'Y';
by TRT01P;
var &a.;
histogram &a. / normal;
qqplot &a. / normal(mu = est sigma = est);
run;
%mend a;
%a(a = glu_aval) /*SHAPIRO: 0.5866*/
%a(a = hb_aval) /*SHAPIRO: 0.2656*/

*TTEST 채택;
proc ttest data = LB1;
class TRT01P;
var glu_aval hb_aval;
ods output Statistics = a;
ods output ttests = b;
ods output Equality = c(rename = (method = vari_method));
run;
*GLU_AVAL: FOLDED F 0.1073 POOLED 0.5455;
*HB_AVAL: FOLDED F 0.9170 POOLED 0.3487;

/****DRUG A, PLACEBO 약 투여 후 혈당이 차이가 없었음****/

data ttest_output;

length vari_method $20. variances $20.;

if _n_ = 1 then do;

call missing(variances);
call missing(tvalue);
call missing(df);
call missing(probt);
call missing(vari_method);
call missing(numdf);
call missing(dendf);
call missing(fvalue);
call missing(probf);


declare hash a1(dataset:'b');
declare hash a2(dataset:'c');

a1.definekey(key:'variable', 'method');
a1.definedata(all:'yes');
a1.definedone();

a2.definekey(key:'variable');
a2.definedata(all:"yes");
a2.definedone();

end;

set a;

rc1 = a1.find();
rc2 = a2.find();


drop rc1 rc2;
run;

data ttest_output1;
set ttest_output;

if probf > 0.0005 then do;
if variances = propcase('unequal') then delete;
end;

keep probt variable -- maximum;
run;


data ttest_output2(keep = variable class 'mean(sd)'n 'diff(95% ci)'n 'p-value'n);
set ttest_output1;

format 'P-value'n pvalue6.4;

if missing(method) then 'Mean(SD)'n = strip(put(mean,7.1))||"("||strip(put(stddev,7.1))||")";

else do;
'diff(95% CI)'n = strip(put(mean,7.1))||"("||strip(put(lowerclmean,7.1))||","||strip(put(upperclmean,7.1))||")";
'P-value'n = probt;
end;

run;

data ttest_output3(keep = 'Treatment Group'n 'Drug A Mean(SD)'n 'Placebo Mean(SD)'n 'diff(95% CI)'n 'P-value'n);
retain variable 'Drug A Mean(SD)'n 'Placebo Mean(SD)'n 'diff(95% CI)'n 'P-value'n;
merge
ttest_output2(where = (class = 'Drug A') keep = variable class 'mean(sd)'n rename = ('mean(sd)'n = 'Drug A Mean(SD)'n))
ttest_output2(where = (class = 'Placebo') keep = variable class 'mean(sd)'n rename = ('mean(sd)'n = 'Placebo Mean(SD)'n))
ttest_output2(where = (class = 'Diff (1-2)') keep = variable class 'diff(95% CI)'n 'P-value'n);

if variable = 'glu_aval' then variable = 'Glucose';
else if variable = 'hb_aval' then variable = 'HbA1c';

rename variable = 'Treatment Group'n;
run;

data output.signed_rank_test(label = '위약과 당뇨약 각각 투여 전 후 혈당, hba1c 비교'); set output1; run;
data output.ttest(label = '위약과 당뇨약 투여 후 혈당, hba1c 비교'); set ttest_output3; run;




