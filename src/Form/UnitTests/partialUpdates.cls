Class Form.UnitTests.PartialUpdates Extends %UnitTest.TestCase
{

Method OnAfterAllTests() As %Status
{
  Do ##class(Form.Test.Person).%KillExtent()
  Return $$$OK
}

ClassMethod CreatePerson(Output id As %String = "", name As %String, dob As %Date = "", num As %Integer = "") As %Status
{
  Quit ##class(Form.UnitTests.Factory).CreatePerson(.id, name, dob, num)
}

ClassMethod FindPerson(id As %String) As %SQL.StatementResult
{
  Set sql = "SELECT name, %INTERNAL(dob) as dob, num, ""relative"", "_
    "Home_City, Home_House, Home_Street "_
    "FROM Form_Test.Person Where ID = ? "
  Set tStatement = ##class(%SQL.Statement).%New()
	set tSC = tStatement.%Prepare(sql)
	Quit:$$$ISERR(tSC) ""
  Quit tStatement.%Execute(id)
}

Method TestChangeOneProperty()
{
  Set name = "Jhon"
  Set dob = $ZDateH("1994-07-17", 3)
  Do $$$AssertStatusOK(..CreatePerson(.id, name, dob))

  Set json = {}
  Set json.num = 42

  Do $$$AssertStatusOK(##class(Form.UnitTests.helper).Put("/form/object/Form.Test.Person/"_id, json, .resp))
  Do $$$AssertEquals(resp.StatusCode, 200)

  Set result = ..FindPerson(id)
  Do result.%Next()
  Do $$$AssertEquals(result.%Get("name"), name)
  Do $$$AssertEquals(result.%Get("num"), 42)
  Do $$$AssertEquals(result.%Get("dob"), dob)
}

Method TestChangeReferenceProperty()
{
  Set name = "Jhon"
  Set dob = $ZDateH("1994-07-17", 3)
  Do $$$AssertStatusOK(..CreatePerson(.id, name, dob))
  Do $$$AssertStatusOK(..CreatePerson(.relative, "Maria"))

  Set json = {}
  Set json.relative = relative

  Do $$$AssertStatusOK(##class(Form.UnitTests.helper).Put("/form/object/Form.Test.Person/"_id, json, .resp))
  Do $$$AssertEquals(resp.StatusCode, 200)

  Set result = ..FindPerson(id)
  Do result.%Next()
  Do $$$AssertEquals(result.%Get("name"), name)
  Do $$$AssertEquals(result.%Get("relative"), relative)
}

Method TestChangeSerialProperty()
{
  Set name = "Jhon"
  Do $$$AssertStatusOK(..CreatePerson(.id, name))

  Set street = "94 Romario street"
  Set json = {}, json.Home = {}
  Set json.Home.House = 90
  Set json.Home.Street = street

  Do $$$AssertStatusOK(##class(Form.UnitTests.helper).Put("/form/object/Form.Test.Person/"_id, json, .resp))
  Do $$$AssertEquals(resp.StatusCode, 200)

  Set result = ..FindPerson(id)
  Do result.%Next()
  Do $$$AssertEquals(result.%Get("name"), name)
  Do $$$AssertEquals(result.%Get("Home_Street"), street)
}

}
