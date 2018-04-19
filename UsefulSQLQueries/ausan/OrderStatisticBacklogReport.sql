
-- from BIDB
SELECT FACT_ORDER_STATISTIC_OPEN.CONTRACT as c1,
  case FACT_ORDER_STATISTIC_OPEN.CONTRACT
    when 'USSA' then 'SUS01'
    else 'TBD'
  end as levelkey,
  FACT_ORDER_STATISTIC_OPEN.STATISTIC_NO as STATISTIC_NOkey,
  case when (FACT_ORDER_STATISTIC_OPEN.ROWSTATE in ('Delivered','Geliefert')) then '2 - Non Operational' else '1 - Operational Backlog' end as level0key,
  FACT_ORDER_STATISTIC_OPEN.TYPE_CODE as TYPE_CODEkey,
  FACT_ORDER_STATISTIC_OPEN.ROWSTATE as ROWSTATEkey,
  FACT_ORDER_STATISTIC_OPEN.REPORTING_DATE as REPORTING_DATEkey,
  case when (DIM_LAST_WORKING_DAYS.LAST_WD_PAST > 5) then 'before'
    else ((((to_char(FACT_ORDER_STATISTIC_OPEN.PLANNED_SHIP_DATE,'YYYY') || '-') || to_char(FACT_ORDER_STATISTIC_OPEN.PLANNED_SHIP_DATE,'MM')) || '-') || to_char(FACT_ORDER_STATISTIC_OPEN.PLANNED_SHIP_DATE,'DD'))
    end as level1key,
  case 
      case 
        when (DIM_LAST_WORKING_DAYS.LAST_WD_PAST > 5) then 'before'
        else ((((to_char(FACT_ORDER_STATISTIC_OPEN.PLANNED_SHIP_DATE,'YYYY') || '-') || to_char(FACT_ORDER_STATISTIC_OPEN.PLANNED_SHIP_DATE,'MM')) || '-') || to_char(FACT_ORDER_STATISTIC_OPEN.PLANNED_SHIP_DATE,'DD'))
      end
    when 'before' then 1
    else 2
  end as c9,
  FACT_ORDER_STATISTIC_OPEN.ORDER_VALUE as ORDER_VALUE
FROM  SCHLEMMER.FACT_ORDER_STATISTIC_OPEN FACT_ORDER_STATISTIC_OPEN, SCHLEMMER.DIM_LAST_WORKING_DAYS DIM_LAST_WORKING_DAYS, SCHLEMMER.DIM_KALENDER DIM_CALENDAR
WHERE 1=1 
  AND (DIM_LAST_WORKING_DAYS.TAG_KZ = 0) 
  AND (FACT_ORDER_STATISTIC_OPEN.REPORTING_DATE = ((((to_char((sysdate - 1),'YYYY') || '-') || to_char((sysdate -1),'MM')) || '-') || to_char((sysdate -1),'DD'))) 
  AND ( FACT_ORDER_STATISTIC_OPEN.CONTRACT in ('USSA')) 
  AND (
    not 
        (
          (
            (
              (
                FACT_ORDER_STATISTIC_OPEN.ROWSTATE = 'Released'
              ) 
              and 
              (
                FACT_ORDER_STATISTIC_OPEN."STATE" like 'DOV%'
              )
            ) 
            and 
            (
              FACT_ORDER_STATISTIC_OPEN.STATE_ORDER_SCHED like 'DOV%'
            )
          ) 
          or 
          (
            (
              (
                FACT_ORDER_STATISTIC_OPEN.ROWSTATE = 'Delivered'
              ) 
              and 
              (
                FACT_ORDER_STATISTIC_OPEN."STATE" = 'Geliefert'
              )
            ) 
            and 
            (
              FACT_ORDER_STATISTIC_OPEN.STATE_ORDER_SCHED = 'Geliefert'
            )
          )
        )
      ) 
  AND (FACT_ORDER_STATISTIC_OPEN.PLANNED_SHIP_DATE_KEY = DIM_CALENDAR.ZEITRAUM_TAG_YYYYMMDD) 
  AND (DIM_LAST_WORKING_DAYS.TAG = DIM_CALENDAR.TAG)
ORDER BY FACT_ORDER_STATISTIC_OPEN.STATISTIC_NO desc, FACT_ORDER_STATISTIC_OPEN.ORDER_VALUE desc
;

