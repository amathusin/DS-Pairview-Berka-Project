/* order */
select *,
CASE
	WHEN k_symbol = 'SIPO' THEN 'household'
	WHEN k_symbol = 'POJISTNE' THEN 'insurance'
	WHEN k_symbol = 'LEASING' THEN 'leasing'
	WHEN k_symbol = 'UVER' THEN 'loan'
END AS order_type
from [dbo].[order]

/* account */
select *
from [dbo].[account]

/* account & order */
select * 
from [dbo].[order] as a
left join [dbo].[account] as b
on a.account_id = b.account_id

/* trans */
select *,
CASE
	WHEN k_symbol = 'SIPO' THEN 'household payment'
	WHEN k_symbol = 'POJISTNE' THEN 'insurance payment'
	WHEN k_symbol = 'SLUZBY' THEN 'statement payment'
	WHEN k_symbol = 'UROK' THEN 'interest credited'
	WHEN k_symbol = 'SANKC. UROK' THEN 'interest debited'
	WHEN k_symbol = 'DUCHOD' THEN 'pension credited'
	WHEN k_symbol = 'UVER' THEN 'loan payment'
END AS trans_type
from [dbo].[trans]


/* loan */
select * from [dbo].[loan]

/* client */
select client_id, 99 - LEFT([birth_number], 2) as age, /* based on date of last transaction 1998-12-31 */
CASE
	WHEN RIGHT([birth_number], 4) >= 1300 THEN 'F'
	WHEN RIGHT([birth_number], 4) < 1300 THEN 'M'
END AS gender
from [dbo].[client]

/* card */
select * from [dbo].[card]

/* disp */
select * from [dbo].[disp]

/* client, disposition, account, transactions */
select t.trans_id, t.account_id, t.amount, t.balance, c.client_id,
CASE 
	WHEN t.type = 'PRIJEM' THEN 'credit'
	WHEN t.type = 'VYDAJ' THEN 'withdrawal'
END AS type
from [dbo].[trans] as t
left join [dbo].[account] as a
on t.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id

/* total income & total spending & net balance*/
WITH income (amount, client_id)
AS(
select sum(amount) amount, c.client_id
from [dbo].[trans] as t
left join [dbo].[account] as a
on t.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id
GROUP BY c.client_id, t.type
having t.type = 'PRIJEM')

, spending (amount, client_id)
as(
select sum(amount) amount, c.client_id
from [dbo].[trans] as t
left join [dbo].[account] as a
on t.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id
GROUP BY c.client_id, t.type
having t.type = 'VYDAJ')

select *, i.amount - s.amount as net_bal
from income as i
left join spending as s
on i.client_id = s.client_id
order by i.amount - s.amount desc

/* average balance after each transaction */
select c.client_id, AVG(t.balance)/count(t.trans_id) average_bal, MAX(t.date) max_date
from [dbo].[trans] as t
left join [dbo].[account] as a
on t.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id
GROUP BY c.client_id
ORDER BY AVG(t.balance)/count(t.trans_id) desc

/* client, disposition, account, loan */
select l.loan_id, c.client_id, l.status, l.duration, l.date
from [dbo].[loan] as l
left join [dbo].[account] as a
on l.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id


/* client, disposition, account, order */
select c.client_id, o.order_id, o.amount,
CASE 
	WHEN o.k_symbol = 'POJISTNE' THEN 'insurance payment'
	WHEN o.k_symbol = 'SIPO' THEN 'household payment'
	WHEN o.k_symbol = 'LEASING' THEN 'leasing'
	WHEN o.k_symbol = 'UVER' THEN 'loan payment'
END AS type
from [dbo].[order] as o
left join [dbo].[account] as a
on o.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id


/* disposition, client, credit card */
select cr.card_id, c.client_id, cr.type, cr.issued
from [dbo].[card] as cr
left join [dbo].[disp] as d
on cr.disp_id = d.disp_id
left join [dbo].[client] as c
on c.client_id = d.client_id

/* client, district */
select c.client_id, distr.A2 as district, distr.A3 as region, distr.A4 as population, distr.A9 as no_cities, distr.A10 as ratio_urban, 
distr.A11 as avg_sal, distr.A12 as unemp_95, distr.A13 as unemp_96, distr.A14 as no_enterp, 
distr.A15 as no_crimes95, distr.A16 as no_crimes96
from [dbo].[district] as distr
left join [dbo].[client] as c
on c.district_id = distr.A1

select * from [dbo].[district]

/* total income */
select c.client_id, sum(amount) income, min(t.date) min_date, max(t.date) max_date
from [dbo].[trans] as t
left join [dbo].[account] as a
on t.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id
GROUP BY c.client_id, t.type
having t.type = 'PRIJEM'


/* total spending */
select c.client_id, avg(amount) spending, min(t.date) min_date, max(t.date) max_date
from [dbo].[trans] as t
left join [dbo].[account] as a
on t.account_id = a.account_id
left join [dbo].[disp] as d
on d.account_id = a.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id
GROUP BY c.client_id, t.type
having t.type = 'VYDAJ'

/* account group by client */
select c.client_id, min(a.date) date
from [dbo].[account] as a
left join [dbo].[disp] as d
on a.account_id = d.account_id
left join [dbo].[client] as c
on c.client_id = d.client_id
group by c.client_id