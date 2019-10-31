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
</Data>
<DataLocation>^Form.Test.SimpleD</DataLocation>
<DefaultData>SimpleDefaultData</DefaultData>
<IdLocation>^Form.Test.SimpleD</IdLocation>
<IndexLocation>^Form.Test.SimpleI</IndexLocation>
<StreamLocation>^Form.Test.SimpleS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
