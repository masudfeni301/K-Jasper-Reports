=====================================CF_OFFDAY_REASON================================

function CF_OFFDAY_REASONFormula return Char is
P VARCHAR2(150);
begin
  SELECT '  '||OCCASION 
  INTO P
	FROM HOLIDAY 
	WHERE 
	COMPANY_CODE = :P_COMPANY_CODE AND
	COMPANY_BRANCH_CODE  = :P_COMPANY_BRANCH_CODE AND
	FROM_DATE = :ATTEND_DATE;
	RETURN P;
EXCEPTION
	WHEN OTHERS THEN 
	RETURN (NULL);
end;
=================================CF_OFFDAY_ALL=============================================
function CF_OFFDAY_ALLFormula return Number is
P NUMBER(10,2);
Q number;
begin
	SELECT NVL(OFFDAY_ALL,0) OFFDAY_ALL
	INTO P
	FROM HR_TNOFF_ALLOWANCE
	WHERE 
	DEPT_GROUP  = :DEPT_GROUP AND
  DEPT_CODE   =  :DEPT_CODE  AND
  DESIG_CODE  = :DESIG_CODE AND
  EFFECTIVE_DATE  = (SELECT MAX(EFFECTIVE_DATE) 
                     FROM HR_TNOFF_ALLOWANCE 
                     WHERE DEPT_GROUP = :DEPT_GROUP AND
                     DEPT_CODE        = :DEPT_CODE  AND
                     DESIG_CODE      = :DESIG_CODE AND
                     EFFECTIVE_DATE  <= TO_DATE(:P_MNYR,'MM/YYYY'));
  
  SELECT COUNT(EMP_ID) INTO Q
        FROM HR_OFFDAY_ADJUST
        WHERE 
        COMPANY_CODE=:P_COMPANY_CODE AND
        COMPANY_BRANCH_CODE=:P_COMPANY_BRANCH_CODE AND
        EMP_ID = :EMP_ID AND
        ADJ_DATE = :ATTEND_DATE AND
        OFFDAY_ADJUST ='C' AND
        INIT_YR(TO_CHAR(ADJ_DATE,'MM/YYYY')) =  INIT_YR(:P_MNYR);
    IF Q > 0 THEN
    	return null;
    ELSE
    return P;
    END IF;  
EXCEPTION
	WHEN OTHERS THEN 
	RETURN (NULL);  
end;

----------------------------------------Not Use------------------------------------------------
=================================CF_EMP_STAY_TIME=============================================
function CF_EMP_STAY_TIMEFormula return Number is
P NUMBER(10);
BEGIN
	SELECT ROUND(24*(OUT_TIME-IN_TIME))TOTAL_TIME 
	INTO P
  FROM DAILY_ATTENDANCE
  WHERE 
  COMPANY_CODE        =:P_COMPANY_CODE AND
  COMPANY_BRANCH_CODE =:P_COMPANY_BRANCH_CODE AND
  ATTEND_DATE         =:ATTEND_DATE AND
  EMP_ID              =:EMP_ID;
  RETURN P;
EXCEPTION
	WHEN OTHERS THEN 
	RETURN (NULL);  
END;
----------------------------------------Not Use------------------------------------------------

=================================CF_EM_STAY_TIME=============================================
function CF_EM_STAY_TIMEFormula return Number is
P NUMBER(10,2);
begin
  IF :OUT_TIME>:IN_TIME THEN 
  P:= 24*(:OUT_TIME-:IN_TIME);
  END IF;
  IF :IN_TIME > :OUT_TIME  THEN 
  P:= 24*(:IN_TIME-:OUT_TIME);
  END IF;
  IF :OUT_TIME IS NULL  THEN 
  P:= 1;
  END IF;
  RETURN P;	 
  
end;

----------------------------------------Not Use------------------------------------------------
=======================================CF_ACTUAL_TIME===========================================
function CF_ACTUAL_TIMEFormula return Number is
P NUMBER(10,2);
begin
	P:=ROUND(NVL(:CF_EM_STAY_TIME,0),2);
  RETURN P;
end;
----------------------------------------Not Use------------------------------------------------

==========================================CF_LUNCH_AMT========================================
function CF_LUNCH_AMTFormula return Number is
P NUMBER(10,2);
begin
	SELECT NVL(OFFDAY_LUNCH_BILL,0) OFFDAY_ALL
  INTO P
  FROM HR_TNOFF_ALLOWANCE
  WHERE 
  DEPT_GROUP  = :DEPT_GROUP AND
  DEPT_CODE   =  :DEPT_CODE  AND
  DESIG_CODE  = :DESIG_CODE AND
  EFFECTIVE_DATE  = (SELECT MAX(EFFECTIVE_DATE) 
                     FROM HR_TNOFF_ALLOWANCE 
                     WHERE DEPT_GROUP = :DEPT_GROUP AND
                     DEPT_CODE        = :DEPT_CODE  AND
                     DESIG_CODE      = :DESIG_CODE AND
                     EFFECTIVE_DATE  <= TO_DATE(:P_MNYR,'MM/YYYY'));
  RETURN P;
EXCEPTION
    WHEN OTHERS THEN 
    RETURN (NULL);
end;
==========================================CF_LUN_DIN_PAY_AMT========================================

function CF_LUN_DIN_PAY_AMTFormula return Char is
P VARCHAR2(100);
Q NUMBER;
begin
	IF :OUT_TIME1 IS NOT NULL AND :OUT_TIME1>= TO_CHAR(TO_DATE('1400','HH24:MI'),'HH24:MI')  AND :OUT_TIME1< TO_CHAR(TO_DATE('23:00','HH24:MI'),'HH24:MI') OR
 :DUTY >04 
	 THEN 
      P :=:CF_LUNCH_AMT;
  ELSE
  	SELECT COUNT(EMP_ID) INTO Q
        FROM HR_OFFDAY_ADJUST
        WHERE 
        COMPANY_CODE=:P_COMPANY_CODE AND
        COMPANY_BRANCH_CODE=:P_COMPANY_BRANCH_CODE AND
        EMP_ID = :EMP_ID AND
        ADJ_DATE = :ATTEND_DATE AND
        LUNCH_ADJUST ='A' AND
        INIT_YR(TO_CHAR(ADJ_DATE,'MM/YYYY')) =  INIT_YR(:P_MNYR);
    IF Q > 0 THEN
    	P :=:CF_LUNCH_AMT;
    ELSE
    	P :=NULL;
    END IF;  
  END IF;
  RETURN P;
end;

----------------------------------------Not Use------------------------------------------------
==========================================CF_LUN_DIN_AMT========================================
function CF_LUN_DIN_AMTFormula return Number is
begin
  RETURN (TO_NUMBER(NVL(:CF_LUN_DIN_PAY_AMT,0)));  
end;
----------------------------------------Not Use------------------------------------------------

=====================================CF_PAYABLE_AMT================================
function CF_PAYABLE_AMTFormula return Number is
P NUMBER(10);
Q NUMBER;
begin
	IF :CF_ACTUAL_TIME>= 4 THEN 
		P:= ROUND((:CF_OFFDAY_ALL*:CS_ATT_DT_COUNT));
	ELSE
		P:= :CF_OFFDAY_ALL;     
	END IF;
	RETURN P;
end;

==========================================CF_TOT_PAY_AMT========================================
function CF_TOT_PAY_AMTFormula return Number is
begin
  RETURN (NVL(:CF_LUN_DIN_AMT,0)+NVL(:CF_PAYABLE_AMT,0));
end;

======================================CF_NET_PAYABLE_CASH========================================
function CF_NET_PAYABLE_CASHFormula return Number is
P NUMBER(15,2);
begin

		
	IF :EMP_AC_NO IS NOT NULL AND :BANK_SAL_FLAG IS NOT NULL 
	AND  :MOBILE_AC_NO IS NOT NULL AND :MOBILE_BANK_SAL_FLAG IS NOT NULL THEN
		P:=:CF_TOT_PAY_AMT;
	ELSIF
	   :EMP_AC_NO IS NULL AND :BANK_SAL_FLAG IS NULL AND :MOBILE_AC_NO IS NULL AND :MOBILE_BANK_SAL_FLAG IS NULL THEN
		P:=:CF_TOT_PAY_AMT;
	ELSE 
		P:=NULL;
	END IF ;
	RETURN P;  
end;
==========================================CF_IN_TIME========================================
function CF_IN_TIMEFormula return Char is
x varchar2(10);
y number;
begin
 select count(attend_date) into y
 from daily_attendance
 where emp_id = :emp_id
 and to_char(attend_date, 'MM/YYYY') = :P_MNYR
 and attend_date = (select adj_date from HR_OFFDAY_ADJUST where emp_id = :emp_id and to_char(adj_date, 'MM/YYYY') = :P_MNYR and adj_date = :attend_date );
 
 if y > 0 then
 	 select to_char(in_time, 'HH24:MI') into x
   from daily_attendance
   where emp_id = :emp_id
   and to_char(attend_date, 'MM/YYYY') = :P_MNYR
   and attend_date = :attend_date;
 else 
 	return :in_time1;
 end if;
 return x;
 exception
 	when no_data_found then
 	return :in_time1; 
end;
==========================================CF_OUT_TIME========================================
function CF_OUT_TIMEFormula return Char is
x varchar2(10);
y number;
begin
 select count(attend_date) into y
 from daily_attendance
 where emp_id = :emp_id
 and to_char(attend_date, 'MM/YYYY') = :P_MNYR
 and attend_date = (select adj_date from HR_OFFDAY_ADJUST where emp_id = :emp_id and to_char(adj_date, 'MM/YYYY') = :P_MNYR and adj_date = :attend_date );
 
 if y > 0 then
 	 select to_char(out_time, 'HH24:MI') into x
   from daily_attendance
   where emp_id = :emp_id
   and to_char(attend_date, 'MM/YYYY') = :P_MNYR
   and attend_date = :attend_date;
 else 
 	return :out_time1; 
 end if;
 return x;
 exception
 	when no_data_found then
 	return :out_time1; 
end;


==========================================CF_NET_PAYABLE_BANK========================================
function CF_NET_PAYABLE_BANKFormula return Number is
P NUMBER(15,2);
begin
	IF  :EMP_AC_NO IS NOT NULL AND :BANK_SAL_FLAG IS NOT NULL 
	OR  :MOBILE_AC_NO IS NOT NULL AND :MOBILE_BANK_SAL_FLAG IS NOT NULL THEN
		P:=:CF_TOT_PAY_AMT;
	ELSE 
		P:=0;
	END IF ;
	RETURN P;  
end;

