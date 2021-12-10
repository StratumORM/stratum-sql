use orm_test
go

exec orm.template_add 'MES Equipment'
exec orm.property_add 'MES Equipment', 'label', 'string'
exec orm.property_add 'MES Equipment', 'parent', 'MES Equipment'
exec orm.property_add 'MES Equipment', 'state', 'integer'
exec orm.property_add 'MES Equipment', 'infeed', 'integer'
exec orm.property_add 'MES Equipment', 'outfeed', 'integer'
exec orm.property_add 'MES Equipment', 'scrap', 'integer'

exec orm.template_add 'Line'
exec orm.template_add 'Workcenter'
exec orm.template_add 'Workstation'

exec orm.inherit_add 'MES Equipment', 'Line'
exec orm.inherit_add 'MES Equipment', 'Workcenter'
exec orm.inherit_add 'MES Equipment', 'Workstation'

exec orm.instance_add 'Line', 'Line 1'
exec orm.value_change 'Line', 'Line 1', 'label', 'Line 1'

exec orm.instance_add 'Workcenter', 'Line 1/Workcenter 1'
exec orm.value_change 'Workcenter', 'Line 1/Workcenter 1', 'label', 'Workcenter 1'
exec orm.value_change 'Workcenter', 'Line 1/Workcenter 1', 'parent', 'Line 1'

exec orm.instance_add 'Workstation', 'Line 1/Workcenter 1/Workstation A'
exec orm.value_change 'Workstation', 'Line 1/Workcenter 1/Workstation A', 'label', 'Workstation A'
exec orm.value_change 'Workstation', 'Line 1/Workcenter 1/Workstation A', 'parent', 'Line 1/Workcenter 1'

exec orm.instance_add 'Workstation', 'Line 1/Workcenter 1/Workstation B'
exec orm.value_change 'Workstation', 'Line 1/Workcenter 1/Workstation B', 'label', 'Workstation B'
exec orm.value_change 'Workstation', 'Line 1/Workcenter 1/Workstation B', 'parent', 'Line 1/Workcenter 1'

exec orm.instance_add 'Workcenter', 'Line 1/Workcenter 2'
exec orm.value_change 'Workcenter', 'Line 1/Workcenter 2', 'label', 'Workcenter 2'
exec orm.value_change 'Workcenter', 'Line 1/Workcenter 2', 'parent', 'Line 1'

exec orm.instance_add 'Line', 'Line 2'
exec orm.value_change 'Line', 'Line 2', 'label', 'Line 2'

exec orm.instance_add 'Line', 'Line 3'
exec orm.value_change 'Line', 'Line 3', 'label', 'Line 3'

exec orm.instance_add 'Workcenter', 'Line 3/Workcenter 1'
exec orm.value_change 'Workcenter', 'Line 3/Workcenter 1', 'label', 'Workcenter 1'
exec orm.value_change 'Workcenter', 'Line 3/Workcenter 1', 'parent', 'Line 3'

exec orm.instance_add 'Workcenter', 'Line 3/Workcenter 2'
exec orm.value_change 'Workcenter', 'Line 3/Workcenter 2', 'label', 'Workcenter 2'
exec orm.value_change 'Workcenter', 'Line 3/Workcenter 2', 'parent', 'Line 3'

exec orm.instance_add 'Workstation', 'Line 3/Workcenter 2/Workstation X'
exec orm.value_change 'Workstation', 'Line 3/Workcenter 2/Workstation X', 'label', 'Workstation X'
exec orm.value_change 'Workstation', 'Line 3/Workcenter 2/Workstation X', 'parent', 'Line 3/Workcenter 2'


-- do these in some interesting order, and repeat one to make sure it dedupes correctly
exec orm.value_change 'Line', 'Line 1', 'state', '1'
waitfor delay '00:00:05'
exec orm.value_change 'Line', 'Line 1', 'state', '2'
waitfor delay '00:00:25'
exec orm.value_change 'Line', 'Line 1', 'state', '1'
waitfor delay '00:01:35'
exec orm.value_change 'Line', 'Line 1', 'state', '4'
waitfor delay '00:01:12'
exec orm.value_change 'Line', 'Line 1', 'state', '8'
waitfor delay '00:00:20'
exec orm.value_change 'Line', 'Line 1', 'state', '1'



