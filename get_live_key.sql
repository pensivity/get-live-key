-- This script finds the "current" address key for any given address in the address location register table.
--
-- Background:
-- If an address key is considered equivalent to another address key, an alias relationship is created between them.
-- The alias relationship tries to point to the most appropriate address between these equivalent addresses.
-- If the address key is the most appropriate address, it will not have an address alias.
--
-- This script uses a recursive function to get an address key without an address alias. 
-- If the address key doesn't have an address alias, it returns itself, otherwise it follows a chain of aliases until it finds an address without an alias (the most “current” address).
-- It returns 3 fields: 
--    the address_key looked at, 
--    the address_alias_key (which will have another address key in it if the address_key has an alias), 
--    and the live_address_key (which will not have an address alias).
--
-- The idea here is that for any address key, you can instantly find the "live" version of that address.

with get_live_key 
as (
       -- Base Case: select the address_key and dedup_key where the dedup_key is null (the "live" address)
       select address_key, address_alias_key, address_key as live_address_key
       from SLR.export.address_location_register
       where address_alias_key is null

       UNION ALL

       -- Recursive case: for a given address key with an alias relationship, look at the dedup key to see if that has an alias.
       -- The live_address_key won't have an alias.
       select b.address_key, b.address_alias_key, a.live_address_key
       from SLR.export.address_location_register b
       inner join get_live_key a
       on a.address_key = b.address_alias_key
       where b.address_alias_key is not null -- need something in the dedup_key field.
       and a.live_address_key <> b.address_key -- this avoids circular aliases - they break a recursive function.
)


-- This statement gets the whole table using the recursive CTE above.
select *
--, case when address_key = live_address_key then null else live_address_key end as final_address_alias_key -- Is null when the address key and current address key are the same.
from get_live_key

