drop database if exists rentals;
create database rentals;
use rentals;


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
    num char(3),
    type char(4),
    description varchar(1000),
    primary key (building, num),
    foreign key (building) references building(id)
);

create table lease_type (
    id tinyint auto_increment,
    name varchar(30) check (name in ("fixed term", "short term")),
    days_per_term tinyint not null,
    primary key (id)
);

create table lease (
    building int,
    apartment char(3),
    start_date date,
    lease_type tinyint not null,
    minimum_term smallint not null,
    rent_per_term int not null,
    -- impossible?
    -- end_date date as adddate(start_date, minimum_term * lease_type(lease_type));
    primary key (building, apartment, start_date),
    foreign key (building, apartment) references apartment(building, num),
    foreign key (lease_type) references lease_type(id)
);

create table tenant (
    building int,
    apartment char(3),
    start_date date,
    ord tinyint,
    tenant int not null,
    primary key (building, apartment, start_date, ord),
    foreign key (building, apartment, start_date) references lease(building, apartment, start_date),
    foreign key (tenant) references person(id)
);


/* Task 3 */
/* 1 */

/* 2 */

/* 3 */

/* 4 */

/* 5 */

/* 6 */

/* 7 */

