Include (%occErrors, %ZEN.Utils, Form)

/// Абстрактный класс, реализующий техническую обработку входящего запроса.
Class Form.REST.Abstract Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "UTF-8";

Parameter UseSession As Integer = 1;

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

ClassMethod getDebugInfo() As %ZEN.proxyObject
{
	set obj = ##class(%ZEN.proxyObject).%New()
	set obj.stack = ..getStackInfo()
	set obj.objlasterror = $system.Status.GetErrorText($get(%objlasterror))
	set obj.request = %request
	set obj.responce = %response
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

/// This method Gets called prior to dispatch of the request. Put any common code here
/// that you want to be executed for EVERY request. If pContinue is set to 0, the
/// request will NOT be dispatched according to the UrlMap. If this case it's the
/// responsibility of the user to return a response.
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
    Quit ..convertRequestBody()
}

/// Конвертируем %request.Content в UTF8 и в объект класса %ZEN.proxyObject
ClassMethod convertRequestBody() As %Status
{
	#dim %request As %CSP.Request
	#dim obj As %ZEN.proxyObject
	
	return:'$isObject(%request.Content) $$$OK // нет тела запроса
	return:'$$$classIsStream($className(%request.Content)) $$$OK // уже сконвертировали
	// Конвертируем объект в UTF8 %ZEN.proxyObject
	set content = %request.Content.Read($$$MaxStringLength)
	set content = $ZCVT(content,"I","UTF8") 
	set:$$$debug %objlasterror = ""
	set sc = ##class(Form.JSON.OBJ).%ConvertJSONToObject(content,,.obj,1)
	
	if $$$debug {
		zw obj
		write $System.Status.GetErrorText(%objlasterror)
	}
	return:$$$ISERR(sc) sc
	return:'$isObject(obj) $$$ERROR($$$ArgumentIsNotAnObject,"Body")
	
	set %request.Content = obj // obj это валидный UTF8 %ZEN.proxyObject
	return $$$OK
}

ClassMethod checkObjPermission(class As %String, action As %String(VALUELIST="C,R,U,D")) As %Status
{
	return $classmethod(class, "checkObjPermissionStatus", action)
}

}
