


  CREATE OR REPLACE FORCE VIEW "IFSAPP"."SCG_CURRENCY_RATE_COBA_EUR" ("CURRENCY", "EXCHANGE_RATE", "EXCHANGE_RATE_DATE") AS 
  select currency                   as CURRENCY
       , TO_NUMBER(mittelkurs, '99999.9999999')                       as EXCHANGE_RATE
       ,  TO_DATE(kursdatum, 'DD.MM.YY')                      as EXCHANGE_RATE_DATE
	from   SCG_IMPORT_COBA_CURRENCY_TAB@BIDBNEU
	where  1 = 1
	with read only;
;
