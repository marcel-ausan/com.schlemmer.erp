select b.customer_no "Customer"
       ,substr(b.customer_name,1,20) "Name"
       ,b.customer_part_no "Customer PN"
       ,b.part_no "Part"
       ,b.part_desc "Description"
       ,case when trim(state) in ('Geliefert','Delivered') then 'deliv.not.ivcd' else
			case when trim(b.state) in ('Reserved','Picked','PickListCreated') then 'Shipping'  else
				case when upper(fnp.text) like '%NO%PPAP%' then 'No PPAP' else
					case when ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Onhand(s.CONTRACT,b.PART_NO,NULL)- ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Reserved(s.CONTRACT,b.PART_NO,NULL)- nvl(ipis_qs.quantity_Q,0)-sum_demands>=0 then 'Ord.M.Picktickets' else
						case  when trunc(create_date) > trunc(planned_ship_date) then 'Ord.M.DelDateAdjust'  else
       --case when ist eigentlich schon in "Delivered" enthalten
							case  when state like 'DOV%' then 'Forecast' else
								case when round(ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Onhand(s.CONTRACT,b.PART_NO,NULL) -ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Reserved(s.CONTRACT,b.PART_NO,NULL),0) - ipis_qs.quantity_Q < quantity and ipis_qs.quantity_Q > quantity then 'Quality' else
									case when b.type_code = 'Manufactured' then nvl(ifsapp.inventory_part_api.Get_Part_Product_Family(s.contract,b.part_no),'Missing Part family') else  
										case when pps.vendor_no ='1300087' then  'Purchased GE'  else
											case when pps.vendor_no ='1300090' then  'Purchased MX'  else 'Purchased'
											end  
										end 
									end 
								end 
							end 
						end 
					end 
				end 
			end 
		end "Classification"
         --
       ,case when trim(b.state) in ('Reserved','Picked','PickListCreated')  then 'enough stock' else
			case when ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Onhand(s.CONTRACT,b.PART_NO,NULL)=0 then 'no stock' else
				case when ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Onhand(s.CONTRACT,b.PART_NO,NULL)- ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Reserved(s.CONTRACT,b.PART_NO,NULL)- nvl(ipis_qs.quantity_Q,0)-sum_demands<0 and b.state not in ('Reserved','Picked','PickListCreated') then 'not enough stock' else 'enough stock'
				end 
			end 
		end "Stockinfo"
       ,round(nvl(b.order_value,0) ,0)  "Value"
       ,round((run_date + (1/24*s.offset)-b.planned_ship_date)/7,0) "weeks late"
       ,round(b.quantity,0) "Order qty"
       ,round(ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Onhand(s.CONTRACT,b.PART_NO,NULL),0) "Qty on hand"
       ,round(ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Reserved(s.CONTRACT,b.PART_NO,NULL),0)  "Qty reserved"
       ,nvl(ipis_qs.quantity_Q,0) "Qty Quality"
       ,round(ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Onhand(s.CONTRACT,b.PART_NO,NULL)
       -ifsapp.Inventory_Part_In_Stock_API.Get_Inventory_Qty_Reserved(s.CONTRACT,b.PART_NO,NULL),0)
       - nvl(ipis_qs.quantity_Q,0) "Qty available"
       ,sum_demands "Sum of demands in Backlog"
       ,replace(replace(replace(replace(to_char(substr(fnp.text,instr(substr(fnp.text,1,1800),'\fs20')+5)),'\par',' ') ,'\fs20',' '),'}',' '),'\lang1033',' ') "Note Availability planning"
--       ,substr(fnb.key_ref,instr(fnb.key_ref,'CONTRACT=')+9,instr(fnb.key_ref,'PART_NO=')-instr(fnb.key_ref,'CONTRACT=')-10) contract
 --      ,substr(fnb.key_ref,instr(fnb.key_ref,'PART_NO=')+8,instr(fnb.key_ref,'^PROJECT_ID=')-instr(fnb.key_ref,'PART_NO')-8) part
		,trunc(fnp.created_date+(1/24*s.offset)) "Created",fnp.created_by "By"
		,trunc(fnp.modified_date+(1/24*s.offset)) "Modified",fnp.modified_by "By"
       ,b.order_no
       ,trim(b.state) "State"
       ,b.type_code
       ,trunc(b.create_date) "created"
       ,trunc(planned_ship_date) "planned ship date"
       ,to_char(b.planned_ship_date,'YYYY/IW') "week pl.ship.date"
       ,ifsapp.inventory_part_api.Get_Part_Product_Family(s.contract,b.part_no) "Part Family"
       ,ifsapp.inventory_part_char_api.Get_Attr_Value(b.contract,b.part_no,990) "Local PN"
		,pps.vendor_no "Prim.Supplier"
		,ifsapp.supplier_info_api.Get_Name(pps.vendor_no) "Name"       
       ,b.*       
       , to_char(run_date + (1/24*s.offset),'YYYYMMDD') "run_date US"
       , run_date "run_date Time Germany"
       , offset
       ,a.*
  --     , sum(nvl(b.order_value,0)) order_value
from ifsapp.YVVDA_ORDER_STATISTIC a
		,ifsapp.YVVDA_ORDER_STAT_OPEN b
		left outer join ifsapp.fnd_note_book_tab fnb on fnb.lu_name='OrderSupplyDemand'
			and fnb.key_ref = 'CONFIGURATION_ID=*^CONTRACT=USSA^PART_NO='||trim(b.part_no)||'^PROJECT_ID=*^'
		left outer join ifsapp.fnd_note_page_tab fnp on fnb.note_id=fnp.note_id and fnp.page_no = 1
		left outer join ifsapp.purchase_part_supplier pps on pps.contract = b.contract and pps.part_no = b.part_no and pps.primary_vendor_DB='Y'
		left outer join (SELECT part_no,contract,SUM(qty_onhand) quantity_Q FROM ifsapp.INVENTORY_PART_IN_STOCK ipis where contract in ('USSA','USEL')
			AND ipis.availability_control_id IN ('QK') group by part_no,contract ) ipis_QS on ipis_qs.part_no = b.part_no and ipis_qs.contract = b.contract
-- summarized demands within choosen timeframe
		left outer join (SELECT d.statistic_no,part_no,d.contract, SUM(nvl(quantity,0)) sum_demands FROM ifsapp.YVVDA_ORDER_STAT_OPEN c,ifsapp.YVVDA_ORDER_STATISTIC d,ifsapp.site e 
									where d.contract in ('USSA','USEL')
									and c.statistic_no = d.statistic_no and e.contract= d.contract and  c.planned_ship_date < d.run_date + (1/24*e.offset)
									group by d.statistic_no,part_no,d.contract ) demands on demands.part_no = b.part_no and demands.statistic_no = b.statistic_no and demands.contract = b.contract
		,ifsapp.site s
where 1=1
		and b.planned_ship_date < run_date + (1/24*s.offset) -- condition for backlog
		--and b.planned_ship_date < run_date + (1/24*s.offset)+35 -- condition for backlog
		and a.statistic_no = b.statistic_no
		and s.contract= a.contract
		and a.statistic_no in ( select max(c.statistic_no) from   ifsapp.YVVDA_ORDER_STATISTIC c
--                          where  trunc(c.run_date)> trunc(sysdate,'MONTH') --trunc(sysdate-2) --
											where  trunc(c.run_date)  > trunc(sysdate-1)
													and c.rowstate = 'VISIBLE'                       -- neu mit IFS 7.5
													and c.user_id = 'IFSAPP'
													and c.contract in ('USSA','USEL')
													group by contract,trunc(c.run_date))
order by a.statistic_no desc,b.order_value desc
;