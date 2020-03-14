alter TRIGGER dbo.trigger__AnotherThing__update 
   ON  dbo.AnotherThing 
   INSTEAD OF update
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	; with unview as
	(	select	InstanceID
			,	Property
			,	Val
		from 
		(	select
			InstanceID
		,	Realish
		,	Real2
		from inserted -- AnotherThing
		) as src
		unpivot
		(	Val for Property in (
			Realish
		,	Real2
		) ) as unpvt
	),	resolved_properties as
	(
		select	unview.InstanceID
			,	props.propertyID
			,	unview.Val
		from orm_meta_properties as props
			inner join unview 
				on props.name = unview.Property
		where	props.templateID = 6 -- AnotherThing
			and props.datatypeID = 3 -- Decimal(19,8)
	)
	merge into orm_meta_values_decimal as v
	using (	select InstanceID, PropertyID, Val
			from resolved_properties) as src
		on	v.instanceID = src.instanceID
		and v.propertyID = src.PropertyID
	when not matched then
		insert (InstanceID, PropertyID, [value])
		values (src.InstanceID, src.PropertyID, src.Val)
	when matched and src.Val is null then
		delete
	when matched and not src.Val is null then
		update set [value] = src.Val
	;



END
GO
