Class Form.Test.Company Extends (%Persistent, Form.Adaptor, %Populate)
{

Parameter FORMNAME = "Company";

Parameter OBJPERMISSIONS As %String = "CRUD";

/// Name is a field used as a basic info about this form object
Parameter DISPLAYPROPERTY As %String = "name";

/// The main property describing this object, automatically computes 
/// on insert or update (for SQL) or on save (for object access)
Property name As %String(DISPLAYNAME = "Name", POPSPEC = "Company()");

/// The <class>Person</class> objects associated with this <class>Company</class>.
Relationship employees As Form.Test.Person(%JSONREFERENCE = "ID", DISPLAYNAME = "Employees") [ Cardinality = many, Inverse = company ];

Storage Default
{
<Data name="CompanyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>displayName</Value>
</Value>
<Value name="3">
<Value>name</Value>
</Value>
</Data>
<DataLocation>^Form.Test.CompanyD</DataLocation>
<DefaultData>CompanyDefaultData</DefaultData>
<IdLocation>^Form.Test.CompanyD</IdLocation>
<IndexLocation>^Form.Test.CompanyI</IndexLocation>
<StreamLocation>^Form.Test.CompanyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

