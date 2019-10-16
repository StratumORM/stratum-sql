

print 'Testing object listing'

print 'Adding a new property on ONE referenceing FOUR called someChild (1)'
exec orm_property_add 'ONE', 'someChild','FOUR'

print 'Adding values to ONE.FOUR (1,1,9)'
exec orm_change_value 'ONE','obj_ONE','someChild','obj_FOUR'
exec orm_change_value 'ONE','obj_ONE','someChild','obj_FOURx2'

select * from orm_ONE_listing

print 'Removing one of the values (1,8)'
exec orm_change_value 'ONE','obj_ONE','someChild','obj_FOURx2', 1

select * from orm_ONE_listing

print 'Adding an extra value and clearing the list (1,2,7)'
exec orm_change_value 'ONE','obj_ONE','someChild','obj_FOURx3'
exec orm_change_value 'ONE','obj_ONE','someChild',NULL, 1

select * from orm_ONE_listing