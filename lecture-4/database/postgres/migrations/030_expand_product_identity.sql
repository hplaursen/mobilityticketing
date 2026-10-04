-- Expand: add stable product UUIDs while keeping product_code usable.
begin;
set local lock_timeout = '3s';

alter table products
    add column id uuid default gen_random_uuid();

alter table products
    alter column id set not null,
    add constraint products_id_unique unique (id);

alter table tickets
    add column product_id uuid;

alter table tickets
    add constraint tickets_product_id_fk
    foreign key (product_id) references products(id) not valid;

-- Prevent accidental reassignment after the UUID has been issued.
create function prevent_product_id_change()
returns trigger language plpgsql as $$
begin
    if new.id is distinct from old.id then
        raise exception 'Product ID is immutable';
    end if;
    return new;
end;
$$;

create trigger products_id_immutable
before update of id on products
for each row execute function prevent_product_id_change();

commit;
