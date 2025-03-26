drop database if exists rentals;
create database rentals;
use rentals;



create function date_in_range (start date, end date, _date date)
returns bool
deterministic
return (start <= _date and _date <= end);

create function date_overlap (start_1 date, end_1 date, start_2 date, end_2 date)
returns bool
deterministic
return
    (date_in_range(start_1, end_1, start_2) or date_in_range(start_1, end_1, end_2));

create table person (
    id int auto_increment,
    first_name varchar(30),
    middle_name varchar(30),
    last_name varchar(30),
    full_name varchar(90) as (concat_ws(' ', first_name, middle_name, last_name)),
    -- max length of phone number according to ITU-T E.164
    phone bigint check (phone <= 999999999999999 and phone >= 0) not null,
    -- length according to https://www.rfc-editor.org/rfc/rfc5321.txt
    email_local varchar(64),
    email_domain varchar(255),
    email varchar(320) as (concat(email_local, '@', email_domain)),
    primary key (id)
);

create table guarantor (
    id int,
    ord tinyint not null,
    guarantor int not null,
    primary key (id, ord),
    foreign key (id) references person(id),
    foreign key (guarantor) references person(id)
);

create table building (
    id int auto_increment,
    manager int,
    addr varchar(100) not null,
    name varchar(50),
    description varchar(1000),
    primary key (id),
    foreign key (manager) references person(id)
);

create table apartment (
    building int,
    num varchar(4),
    type varchar(30),
    description varchar(1000),
    primary key (building, num),
    foreign key (building) references building(id)
);

create table lease_type (
    id tinyint auto_increment,
    name varchar(30) not null,
    days_per_term smallint not null,
    primary key (id)
);
insert into lease_type (name, days_per_term) values
('long term', 365),
('fixed term', 30),
('short term', 1);

create table lease (
    building int,
    apartment varchar(4),
    start_date date,
    lease_type tinyint not null,
    minimum_term smallint not null,
    rent_per_term int not null,
    primary key (building, apartment, start_date),
    foreign key (building, apartment) references apartment(building, num),
    foreign key (lease_type) references lease_type(id)
);

create table tenant (
    building int,
    apartment varchar(4),
    start_date date,
    ord tinyint,
    tenant int not null,
    primary key (building, apartment, start_date, ord),
    foreign key (building, apartment, start_date) references lease(building, apartment, start_date),
    foreign key (tenant) references person(id)
);


delimiter $
create trigger date_overlap before insert on lease for each row
begin
    declare days int;

    select days_per_term into days from lease_type where new.lease_type = id;

    if exists (
        select true from lease l, lease_type t
        where l.lease_type = t.id
        and l.building = new.building
        and l.apartment = new.apartment
        and date_overlap(
            new.start_date,
            date_add(new.start_date, interval new.minimum_term * days day),
            l.start_date,
            date_add(l.start_date, interval l.minimum_term * t.days_per_term day)
        ) limit 1
    ) then
        signal sqlstate value '23000' set message_text = 'The date of the input lease overlaps with existing lease(s) of the same apartment.';
    end if;
end $
delimiter ;


-- Task 2
INSERT INTO person (first_name, middle_name, last_name, phone, email_local, email_domain) VALUES
('John', 'A.', 'Doe', 4034567890, 'john_doe', 'hotmail.com'),
('Jane', 'B.', 'Smith', 5875678901, 'janes123', 'gmail.com'),
('Alice', NULL, 'Johnson', 4036789012, 'alice.johnson', 'yahoo.com'),
('Bob', 'C.', 'Brown', 4037890123, 'bob.brown23', 'gmail.com'),
('Charlie', NULL, 'Davis', 5878901234, 'charlie_davis', 'hotmail.com'),
('Eva', 'D.', 'Wilson', 5879012345, 'eva.w75', 'hotmail.com'),
('Frank', NULL, 'Moore', 4030123456, 'frank_moore', 'yahoo.com'),
('Grace', 'E.', 'Taylor', 5871234567, 'grace.taylor', 'gmail.com'),
('Henry', NULL, 'Anderson', 4032345678, 'henry.anderson1', 'hotmail.com'),
('Ivy', 'F.', 'Thomas', 4034567890, 'ivy.thomas3', 'hotmail.com');

INSERT INTO building (manager, addr, name, description) VALUES
(1, '2120 Southland Dr, Calgary, AB', 'Glenmore Estates', 'A luxurious high-rise building in downtown Calgary.'),
(2, '815 50 Ave, Calgary, AB', 'Britannia 800', 'A modern apartment complex with great amenities.'),
(3, '789 Oak St, Calgary, AB', 'Oak Heights', 'A cozy building with a view of the mountains.'),
(4, '2719 17 Avenue SW, Calgary, AB', 'The Wellington', 'A family-friendly building with a playground.'),
(5, '202 Maple St, Calgary, AB', 'Maple Suites', 'A stylish building with a rooftop terrace.');

INSERT INTO apartment (building, num, type, description) VALUES
(1, '101', '1BHK', 'A cozy one-bedroom apartment with a balcony.'),
(1, '102', '2BHK', 'A spacious two-bedroom apartment with a modern kitchen.'),
(2, '201', '1BHK', 'A cozy one-bedroom apartment.'),
(2, '202', '3BHK', 'A three-bedroom apartment with a study.'),
(3, '301', '2BHK', 'A two-bedroom apartment with mountain views.'),
(3, '302', '1BHK', 'A compact one-bedroom apartment.'),
(4, '401', '3BHK', 'A large three-bedroom apartment.'),
(4, '402', '2BHK', 'A two-bedroom apartment with a fireplace.'),
(5, '501', '1BHK', 'A modern one-bedroom apartment.'),
(5, '502', '2BHK', 'A two-bedroom apartment with a den.');

INSERT INTO lease (building, apartment, start_date, lease_type, minimum_term, rent_per_term) VALUES
(1, '101', '2025-01-01', 1, 12, 1500),  -- Long-term lease for apartment 101
(1, '102', '2025-02-01', 2, 3, 2000),   -- Fixed-term lease for apartment 102
(2, '201', '2025-03-01', 1, 12, 1200),  -- Long-term lease for apartment 201
(2, '202', '2025-04-01', 2, 6, 2500),   -- Fixed-term lease for apartment 202
(3, '301', '2025-05-01', 1, 12, 1800),  -- Long-term lease for apartment 301
(3, '302', '2025-06-01', 2, 3, 1600),   -- Fixed-term lease for apartment 302
(4, '401', '2025-07-01', 1, 12, 2200),  -- Long-term lease for apartment 401
(4, '402', '2025-08-01', 2, 6, 2400),   -- Fixed-term lease for apartment 402
(5, '501', '2025-09-01', 1, 12, 1300),  -- Long-term lease for apartment 501
(5, '502', '2025-10-01', 2, 3, 1900);   -- Fixed-term lease for apartment 502

INSERT INTO tenant (building, apartment, start_date, ord, tenant) VALUES
(1, '101', '2025-01-01', 1, 1),  -- John Doe is a tenant for apartment 101
(1, '102', '2025-02-01', 1, 3),  -- Alice Johnson is the tenant for apartment 102
(1, '101', '2025-01-01', 2, 3),  -- Alice Johnson is a tenant for apartment 101
(2, '201', '2025-03-01', 1, 5),  -- Charlie Davis is a tenant for apartment 201
(2, '201', '2025-03-01', 2, 3),  -- Alice Johnson is a tenant for apartment 201
(2, '202', '2025-04-01', 1, 7),  -- Frank Moore is the tenant for apartment 202
(3, '301', '2025-05-01', 1, 9),  -- Henry Anderson is the tenant for apartment 301
(3, '302', '2025-06-01', 1, 2),  -- Jane Smith is the tenant for apartment 302
(4, '401', '2025-07-01', 1, 4),  -- Bob Brown is the tenant for apartment 401
(4, '402', '2025-08-01', 1, 6),  -- Eva Wilson is the tenant for apartment 402
(5, '501', '2025-09-01', 1, 8),  -- Grace Taylor is the tenant for apartment 501
(5, '502', '2025-10-01', 1, 10); -- Ivy Thomas is the tenant for apartment 502


INSERT INTO guarantor (id, ord, guarantor) VALUES
(1, 1, 2),  -- Person 1 (John Doe) has Person 2 (Jane Smith) as their primary guarantor
(1, 2, 3),  -- Person 1 (John Doe) has Person 3 (Alice Johnson) as their secondary guarantor
(2, 1, 4),  -- Person 2 (Jane Smith) has Person 4 (Bob Brown) as their primary guarantor
(3, 1, 5),  -- Person 3 (Alice Johnson) has Person 5 (Charlie Davis) as their primary guarantor
(4, 1, 6),  -- Person 4 (Bob Brown) has Person 6 (Eva Wilson) as their primary guarantor
(5, 1, 7),  -- Person 5 (Charlie Davis) has Person 7 (Frank Moore) as their primary guarantor
(6, 1, 8),  -- Person 6 (Eva Wilson) has Person 8 (Grace Taylor) as their primary guarantor
(7, 1, 9),  -- Person 7 (Frank Moore) has Person 9 (Henry Anderson) as their primary guarantor
(8, 1, 10), -- Person 8 (Grace Taylor) has Person 10 (Ivy Thomas) as their primary guarantor
(9, 1, 1);  -- Person 9 (Henry Anderson) has Person 1 (John Doe) as their primary guarantor


-- Task 3
-- Retrieve the details of all apartments in a specific building, sorted by apartment type.
SELECT *
FROM apartment
WHERE building = 1
ORDER BY type;

-- Find all available apartments (not booked during a given date range).
SELECT a.*
FROM apartment a
WHERE NOT EXISTS (
    SELECT 1
    FROM lease l
    JOIN lease_type lt ON l.lease_type = lt.id
    WHERE l.building = a.building
      AND l.apartment = a.num
      And date_overlap(
      l.start_date,
      DATE_ADD(l.start_date, INTERVAL l.minimum_term * lt.days_per_term DAY),
            '2025-01-01',
            '2025-01-31'
          )
);

-- List the buildings with the highest number of booked apartments.
SELECT b.name, COUNT(l.apartment) AS booked_apartments
FROM building b
JOIN lease l ON b.id = l.building
GROUP BY b.id
ORDER BY booked_apartments DESC;

-- Retrieve the total revenue generated by each building from bookings (assume booking cost =  $100 per day).
SELECT b.name, SUM(l.minimum_term * lt.days_per_term * 100) AS total_revenue
FROM building b
JOIN lease l ON b.id = l.building
JOIN lease_type lt ON l.lease_type = lt.id
GROUP BY b.id
order by total_revenue desc;

-- Find guests who have made more than 2 bookings.
SELECT p.full_name, COUNT(t.tenant) AS booking_count
FROM person p
JOIN tenant t ON p.id = t.tenant
GROUP BY p.id
HAVING booking_count > 2;

-- List all bookings that are currently active (ongoing based on the current date).
select t.*
    from (
    select
    b.name as building,
    l.apartment,
    l.start_date,
    DATE_ADD(l.start_date, INTERVAL l.minimum_term * t.days_per_term DAY) as end_date,
    t.name as lease_type,
    l.minimum_term,
    t.days_per_term,
    l.rent_per_term
    from lease l, building b, lease_type t
    where l.building = b.id and l.lease_type = t.id
    ) t
where date_in_range(t.start_date, t.end_date, curdate())
order by t.start_date, t.building, t.apartment;

-- Generate a report showing booking details (apartment, guest name, booking status) for a specific date range.

create procedure apt_status(
    range_start date,
    range_end date
) select
    b.name as building,
    a.num as "apartment number",
    ifnull(group_concat(t.full_name order by t.ord separator ', '), '') as tenants,
    if(max(l.start_date), 'Active', 'Inactive') as "booking status"
from apartment a
join building b on a.building = b.id
left join (select * from lease l, lease_type t where l.lease_type = t.id) l
    on a.building = l.building
    and a.num = l.apartment
    and date_overlap(l.start_date, DATE_ADD(l.start_date, INTERVAL l.minimum_term * l.days_per_term DAY), range_start, range_end)
left JOIN (select * from tenant t, person p where t.tenant = p.id) t
    ON l.building = t.building AND l.apartment = t.apartment AND l.start_date = t.start_date
group by a.building, a.num
order by a.building, a.num;

create procedure cur_apt_status() call apt_status(cur_date(), cur_date());

call apt_status('2025-12-31', '2025-01-01');

-- Failing test for the date_overlap trigger
INSERT INTO lease (building, apartment, start_date, lease_type, minimum_term, rent_per_term) VALUES
(1, '101', date_add('2025-01-01', interval -1 day), 1, 12, 1500);
