/// Test form: Person
Class Form.Test.Person Extends (%Persistent, Form.Adaptor, %Populate)
{

Parameter FORMNAME = "Person";

Parameter OBJPERMISSIONS As %String = "CRUD";

/// Name is a field used as a basic info about this form object
Parameter DISPLAYPROPERTY As %String = "name";

Parameter FORMORDERBY As %String = "dob";

/// Person's name.
/// Use only first 250 symbols for comparison.
/// Required for all long properties used by "order by" 
Property name As %String(COLLATION = "TRUNCATE(250)", DISPLAYNAME = "Name", MAXLEN = 2000);

/// Person's gender
/// Person's Date of Birth.
Property dob As %Date(DISPLAYNAME = "Date of Birth", POPSPEC = "Date()");

Property ts As %TimeStamp(DISPLAYNAME = "Timestamp") [ InitialExpression = {$ZDATETIME($ZTIMESTAMP, 3, 1, 3)} ];

Property num As %Numeric(DISPLAYNAME = "Number") [ InitialExpression = "2.15" ];

/// Person's age.<br>
/// This is a calculated field whose value is derived from <property>DOB</property>.
Property аge As %Integer(DISPLAYNAME = "Age") [ Calculated, SqlComputeCode = { set {*}=##class(Form.Test.Person).currentAge({dob})}, SqlComputed, SqlComputeOnChange = dob ];

/// This class method calculates a current age given a date of birth <var>date</var>.
ClassMethod currentAge(date As %Date = "") As %Integer [ CodeMode = expression ]
{
$Select(date="":"",1:($ZD($H,8)-$ZD(date,8)\10000))
}

/// Person's spouse. 
/// This is a reference to another persistent object.
Property relative As Form.Test.Person(DISPLAYNAME = "Relative");

/// Person's home address. This uses an embedded object.
Property Home As Form.Test.Address(DISPLAYNAME = "House");

/// The company this person works for.
Relationship company As Form.Test.Company(DISPLAYNAME = "Company") [ Cardinality = one, Inverse = employees ];

/// Property amount As %Double(DISPLAYNAME = "double", POPSPEC = "Float(0,100,2)");
Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>name</Value>
</Value>
<Value name="3">
<Value>gender</Value>
</Value>
<Value name="4">
<Value>dob</Value>
</Value>
<Value name="5">
<Value>company</Value>
</Value>
<Value name="6">
<Value>spouse</Value>
</Value>
<Value name="7">
<Value>Home</Value>
</Value>
<Value name="8">
<Value>relative</Value>
</Value>
<Value name="9">
<Value>ts</Value>
</Value>
<Value name="10">
<Value>amount</Value>
</Value>
<Value name="11">
<Value>num</Value>
</Value>
</Data>
<DataLocation>^Form.Test.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<Description>
<![CDATA[Property amount As %Double(DISPLAYNAME = "double", POPSPEC = "Float(0,100,2)");]]></Description>
<ExtentSize>10</ExtentSize>
<IdLocation>^Form.Test.PersonD</IdLocation>
<IndexLocation>^Form.Test.PersonI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>1.1</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="amount">
<AverageFieldSize>19.1</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="dob">
<AverageFieldSize>5</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="name">
<AverageFieldSize>17.4</AverageFieldSize>
<Selectivity>10.0000%</Selectivity>
</Property>
<Property name="num">
<AverageFieldSize>4</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="ts">
<AverageFieldSize>23</AverageFieldSize>
<Selectivity>50.0000%</Selectivity>
</Property>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^Form.Test.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
