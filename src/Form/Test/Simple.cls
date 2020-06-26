Class Form.Test.Simple Extends (%Persistent, Form.Adaptor, %Populate)
{

/// Form name, not a global key so it can be anything
Parameter FORMNAME = "Simple form";

/// Default permissions
/// Objects of this form can be Created, Read, Updated and Deleted
/// Redefine this parameter to change permissions for everyone
/// Redefine checkPermission method (see Form.Security) for this class 
/// to add custom security based on user/roles/etc.
Parameter OBJPERMISSIONS As %String = "CRUD";

/// Property used for basic information about the object
/// By default getObjectDisplayName method gets its value from it
Parameter DISPLAYPROPERTY As %String = "displayName";

// Form properties below. Mandatory part above. 

/// The main property describing this object, automatically computes 
/// on insert or update (for SQL) or on save (for object access)
Property displayName As %String(DISPLAYNAME = "Text") [ SqlComputeCode = {set {*} = {text}}, SqlComputed, SqlComputeOnChange = (%%INSERT, %%UPDATE) ];

Property text As %String(DISPLAYNAME = "Text");

Property IntegerList As list Of %Integer(DISPLAYNAME = "IntegerList");

Property IntegerArray As array Of %Integer(DISPLAYNAME = "IntegerArray");

Property ObjectList As list Of Person(DISPLAYNAME = "ObjectList");

Property ObjectArray As array Of Person(DISPLAYNAME = "ObjectArray");

Property Boolean As %Boolean(DISPLAYNAME = "Boolean");

Property Integer As %Integer(DISPLAYNAME = "Integer");

Property BigInt As %BigInt(DISPLAYNAME = "BigInt");

Property SmallInt As %SmallInt(DISPLAYNAME = "SmallInt");

Property TinyInt As %TinyInt(DISPLAYNAME = "TinyInt");

Property Decimal As %Decimal(DISPLAYNAME = "Decimal");

Property Double As %Double(DISPLAYNAME = "Double");

Property Float As %Float(DISPLAYNAME = "Float");

Property Currency As %Currency(DISPLAYNAME = "Currency");

Property Numeric As %Numeric(DISPLAYNAME = "Numeric");

Property String As %String(DISPLAYNAME = "String");

Property VarString As %VarString(DISPLAYNAME = "VarString");

Property Char As %Char(DISPLAYNAME = "Char");

Property Date As %Date(DISPLAYNAME = "Date");

Property DateTime As %DateTime(DISPLAYNAME = "DateTime");

Property Time As %Time(DISPLAYNAME = "Time");

Property TimeStamp As %TimeStamp(DISPLAYNAME = "TimeStamp");

Property PosixTime As %PosixTime(DISPLAYNAME = "PosixTime");

/// do ##class(Form.Test.Simple).recreate()
ClassMethod recreate(count As %Integer = 10, verbose As %Boolean = {$$$NO})
{
	///do ..%DeleteExtent()
	///do ..Populate(count, verbose)
}

/// do ##class(Form.Test.Simple).recreate2()
ClassMethod recreate2()
{
	do ..%DeleteExtent()
	set obj = ..%New()
	set obj.Text = 123
	write obj.%Save()
}

Storage Default
{
<Data name="IntegerArray">
<Attribute>IntegerArray</Attribute>
<Structure>subnode</Structure>
<Subscript>"IntegerArray"</Subscript>
</Data>
<Data name="ObjectArray">
<Attribute>ObjectArray</Attribute>
<Structure>subnode</Structure>
<Subscript>"ObjectArray"</Subscript>
</Data>
<Data name="SimpleDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>displayName</Value>
</Value>
<Value name="3">
<Value>text</Value>
</Value>
<Value name="4">
<Value>gender</Value>
</Value>
<Value name="5">
<Value>Boolean</Value>
</Value>
<Value name="6">
<Value>Integer</Value>
</Value>
<Value name="7">
<Value>BigInt</Value>
</Value>
<Value name="8">
<Value>SmallInt</Value>
</Value>
<Value name="9">
<Value>TinyInt</Value>
</Value>
<Value name="10">
<Value>Decimal</Value>
</Value>
<Value name="11">
<Value>Double</Value>
</Value>
<Value name="12">
<Value>Float</Value>
</Value>
<Value name="13">
<Value>Currency</Value>
</Value>
<Value name="14">
<Value>Numeric</Value>
</Value>
<Value name="15">
<Value>String</Value>
</Value>
<Value name="16">
<Value>VarString</Value>
</Value>
<Value name="17">
<Value>Char</Value>
</Value>
<Value name="18">
<Value>Date</Value>
</Value>
<Value name="19">
<Value>DateTime</Value>
</Value>
<Value name="20">
<Value>Time</Value>
</Value>
<Value name="21">
<Value>TimeStamp</Value>
</Value>
<Value name="22">
<Value>PosixTime</Value>
</Value>
<Value name="23">
<Value>IntegerList</Value>
</Value>
<Value name="24">
<Value>ObjectList</Value>
</Value>
</Data>
<DataLocation>^Form.Test.SimpleD</DataLocation>
<DefaultData>SimpleDefaultData</DefaultData>
<IdLocation>^Form.Test.SimpleD</IdLocation>
<IndexLocation>^Form.Test.SimpleI</IndexLocation>
<StreamLocation>^Form.Test.SimpleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

