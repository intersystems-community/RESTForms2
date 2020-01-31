/// 
/// TestCase for Object CRUD operations
Class Form.UnitTests.ObjectCRUD Extends %UnitTest.TestCase
{

/// Delete test data after all tests
Method OnAfterAllTests() As %Status
{
  do ##class(Form.Test.Person).%KillExtent()
  quit $$$OK
}

/// After each test: restore class parameters to default values
Method OnAfterOneTest(testname As %String) As %Status
{
  set ret = $$$OK
  try {
    // restore class parameters
    set paramName=$lb("Form.Test.Person||FORMCREATEMAPPING","Form.Test.Person||FORMUPDATEMAPPING","Form.Test.Person||FORMREADMAPPING")
    for i=1:1:$ll(paramName) {
      set param = ##class(%Dictionary.ParameterDefinition).%OpenId($lg(paramName, i))
      set param.Default = ""
      $$$ThrowOnError(param.%Save())
      $$$ThrowOnError($system.OBJ.Compile("Form.Test.Person"))
    }

  } catch ex {
    set ret = ex.AsStatus()
  }
  quit ret
}

/// 
/// Create objects
/// - POST /form/object/:class
Method TestCreate()
{
  // -- use default JSON mapping defined in class, FORMCREATEMAPPING=""
  // create company
  set companyReq = { "name": "Dallas Mavericks" }
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Post("/form/object/Form.Test.Company", companyReq, .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  set companyRsp = {}.%FromJSON(resp.Data.Read())
  set company = ##class(Form.Test.Company).%OpenId(companyRsp.%Get("Id"))
  do $$$AssertEquals(companyRsp.%Get("Id"), company.%Id())
  do $$$AssertEquals(company.name, companyReq.%Get("name"))
  
  // create person
  set personReq = {"name":"Luka Dončić","dob":"1999-02-28","num":77,"company":(company.%Id())} 
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Post("/form/object/Form.Test.Person", personReq, .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  set personRsp = {}.%FromJSON(resp.Data.Read())
  set person = ##class(Form.Test.Person).%OpenId(personRsp.%Get("Id"))
  do $$$AssertEquals(personRsp.%Get("Id"), person.%Id())
  do $$$AssertEquals(person.company.%Id(), company.%Id())
  do $$$AssertEquals(person.name, personReq.%Get("name"))
  do $$$AssertEquals($zdate(person.dob,3), personReq.%Get("dob"))
  do $$$AssertEquals(person.num, personReq.%Get("num"))

  // -- use FORMCREATEMAPPING="CreateMapping"
  set param = ##class(%Dictionary.ParameterDefinition).%OpenId("Form.Test.Person||FORMCREATEMAPPING")
  set param.Default = "CreateMapping"
  do $$$AssertStatusOK(param.%Save())
  do $$$AssertStatusOK($system.OBJ.Compile("Form.Test.Person"))
  // create person
  set personReq = {"fullName":"Kristaps Porziņģis","dob":"1995-08-02","num":6,"company":("Form.Test.Company,"_company.%Id())} 
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Post("/form/object/Form.Test.Person", personReq, .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  set personRsp = {}.%FromJSON(resp.Data.Read())
  set person = ##class(Form.Test.Person).%OpenId(personRsp.%Get("Id"))
  do $$$AssertEquals(personRsp.%Get("Id"), person.%Id())
  do $$$AssertEquals(person.company.%Id(), company.%Id())
  do $$$AssertEquals(person.name, personReq.%Get("fullName"))
  do $$$AssertEquals($zdate(person.dob,3), personReq.%Get("dob"))
  do $$$AssertEquals(person.num, personReq.%Get("num"))
}

/// 
/// Read objects 
/// - GET /form/object/:class/:id
/// - Test different JSON mappings (FORMREADMAPPING)
Method TestRead()
{
  // create company
  set company = ##class(Form.Test.Company).%New()
  set company.name = "Houston Rockets"
  do $$$AssertStatusOK(company.%Save())

  // create person
  set person = ##class(Form.Test.Person).%New()
  set person.name = "James Harden"
  set person.dob = $zdateh("1989-08-26", 3)
  set person.num = 13
  set person.ts = "2019-12-18 17:35:01"
  set person.company = company
  do $$$AssertStatusOK(person.%Save())

  // -- use default JSON mapping defined in class, FORMREADMAPPING=""
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Get("/form/object/Form.Test.Person/"_person.%Id(), .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  set data = resp.Data.Read()
  set expected = {"name":"James Harden","dob":"1989-08-26","ts":"2019-12-18T17:35:01Z","num":13,"аge":(##class(Form.Test.Person).currentAge(person.dob)),"company":(company.%Id())}
  do $$$AssertEquals(data, expected.%ToJSON(), "default mapping")

  // -- use FORMREADMAPPING="ReadMapping"
  set param = ##class(%Dictionary.ParameterDefinition).%OpenId("Form.Test.Person||FORMREADMAPPING")
  set param.Default = "ReadMapping"
  do $$$AssertStatusOK(param.%Save())
  do $$$AssertStatusOK($system.OBJ.Compile("Form.Test.Person"))
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Get("/form/object/Form.Test.Person/"_person.%Id(), .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  set data = resp.Data.Read()
  set expected = {"name":"James Harden","dateOfBirth":"1989-08-26","num":13,"company":("Form.Test.Company,"_company.%Id())}
  do $$$AssertEquals(data, expected.%ToJSON(), "ReadMapping")
}

/// 
/// Update objects
/// - PUT /form/object/:class/:id
Method TestUpdate()
{
  // -- use default JSON mapping defined in class, FORMUPDATEMAPPING=""
  // create company
  set company = ##class(Form.Test.Company).%New()
  set company.name = "Los Angeles Lakers"
  do $$$AssertStatusOK(company.%Save())
  // create person
  set person = ##class(Form.Test.Person).%New()
  set person.name = "Alex Caruso"
  set person.dob = $zdateh("1994-02-28", 3)
  set person.num = 4
  set person.company = company
  do $$$AssertStatusOK(person.%Save())
  // update person
  set personReq = {"name":"Alex Caruso (Bald Mamba)","dob":"1994-02-28","num":3,"company":(company.%Id())} 
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Put("/form/object/Form.Test.Person/"_person.%Id(), personReq, .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  do $$$AssertStatusOK(person.%Reload())
  do $$$AssertEquals(person.name, personReq.%Get("name"))
  do $$$AssertEquals($zdate(person.dob,3), personReq.%Get("dob"))
  do $$$AssertEquals(person.num, personReq.%Get("num"))
  do $$$AssertEquals(person.company.%Id(), personReq.%Get("company"))

  // -- use FORMUPDATEMAPPING="UpdateMapping"
  set param = ##class(%Dictionary.ParameterDefinition).%OpenId("Form.Test.Person||FORMUPDATEMAPPING")
  set param.Default = "UpdateMapping"
  do $$$AssertStatusOK(param.%Save())
  do $$$AssertStatusOK($system.OBJ.Compile("Form.Test.Person"))
  // create person
  set person = ##class(Form.Test.Person).%New()
  set person.name = "Anthony Davis"
  set person.dob = $zdateh("1993-03-11", 3)
  set person.num = 3
  set person.company = company
  do $$$AssertStatusOK(person.%Save())
  // update person
  set personReq = {"fullName":"Anthony Davis (The Brow)","dob":"1993-03-11","num":3,"company":(company.%Id())} 
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Put("/form/object/Form.Test.Person/"_person.%Id(), personReq, .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  do $$$AssertStatusOK(person.%Reload())
  do $$$AssertEquals(person.name, personReq.%Get("fullName"))
  do $$$AssertEquals($zdate(person.dob,3), personReq.%Get("dob"))
  do $$$AssertEquals(person.num, personReq.%Get("num"))
  do $$$AssertEquals(person.company.%Id(), personReq.%Get("company"))
}

/// 
/// Update objects
/// - DELETE /form/object/:class/:id
Method TestDelete()
{
  // create person
  set person = ##class(Form.Test.Person).%New()
  set person.name = "Rajon Rondo"
  set person.dob = $zdateh("1986-02-22", 3)
  set person.num = 9
  do $$$AssertStatusOK(person.%Save())

  // delete person
  do $$$AssertStatusOK(##class(Form.UnitTests.helper).Delete("/form/object/Form.Test.Person/"_person.%Id(), .resp))
  do $$$AssertEquals(resp.StatusCode, 200)
  do $$$AssertEquals(##class(Form.Test.Person).%ExistsId(person.%Id()), 0)
}

}
