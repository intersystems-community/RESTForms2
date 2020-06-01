Include (%occErrors, %ZEN.Utils, Form)

/// Abstract broker for tech request processing. 
/// No business logic goes here
Class Form.REST.Abstract Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "UTF-8";

Parameter UseSession As Integer = 1;

Parameter CONVERTINPUTSTREAM = 1;

/// This method takes a status, renders it as json (if requested) and outputs the result
ClassMethod outputStatus(pSC As %Status) As %Status [ Internal ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
        
        #dim tJSON As %ZEN.proxyObject
    
        If ..AcceptsContentType("application/json") {
        
            Set %response.ContentType = ..#CONTENTTYPEJSON
        
            #; Convert the exception to a status and render to JSON
            Set tSC = ..StatusToProxyObject(pSC, .tJSON)
            Set tJSON.stack = ..getDebugInfo()
            If $$$ISERR(tSC) Quit

            #; Write the JSON to the output device
            Set tSC = tJSON.%ToJSON(, "aeloqutwc")
            If $$$ISERR(tSC) Quit
            
        } else {
            
            #; Set plain text
            Set %response.ContentType = ..#CONTENTTYPETEXT
            
            #; Write out a simple text message
            Do ##class(%Exception.StatusException).CreateFromStatus(pSC).OutputToDevice()
        }
        
    } Catch (e) {
        #; Oops
        Set tSC = e.AsStatus()
    }
    Quit $$$OK
}

/// Called for a REST page in the event of a login being required
ClassMethod Login(skipheader As %Boolean = 1) As %Status [ ProcedureBlock = 0 ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tMatchURL As %String
			$$$SysLog(3,"OAuth2","[%CSP.REST]","Login: %request.Method="_%request.Method)
           
    Try {
        
        #; Don't want the session token
        Set %response.OutputSessionToken=0
        
        #; Also set language to prevent any attempt to call %response.MatchLanguage as this can cause PROTECT errors reading from ^IRIS.Msg global
        If %response.Language="" Set %response.Language="en"
        
        Set tMatchURL=$Extract(%request.URL,$Length(%request.Application),*)
      
        #; Process CORS request
        Set tSC=..ProcessCorsRequest(tMatchURL)
        If $$$ISERR(tSC) Quit
            
        If %request.Method="OPTIONS" {
            
            #; We want to allow OPTIONS requests even if not authorized
            Set tSC=..OnHandleOptionsRequest(tMatchURL)
            If $$$ISERR(tSC) Quit
         
        } else {
            
            #; Set the Http Status
            Set %response.Status=..#HTTP401UNAUTHORIZED
            
            #; We DO NOT want Basic authentication
            #; Do %response.SetHeader("WWW-Authenticate","Basic")
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    #; We need to manually write out the headers here because PAGE has not been called
    Do %response.WriteHTTPHeader()
        
    #; Done
    Quit tSC
}

ClassMethod getDebugInfo() As %ZEN.proxyObject
{
	set obj = ##class(%ZEN.proxyObject).%New()
	set obj.stack = ..getStackInfo()
	set obj.objlasterror = $system.Status.GetErrorText($get(%objlasterror))
	set obj.request = %request
	set obj.response = %response
	set obj.user = $username
	
	return obj
}

ClassMethod getStackInfo() As %ListOfDataTypes
{

	set ex = ##class(%Exception.SystemException).%New()
	do ex.StackAsArray(.stack)
	set list = ##class(%ListOfObjects).%New()
	for i=1:1:stack {
		set obj = ##class(%ZEN.proxyObject).%New()
		set obj.line = stack(i,"PLACE")
		set obj.call =  stack(i)
		set obj.part = $piece($piece(stack(i,"PLACE"), "^", *), " ", 1)
		do list.Insert(obj)
	}
	
	return list
}

ClassMethod checkObjPermission(class As %String, action As %String(VALUELIST="C,R,U,D")) As %Status
{
	return $classmethod(class, "checkObjPermissionStatus", action)
}

}

