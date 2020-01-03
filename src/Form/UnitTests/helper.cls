/// Helper to create HttpRequest
Class Form.UnitTests.helper
{

/// Your WebApplication Name
Parameter APLICATION = "forms";

/// Application Host
Parameter HOST = "localhost";

Parameter PORT = 52773;

Parameter TIMEOUT = 2;

Parameter USERNAME = "_SYSTEM";

Parameter PASSWORD = "SYS";

ClassMethod GetServer() As %Net.HttpRequest
{
  Set httpRequest = ##class(%Net.HttpRequest).%New()
  Set httpRequest.Server = ..#HOST
  Set httpRequest.Port = ..#PORT
  Set httpRequest.Timeout = ..#TIMEOUT

  set auth = "Basic "_$system.Encryption.Base64Encode(..#USERNAME _":"_..#PASSWORD)
  Do httpRequest.SetHeader("Authorization", auth)
  Quit httpRequest
}

/// Parse Response Data Stream to DynamicObject
ClassMethod ResponseDataToJSON(response As %Net.HttpResponse) As %DynamicObject
{
  Set data = response.Data.Read(32000)
  Quit {}.%FromJSON(data)
}

ClassMethod Get(location As %String, Output response As %Net.HttpResponse) As %Status
{
  Set tSC = $$$OK
  Try {
    Set server = ..GetServer()
    $$$THROWONERROR(tSC, server.Get(..#APLICATION _ location))
    Set response = server.HttpResponse
  } Catch tErr {
		Set tSC = tErr.AsStatus()
  }
  Quit tSC
}

ClassMethod Post(location As %String, body As %DynamicObject, Output response As %Net.HttpResponse) As %Status
{
  Set tSC = $$$OK
  Try {
    Set server = ..GetServer()
    Set json = body.%ToJSON()
    Do server.EntityBody.Write(json)
    $$$THROWONERROR(tSC, server.Post(..#APLICATION _ location))
    Set response = server.HttpResponse
  } Catch tErr {
		Set tSC = tErr.AsStatus()
  }
  Quit tSC
}

ClassMethod Put(location As %String, body As %DynamicObject, Output response As %Net.HttpResponse) As %Status
{
  Set tSC = $$$OK
  Try {
    Set server = ..GetServer()
    Set json = body.%ToJSON()
    Do server.EntityBody.Write(json)
    $$$THROWONERROR(tSC, server.Put(..#APLICATION _ location))
    Set response = server.HttpResponse
  } Catch tErr {
		Set tSC = tErr.AsStatus()
  }
  Quit tSC
}

ClassMethod Delete(location As %String, Output response As %Net.HttpResponse) As %Status
{
  Set tSC = $$$OK
  Try {
    Set server = ..GetServer()
    $$$THROWONERROR(tSC, server.Delete(..#APLICATION _ location))
    Set response = server.HttpResponse
  } Catch tErr {
		Set tSC = tErr.AsStatus()
  }
  Quit tSC
}

}
