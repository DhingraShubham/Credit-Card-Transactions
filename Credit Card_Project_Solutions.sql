-- 1) How many customers have done transactions over 49000.

select count(distinct cust_id) as Customers
from transaction_base tb
join card_base cb on tb.credit_card_id = cb.card_number
where transaction_value > 49000;


-- 2) Identify the range of credit limit of customer who have done fraudulent transactions.

select concat(min(cb.credit_limit), ' - ', max(cb.credit_limit)) as Credit_Range
from fraud_base fb
join transaction_base tb on fb.transaction_id = tb.transaction_id
join card_base cb on tb.credit_card_id = cb.card_number;


-- 3) What is the average age of customers who are involved in fraud transactions based on different card type.

select cb.card_family, round(avg(csb.age),2) as Avg_age_of_customers
from fraud_base fb
join transaction_base tb on fb.transaction_id = tb.transaction_id
join card_base cb on tb.credit_card_id = cb.card_number
join customer_base csb on cb.cust_id = csb.cust_id
group by cb.card_family;


-- 4) Identify the month when highest no of fraudulent transactions occured.

select month(transaction_date) as month ,count(*) as max_fraud_trans
from fraud_base fb
join transaction_base tb on tb.transaction_id = fb.transaction_id
group by month(transaction_date)
order by max_fraud_trans desc
limit 1;


-- 5) Identify the customer who has done the most transaction value without involving in any fraudulent transactions.

select cb.cust_id as Customer, sum(tb.Transaction_Value) as Total_sum
from transaction_base tb
left join fraud_base fb on tb.transaction_id = fb.transaction_id
join card_base cb on tb.credit_card_id = cb.card_number 
where cb.cust_id not in ( select cust_id
                          from card_base cb
                          join transaction_base tb on cb.Card_Number = tb.Credit_Card_ID
                          join fraud_base fb on tb.Transaction_ID = fb.Transaction_ID)
group by cb.Cust_ID
order by total_sum desc
limit 1;


-- 6) Check and return any customers who have not done a single transaction.

select csb.cust_id as Customers
from customer_base csb
left join card_base cb on csb.cust_id = cb.cust_id
where cb.card_number is null;

-- OR

select distinct cust_id as Customers
from customer_base csb 
where csb.cust_id not in (select distinct cb.cust_id
			  from Transaction_base tb
			  join Card_base cb on tb.credit_card_id = cb.card_number);


-- 7) What is the highest and lowest credit limit given to each card type.

select card_family, min(credit_limit) as Min_limit, max(credit_limit) as Max_limit
from card_base
group by card_family ;


-- 8) What is the total value of transactions done by customers who come under the age bracket of 20-30 yrs, 30-40 yrs, 40-50 yrs, 50+ yrs and 0-20 yrs.

with cte as 
        ( select csb.age,tb.transaction_value 
          from customer_base csb
          join card_base cb on cb.cust_id = csb.cust_id
          join transaction_base tb on cb.card_number = tb.credit_card_id),
     age_group as 
       ( select case when (age<= 20) then '0-20'
                     when (age > 20 and age <= 30) then '20-30'
                     when (age > 30 and age <= 40) then '30-40'
                     when (age > 40 and age <= 50) then '40-50'
                     else '50+' end as Age_group,
                     transaction_value
		 from cte)
select age_group, sum(transaction_value) as Total_Sum_Value
from age_group 
group by age_group 
order by age_group;

-- OR

select sum(case when (age <= 20) then transaction_value else 0 end) as 'Age Group 0-20',
       sum(case when (age>20 and age <= 30) then transaction_value else 0 end) as 'Age Group 20-30',
       sum(case when (age>30 and age <= 40) then transaction_value else 0 end) as 'Age Group 30-40',
       sum(case when (age>40 and age <= 50) then transaction_value else 0 end) as 'Age Group 40-50',
       sum(case when (age>50) then transaction_value else 0 end) as 'Age Group 50+'
from customer_base csb
join card_base cb on csb.cust_id = cb.cust_id
join transaction_base tb on cb.card_number = tb.credit_card_id ;


-- 9) Excluding fraudulent transactions, Which card type has done the most no of transactions and the total highest value of transactions.

select * 
from ( select card_family, count(1) as Trans
       from transaction_base tb
       join card_base cb on tb.credit_card_id = cb.card_number
       where transaction_id not in (select transaction_id from fraud_base)
	   group by card_family
       order by trans desc
	   limit 1) x
union all
select * 
from ( select card_family, sum(transaction_value) as Total
       from transaction_base tb
       join card_base cb on tb.credit_card_id = cb.card_number
       where transaction_id not in (select transaction_id from fraud_base)
       group by card_family
       order by total desc
       limit 1) y;

