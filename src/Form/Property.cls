Include Form

/// Methods for form field === class property
Class Form.Property [ Abstract ]
{

/// Get metadata for one field of a form. Equal to propertyToMetadata method, 
/// but uses direct global references instead of object access
ClassMethod propertyToMetadata(className As %String = "", name = "") As %DynamicObject
{
	set metadata = {}
	set metadata.name = name
	set metadata.type = ..getPropertyType(className, name)
	set metadata.collection = $$$comMemberKeyGet(className, $$$cCLASSproperty, name, $$$cPROPcollection)
	set metadata.displayName = ..getPropertyDisplayName(className, name)
	
	set valueList = ..getPropertyParam(className, name, "VALUELIST")
	set:valueList'="" metadata.valueList = ##class(Form.Util.Converter).stringToArray(valueList)
	
	set displayList = ..getPropertyParam(className, name, "DISPLAYLIST")
	set:displayList'="" metadata.displayList = ##class(Form.Util.Converter).stringToArray(displayList)
	
	set metadata.maxlen =  ..getPropertyParam(className, name, "MAXLEN")

	set metadata.required = +$$$comMemberKeyGet(className, $$$cCLASSproperty, name, $$$cPROPrequired)	
	set metadata.category = ..determineClassCategory(metadata.type)
	return metadata
}

/// Determine class type
ClassMethod determineClassCategory(className As %String = "") As %String
{
	return:##class(Form.Info).formExists(className) "form"
	return:className=$$$fileClass "file"
	return $$$getClassType(className)
}

/// Add class property
/// className - class
/// name - property name
/// type - property type
/// collection - is a collection (list, array)
/// displayName - displayname parameter value
/// required - is it required (0/1)
ClassMethod addClassProperty(className As %String = "", name As %String, type As %String = "%String", collection As %String(VALUELIST=",list,array") = "", displayName As %String = "", required As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	if (##class(%Dictionary.PropertyDefinition).IDKEYExists(className, name)) {
		return $$$ERROR($$$GeneralError, "Property " _ name _ " already exists")
	}
	
	set class = ##class(%Dictionary.ClassDefinition).%OpenId(className, ,.sc)
	return:$$$ISERR(sc) sc
	
	set property = ##class(%Dictionary.PropertyDefinition).%New()
	set property.Name = name
	set property.Type = type
	set property.Collection = collection
	set property.Required = required
	if (($get(displayName)'="") && ($$$comClassKeyGet(className,$$$cCLASSpropertyclass)[$$$propClass)) {
		set sc = property.Parameters.SetAt(displayName, $$$propDisplayNameParam)
		return:$$$ISERR(sc) sc
	}
	
	set sc = class.Properties.Insert(property)
	return:$$$ISERR(sc) sc
	
	set sc = class.%Save()
	return:$$$ISERR(sc) sc
	
	kill class	
	return ..compileClass(className)
}

/// Modify class property
/// className - class
/// name - property name
/// type - property type
/// collection - is a collection (list, array)
/// displayName - displayname parameter value
/// required - is it required (0/1)
ClassMethod modifyClassProperty(className As %String = "", name As %String, type As %String = "%String", collection As %String(VALUELIST=",list,array") = "", displayName As %String = "", required As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	set property = ##class(%Dictionary.PropertyDefinition).IDKEYOpen(className, name, , sc)
	return:$$$ISERR(sc) sc
	
	set property.Type = type
	set property.Collection = collection
	set property.Required = required
	if (($get(displayName)'="") && ($$$comClassKeyGet(className,$$$cCLASSpropertyclass)=$$$propClass)) {
		set sc = property.Parameters.SetAt(displayName, $$$propDisplayNameParam)
		return:$$$ISERR(sc) sc
	}

	set sc = property.%Save()
	return:$$$ISERR(sc) sc
	
	kill property	
	return ..compileClass(className)
}

/// Delete class property
/// className - class
/// name - property
ClassMethod deleteClassProperty(className As %String = "", name As %String) As %Status
{
	#dim sc As %Status = $$$OK
	if ('##class(%Dictionary.PropertyDefinition).IDKEYExists(className, name)) {
		return $$$ERROR($$$GeneralError, "Property " _ name _ " does not exist")
	}
	
	set sc = ##class(%Dictionary.PropertyDefinition).IDKEYDelete(className, name)
	return:$$$ISERR(sc) sc
	
	return ..compileClass(className)
}

/// Compile class and return status
/// Do not output anything to device
ClassMethod compileClass(className As %String = "") As %Status [ CodeMode = expression ]
{
$system.OBJ.Compile(className, "cuks /checkuptodate=expandedonly /displaylog=0 /displayerror=0")
}

/// Get property DISPLAYNAME
/// w ##class(Form.Property).getPropertyDisplayName("Form.Test.Simple", "text")
ClassMethod getPropertyDisplayName(className As %String = "", name As %String) As %String
{
	set displayName = ..getPropertyParam(className, name, $$$propDisplayNameParam)
	set displayName = ##class(Form.Util.Translate).get(displayName)
	set:displayName="" displayName = name
	return displayName
}

/// Get property Type
/// w ##class(Form.Property).getPropertyType("Form.Test.Simple", "text")
ClassMethod getPropertyType(className As %String = "", name As %String) As %String
{
	set type = $$$comMemberKeyGet(className, $$$cCLASSproperty, name, $$$cPROPtype)
	set:type="" type = "%Library.String"
	return type
}

/// Get property param
/// w ##class(Form.Property).getPropertyParam("Form.Test.Simple", "text", "VALUELIST")
ClassMethod getPropertyParam(className As %String = "", name As %String = "", param = "") As %String [ CodeMode = expression ]
{
$$$comMemberArrayGet(className, $$$cCLASSproperty, name, $$$cPROPparameter, param)
}

/// Get property SQL name
/// w ##class(Form.Property).getPropertySQLName("Form.Test.Simple", "text")
ClassMethod getPropertySQLName(className As %String = "", name As %String = "") As %String [ CodeMode = expression ]
{
$$$comMemberKeyGet(className, $$$cCLASSproperty, name, $$$cPROPsqlfieldname)
}

}

