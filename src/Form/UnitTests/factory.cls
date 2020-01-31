/// Factory to create Data
Class Form.UnitTests.Factory
{

ClassMethod CreatePerson(Output id As %String = "", name As %String, dob As %Date = "", num As %Integer = "") As %Status
{
  Set person = ##class(Form.Test.Person).%New()
  Set person.name = name
  Set:(dob'="") person.dob = dob
  Set:(num'="") person.num = num
  Set tSC = person.%Save()
  Quit:$$$ISERR(tSC) tSC
  Set id = person.%Id()
  Quit tSC
}

ClassMethod Ronaldinho(Output id As %String = "") As %Status
{
  Set name = "Ronaldo Gaúcho"
  Set dob = $ZDateh("1980-03-21", 3)
  Quit ..CreatePerson(.id, name, dob)
}

ClassMethod Kaka(Output id As %String = "") As %Status
{
  Set name = "Kaká"
  Set dob = $ZDateh("1982-04-22", 3)
  Quit ..CreatePerson(.id, name, dob)
}

}
