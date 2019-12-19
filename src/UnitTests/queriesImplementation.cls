Class UnitTests.QueriesImplementation Extends %UnitTest.TestCase
{

Method OnBeforeAllTests() As %Status
{
  Do ##class(Form.Test.Person).%KillExtent()
  Do ##class(UnitTests.Factory).Ronaldinho()
  Do ##class(UnitTests.Factory).Kaka()
  Return $$$OK
}

Method TestAll()
{
  Set result = "{""children"":["_
    "{""ID"":""1"",""company"":"""",""dob"":""1980-03-21"",""name"":""Ronaldo Gaúcho"",""num"":2.15,""relative"":"""",""ts"":"""",""аge"":39,""Home_City"":"""",""Home_House"":"""",""Home_Street"":"""",""_class"":""Form.Test.Person""},"_
    "{""ID"":""2"",""company"":"""",""dob"":""1982-04-22"",""name"":""Kaká"",""num"":2.15,""relative"":"""",""ts"":"""",""аge"":37,""Home_City"":"""",""Home_House"":"""",""Home_Street"":"""",""_class"":""Form.Test.Person""}"_
    "],""total"":2}"

  Do $$$AssertStatusOK(##class(UnitTests.helper).Get("/form/objects/Form.Test.Person/all", .resp))
  Do $$$AssertEquals(resp.StatusCode, 200)
  Set data = resp.Data.Read()

  // Remove Timestamp
  set dataObj = {}.%FromJSON(data)
  set total = dataObj.%Get("total")
  for i=0:1:(total-1) {
    do dataObj.%Get("children").%Get(i).%Set("ts", "")
  }

  Do $$$AssertEquals(dataObj.%ToJSON(), result)
}

Method TestInfo()
{
  Set result = "{""children"":[{""_id"":""1"",""displayName"":""Ronaldo Gaúcho""},{""_id"":""2"",""displayName"":""Kaká""}],""total"":2}"

  Do $$$AssertStatusOK(##class(UnitTests.helper).Get("/form/objects/Form.Test.Person/info", .resp))
  Do $$$AssertEquals(resp.StatusCode, 200)
  Set data = resp.Data.Read()
  Do $$$AssertEquals(data, result)
}

Method TestQuery()
{
  Set result = "{""children"":[{""name"":""Ronaldo Gaúcho"",""dob"":""1980-03-21"",""аge"":39},{""name"":""Kaká"",""dob"":""1982-04-22"",""аge"":37}],""total"":2}"

  Do $$$AssertStatusOK(##class(UnitTests.helper).Get("/form/objects/Form.Test.Person/LIST", .resp))
  Do $$$AssertEquals(resp.StatusCode, 200)
  Set data = resp.Data.Read()
  Do $$$AssertEquals(data, result)
}

Method TestCustomQuery()
{
  Set result = "{""children"":[{""company"":"""",""name"":""Ronaldo Gaúcho"",""partner"":"""",""аge"":39,""Home_City"":"""",""Home_House"":"""",""Home_Street"":""""},{""company"":"""",""name"":""Kaká"",""partner"":"""",""аge"":37,""Home_City"":"""",""Home_House"":"""",""Home_Street"":""""}],""total"":2}"

  Do $$$AssertStatusOK(##class(UnitTests.helper).Get("/form/objects/Form.Test.Person/custom/SAMPLE", .resp))
  Do $$$AssertEquals(resp.StatusCode, 200)
  Set data = resp.Data.Read()
  Do $$$AssertEquals(data, result)
}

}
