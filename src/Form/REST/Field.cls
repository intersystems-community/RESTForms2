/// Broker for form fields
Class Form.REST.Field Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/:form" Method="POST" Call="createFormField"/>
<Route Url="/:form" Method="PUT" Call="updateFormField"/>
<Route Url="/:form/:field" Method="DELETE" Call="deleteFormField"/>
</Routes>
}

/// Add field to form
/// URL: POST /form/field/:form
/// Body:
/// {
/// 	 "name":"services",
/// 	 "collection":"",
/// 	 "displayName":"Resource",
/// 	 "type":"%Library.String",
/// 	 "required": "0"
/// }
ClassMethod createFormField(class As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	
	set obj = %request.Content
	 
	set name = obj.name
	set type = obj.type
	set collection = obj.collection
	set displayName = obj.displayName
	set required = obj.required
	
	set sc = ##class(Form.Property).addClassProperty(class, name, type, collection, displayName, required)

	return sc
}

/// Modify field in form
/// URL: PUT /form/field/:form
/// Body:
/// {
/// 	 "name":"services",
/// 	 "collection":"",
/// 	 "displayName":"Resource",
/// 	 "type":"%String",
/// 	 "required": "0"
/// }
ClassMethod updateFormField(class As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	
	set obj = %request.Content
	 
	set name = obj.name
	set type = obj.type
	set collection = obj.collection
	set displayName = obj.displayName
	set required = obj.required
	
	set sc = ##class(Form.Property).modifyClassProperty(class, name, type, collection, displayName, required)

	return sc
}

/// Delete field in form
ClassMethod deleteFormField(class As %String = "", property As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	
	set sc = ##class(Form.Property).deleteClassProperty(class, property)
	return sc
}

}

