-- create database hooky;
create user hookyuser with encrypted password 'P0stGr3$$';
grant all privileges on database hooky to hookyuser;

create table public.webhook
(
	id uuid not null
		constraint webhook_pk
			primary key,
	status varchar(8) default 'NEW'::character varying not null,
	url varchar(1024) not null,
	http_method varchar(7) not null,
	headers varchar(1024),
	query_params varchar(1024),
	body text,
	run_count integer default 0 not null,
	updated_at timestamp,
	created_at timestamp default CURRENT_TIMESTAMP not null,
	response_code integer,
	surrogate_id bigserial not null,
	locked boolean default false not null,
	lock_date timestamp
);

comment on table public.webhook is 'Webhook jobs';

alter table public.webhook owner to hookyuser;

create unique index webhook_surrogate_id_uindex
	on public.webhook (surrogate_id);

-- create sequence webhook_surrogate_id_seq;
--
-- alter sequence webhook_surrogate_id_seq owner to hookyuser;




