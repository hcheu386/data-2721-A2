drop database if exists rentals;
create database rentals;
use rentals;



create function date_overlap (start_1 date, end_1 date, start_2 date, end_2 date)
returns bool
deterministic
return
    (start_1 >= start_2 and start_1 <= end_2)
    or (end_1 >= start_2 and end_1 <= end_2);


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
    declare new_start date;
    declare new_end date;

    select days_per_term into days from lease_type where new.lease_type = id;
    set new_start = new.start_date;
    set new_end = date_add(new.start_date, interval new.minimum_term * days day);

    if exists (
        select true from lease l, lease_type t
        where l.lease_type = t.id
        and l.building = new.building
        and l.apartment = new.apartment
        and date_overlap(new_start, new_end, l.start_date, date_add(l.start_date, interval l.minimum_term * t.days_per_term day))
        limit 1
    ) then
        signal sqlstate value '23000' set message_text = 'The date of the input lease overlaps with existing lease(s) of the same apartment.';
    end if;
end $
delimiter ;
