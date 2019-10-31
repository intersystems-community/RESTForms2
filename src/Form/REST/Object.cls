/// Брокер работы с индивидуальными объектами
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
<Route Url="/:form" Method="PUT" Call="updateFormClassObject"/>
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

/// Создание нового объекта для формы form (берём из %request.Content)
/// Возвращает {"Id": "Значение Id"} при успехе
ClassMethod createFormObject(class As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "C")
	return:$$$ISERR(sc) sc
	
	set obj = %request.Content
	set objClass = $className(obj)
	return:objClass'=class $$$ERROR("Expected instance of '" _ class _ "' class, received instance of '" _ objClass _ "'")
	
	set sc = obj.%Save()
	
	if $$$ISOK(sc) {
		 write "{""Id"": """ _ obj.%Id() _ """}" 
	}
	
	return sc
}

/// Обновление объекта id для формы form (берём из %request.Content)
ClassMethod updateFormDynamicObject(class As %String, id As %Integer = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ..checkObjPermission(class, "U")
	return:$$$ISERR(sc) sc
	
	set obj = %request.Content
	set sc = $classMethod(class, $$$updateClassMethod ,id, obj)
	
	return sc
}

/// Обновление объекта id для формы form (берём из %request.Content)
ClassMethod updateFormClassObject(class As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ..checkObjPermission(class, "U")
	return:$$$ISERR(sc) sc
	
	set obj = %request.Content

	set objClass = $className(obj)
	return:objClass'=class $$$ERROR("Expected instance of '" _ class _ "' class, received instance of '" _ objClass _"'")
	
	set sc = obj.%Save()
	
	return sc
}

/// Удаление объекта id для формы form
ClassMethod deleteFormObject(class As %String = "", id As %Integer = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "D")
	return:$$$ISERR(sc) sc

	set sc = $classMethod(class, "%DeleteId", id)
	
	return sc
}

}
