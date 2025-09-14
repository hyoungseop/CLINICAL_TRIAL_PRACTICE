
proc format;
value age_group
low -< 30 = '<30'
30 -< 40 = '30-40'
40 -< 50 = '40-50'
50 -< 60 = '50-60'
60 - high = '>60';
run;


/*포맷 전부 삭제
proc catalog catalog=work.formats kill;
quit;
*/

data null; run;

data ADSL; set ADAM.ADAM_DM_ADSL;
if age < 30 then age_g = 1;
else if age < 40 then age_g = 2;
else if age < 50 then age_g = 3;
else if age < 60 then age_g = 4;
else age_g = 5;

bmi = weightbl/(heightbl/100)**2;
run;


%let drop = _TYPE_ _PAGE_ _TABLE_;

*1. age table;
proc tabulate data = ADSL out = AGE_TABLE;
where FASFL = 'Y';
class trt01p;
var age;
table 
trt01p * (n pctn)
trt01p * age * (median p25 p75)
trt01p * age * (mean std)
trt01p * age * (min max);
run;


data AGE_TABLE1(keep = "Age, Years"n VARNAME 'Median (Q1, Q3)'n 'Mean (SD)'n 'Min - Max'n); 
format Characteristic $40.;
set AGE_TABLE(drop = &drop.);
"Age, Years"n = '';

VARNAME = strip(TRT01P)|| ' '||"N = "||strip(put(N,2.));
'Median (Q1, Q3)'n = strip(put(AGE_MEDIAN,4.1))||" ("||strip(put(AGE_P25,4.1))||", "||strip(put(AGE_P75,4.1)||")");
'Mean (SD)'n = strip(put(AGE_MEAN,7.1))||" ("||strip(put(AGE_STD,7.2))||")";
'Min - Max'n = strip(put(AGE_MIN,4.1))||" - "||strip(put(AGE_MAX,4.1));

run;


proc transpose data = AGE_TABLE1 out = AGE_TABLE2(rename = (_NAME_ = Characteristic));
id VARNAME;
VAR "Age, Years"n 'Median (Q1, Q3)'n 'Mean (SD)'n 'Min - Max'n;
run;


*2. age_g table;
proc tabulate data = ADSL out = AGE_G_TABLE;
where FASFL = 'Y';
class trt01p age_g/ order = formatted;
table 
age_g ,trt01p * (n colpctn);
run;

*
쉼표(,) : 세로로
별표(*) : 가로로
;

proc sort data = AGE_G_TABLE; by trt01p age_g; run;

data AGE_G_TABLE1; 
set AGE_G_TABLE(drop = &drop.);

retain tot_n;

by trt01p age_g;

if first.trt01p then tot_n = n;
else tot_n + n;

if last.trt01p then call symputx(catt('obs_',compress(lowcase(trt01p))),tot_n);

age_n_percent = strip(put(n,4.))||" ("||strip(put(pctn_10,6.1))||"%)";

run;

data AGE_G_TABLE2;
set AGE_G_TABLE1;
format varname $20.;
%macro a(a);
if lowcase(compress(trt01p)) = "&a." then VARNAME = strip(TRT01P)|| ' '||"N = "||strip(&&obs_&a.);
%mend a;
%a(a = druga)
%a(a = placebo)

run;


data AGE_G_TABLE3(keep = Characteristic "Drug A N = 90"n "Placebo N = 10"n);
format Characteristic $40.;
retain Characteristic "Drug A N = 90"n "Placebo N = 10"n;
set null AGE_G_TABLE2(rename = (AGE_N_PERCENT = "Drug A N = 90"n) where = (VARNAME = "Drug A N = 90"));
set null AGE_G_TABLE2(rename = (AGE_N_PERCENT = "Placebo N = 10"n) where = (VARNAME = "Placebo N = 10"));

if _n_ = 1 then Characteristic = "Age Group, n (%)";

if age_g = 1 then Characteristic = "<30";
else if age_g = 2 then Characteristic = "30-40";
else if age_g = 3 then Characteristic = "40-50";
else if age_g = 4 then Characteristic = "50-60";
else if age_g = 5 then Characteristic = ">60";

run;


*3. sex table;
proc tabulate data = ADSL out = SEX_TABLE;
where FASFL = 'Y';
class trt01p sexn/ order = data;
table 
trt01p, sexn * (n rowpctn);
run;


data SEX_TABLE1;
set SEX_TABLE;
AGE_N_PERCENT = strip(put(N,4.))||" ("||strip(put(PCTN_10,6.1))||"%)";
run;


data SEX_TABLE2(keep = Characteristic "Drug A N = 90"n "Placebo N = 10"n);
format Characteristic $40.;
retain Characteristic "Drug A N = 90"n "Placebo N = 10"n;
set null SEX_TABLE1(rename = (AGE_N_PERCENT = "Drug A N = 90"n) where = (TRT01P = 'Drug A'));
set null SEX_TABLE1(rename = (AGE_N_PERCENT = "Placebo N = 10"n) where = (TRT01P = 'Placebo'));

if _n_ = 1 then Characteristic = 'Sex, n (%)';

if SEXn = 1 then Characteristic = 'Male';
else if SEXn = 2 then Characteristic = 'Female';

run;


*4. weight, height, bmi ,mhdur table;
proc tabulate data = ADSL out = WHBM_TABLE;
where FASFL = 'Y';
class trt01p / order = data;
var weightbl heightbl bmi mhdur;
table
trt01p * (weightbl heightbl bmi mhdur) * (n pctn)
trt01p * (weightbl heightbl bmi mhdur) * (median p25 p75)
trt01p * (weightbl heightbl bmi mhdur) * (mean std)
trt01p * (weightbl heightbl bmi mhdur) * (min max);
run;


data WHBM_TABLE1; set 
%macro a(a);
WHBM_TABLE(keep = trt01p &a.: rename = 
(&a._n = n &a._pctn_0_&a. = pct
 &a._median = median &a._p25 = p25 &a._p75 = p75
 &a._mean = mean &a._std = std
 &a._min = min &a._max = max)
 in = &a.)
%mend a;
%a(a = weightbl)
%a(a = heightbl)
%a(a = bmi)
%a(a = mhdur)
;
format group $20.;

if weightbl then group = 'weight';
if heightbl then group = 'height';
if bmi then group = 'bmi';
if mhdur then group = 'mhdur';


VARNAME = strip(TRT01P)|| ' '||"N = "||strip(put(N,2.));
'Median (Q1, Q3)'n = strip(put(MEDIAN,4.1))||" ("||strip(put(P25,4.1))||", "||strip(put(P75,4.1)||")");
'Mean (SD)'n = strip(put(MEAN,7.1))||" ("||strip(put(STD,7.2))||")";
'Min - Max'n = strip(put(MIN,4.1))||" - "||strip(put(MAX,4.1));

run;

proc sort data = WHBM_TABLE1; by group; run;

proc transpose data = WHBM_TABLE1 out = WHBM_TABLE2(rename = (_NAME_ = Characteristic));
by group;
id VARNAME;
VAR n 'Median (Q1, Q3)'n 'Mean (SD)'n 'Min - Max'n;
run;

data WHBM_TABLE3(drop = group); 
format Characteristic $40.;
set 
null(in = a1)
WHBM_TABLE2(where = (group = 'weight'))
null(in = a2)
WHBM_TABLE2(where = (group = 'height'))
null(in = a3)
WHBM_TABLE2(where = (group = 'bmi'))
null(in = a4)
WHBM_TABLE2(where = (group = 'mhdur'));

if a1 then Characteristic = 'Baseline Weight (kg)';
if a2 then Characteristic = 'Baseline Height (cm)';
if a3 then Characteristic = 'Baseline BMI (kg/m^2)';
if a4 then Characteristic = 'Duration of Disease (Month)';

run;


data OUTPUT.DM_FINAL;
format Characteristic $40.;
set
AGE_TABLE2
AGE_G_TABLE3
SEX_TABLE2
WHBM_TABLE3;
run;

