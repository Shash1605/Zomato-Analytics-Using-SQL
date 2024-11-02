CREATE DATABASE Zomato;
use zomato;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 
desc goldusers_signup;
INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-11-04');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-09-11',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-11-03',2),
(1,'2016-11-03',1),
(3,'2016-10-11',1),
(3,'2017-07-12',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-10-09',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

## 1. What is the total amount each customer spent on zomato ?

select a.userid,sum(b.price)Total_price 
from sales as a inner join product as b
on
a.product_id = b.product_id
group by a.userid;

## 2. How many days has each customer visited zomato ?

select userid, count(distinct created_date)Days 
from sales
group by userid;

## 3. What was the first product purchased by each customer ?

select * from(
select *,rank() over(partition by userid order by created_date) rnk from sales) a
where rnk = 1;

## 4. What is the most purchased item and how many times was it purchased by all customers ?

select * from sales;

select userid,count(product_id) cnt from sales where product_id = 
(select product_id from sales group by 1 order by count(product_id) desc limit 1)
group by userid;

## 5. Which item was the most popular for each customer ?

select * from
(select *,rank() over(partition by userid order by cnt desc)rnk from
(select userid,product_id,count(product_id) cnt from sales
group by userid,product_id)a)b
where rnk = 1;

## 6. Which item was purchased first by the customer after they became a member ?

select * from (
select *,rank() over(partition by userid order by created_date) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales as a inner join goldusers_signup as b
on
a.userid = b.userid and created_date > gold_signup_date)a
)b
where rnk = 1;

## 7. Which item was purchased just before the customer became a member ?

select * from goldusers_signup;

select * from (
select *,rank() over(partition by userid order by created_date desc) rnk from
(select a.userid,a.product_id,a.created_date,b.gold_signup_date 
from sales as a join goldusers_signup as b
on a.userid = b.userid and created_date < gold_signup_date
group by 1,2,3,4) a) b
where rnk = 1; 

## 8. What is the total orders and amount spent for each member before they became a member ?

select userid,count(created_date),sum(price) from
(select c.*,d.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date 
from sales as a join goldusers_signup as b
on
a.userid = b.userid and a.created_date <= b.gold_signup_date)c
join product as d
on
c.product_id = d.product_id)e
group by userid;

## 9. If buying each product generates for eg 5rs = 2 zomato point and each product has different purchasing points
##    for eg for p1 5rs = 1 zomato point, p2 10rs = 5 zomato point and p3 5rs = 1 zomato point
##  Calculate points collected by each customers and for which product most points have been given till now

select * from sales;
select * from product;

select *,rank() over(order by Total_money_earned) from 
(select product_id,sum(total_points) Total_money_earned from
(select e.*,amt/points as total_points from
(select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from
(select c.userid,c.product_id,sum(c.price)amt from
(select a.*, b.price 
from sales as a join product as b
on a.product_id = b.product_id)c
group by 1,2)d)e
order by userid,product_id)f
group by product_id)g;

## 10 In the first one year after a customer joins the gold program (including their join date) irrespective of
##    what the customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3
##    and what was their points earnings in their first year ? ## 1 Zp = 2 rs
select * from goldusers_signup;

select c.*,d.price*0.5 Total_Points_Earned from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a join goldusers_signup as b
on a.userid = b.userid and created_date >= gold_signup_date and created_date <= DATE_ADD(gold_signup_date, INTERVAL 1 YEAR))c
join product as d on c.product_id = d.product_id;

## 11. Rank all the transaction of the customers

select *,rank() over(partition by userid order by created_date) rnk from sales;

## 12. Rank all the transactions for each member whenever they are a zomato gold member for every non-gold
##     mark as na

select e.*,case when rnk=0 then 'na' else rnk end as rnkk from
(select c.*,case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end as rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales as a left join
goldusers_signup as b on a.userid = b.userid and created_date >= gold_signup_date)c)e;










