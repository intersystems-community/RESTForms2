/// Work with individual objects
Class Form.REST.Object Extends Form.REST.Abstract
{

Parameter CHARSET = "UTF-8";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/:form/:id" Method="GET" Call="getFormObject"/>
<Route Url="/:form/:id/:property" Method="GET" Call="getFormObjectProperty"/>
<Route Url="/:form" Method="POST" Call="createFormObject"/>
<Route Url="/:form/:id" Method="PUT" Call="updateFormDynamicObject"/>
<Route Url="/:form/:id" Method="DELETE" Call="deleteFormObject"/>
</Routes>
}

/// Get json representation of an object by its class and id 
ClassMethod getFormObject(class As %String = "", id As %Integer = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "R")
	return:$$$ISERR(sc) sc
	
	set sc = $classMethod(class, $$$toJSONClassMethod, id)
	
	return sc
}

/// Get value of property for object of class with id identifier. Does not open objects if possible
ClassMethod getFormObjectProperty(class As %String = "", id As %Integer = "", property As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "R")
	return:$$$ISERR(sc) sc
	
	return:'##class(%Dictionary.CompiledProperty).IDKEYExists(class, property, .propertyId) $$$ERROR($$$GeneralError, "Property '" _ property _ "' does not exists in '" _ class _ "' class")
	
	if ##class(%Dictionary.CompiledPropertyMethod).IDKEYExists(propertyId, "GetStored") {
		set value = $classMethod(class, property _ "GetStored", id)
	} else {
		 set obj = $classMethod(class, "%OpenId", id, ,.sc)
		 return:$$$ISERR(sc) sc
		 set value = $property(obj, property)
	}

	write "{""" _ property _ """:" _ $$$ZENJSUSTR(value) _ "}"
	
	return sc
}

/// Create new object (from %request.Content)
/// Returns {"Id": "New Id Value"} on success
ClassMethod createFormObject(class As %String) As %Status
{
	set sc = $$$OK
	$$$QuitOnError(##class(Form.Info).formExistsStatus(class))
	$$$QuitOnError(..checkObjPermission(class, "C"))

	$$$QuitOnError($classmethod(class, "createFromJSON", %request.Content, .obj))
	write "{""Id"": """ _ obj.%Id() _ """}" 
	return sc
}

/// Update object by id for form
ClassMethod updateFormDynamicObject(class As %String, id As %Integer = "") As %Status
{
	set sc = $$$OK
	$$$QuitOnError(..checkObjPermission(class, "U"))
	$$$QuitOnError($classmethod(class, "updateFromJSON", id, %request.Content, .obj))
	return sc
}

/// Delete object by id from form
ClassMethod deleteFormObject(class As %String = "", id As %Integer = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "D")
	return:$$$ISERR(sc) sc

	set sc = $classMethod(class, "deleteObject", id)
	
	return sc
}

}

