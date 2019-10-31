Include Form

Class Form.Info [ Abstract ]
{

/// Get all forms list
/// w ##class(Form.Info).getFormsList().$toJSONFormat()
ClassMethod getFormsList() As %DynamicArray
{
	#dim sc As %Status = $$$OK
	set forms = []
	
	set rs = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	set sc = rs.%Execute($$$adaptorClass)
	quit:$$$ISERR(sc) 

	while (rs.%Next(.sc)) {
		quit:$$$ISERR(sc)		
		set className = rs.Data("Name")
		CONTINUE:'..formExists(className)
		set formName = $parameter(className, $$$formNameParam)
		set formObj = {"name": (formName), "class": (className)}
		do forms.%Push(formObj)
	}
	
	quit forms
}

/// Get all forms metadata
/// w ##class(Form.Info).getFormsMetadata().$toJSONFormat()
ClassMethod getFormsMetadata() As %DynamicObject
{
	set formsList = ..getFormsList()
	set metadata = {}
	for i = 0:1:formsList.%Size()-1 {
		set form = formsList.%Get(i)
		do metadata.%DispatchSetProperty(form.class, ..getFormMetadata(form.class))
	}
	quit metadata
}

/// Check that form with this classname exist
ClassMethod formExists(className As %String) As %Boolean
{
	return:className="" $$$NO
	return:($$$skipClasses[className) $$$NO
	set formName = $$$defMemberKeyGet(className,$$$cCLASSparameter,$$$formNameParam,$$$cPARAMdefault)
	return:(formName="") $$$NO
	return:($$$skipClasses[className) $$$NO
	return $$$YES
}

/// Check that form with this classname exist
ClassMethod formExistsStatus(className As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set formExists = ..formExists(className)
	if 'formExists {
		set sc = $$$ERROR($$$GeneralError, "Form '" _ className _ "' does not exist")
	}
	return sc
}

/// Get form metadata at runtime
/// Equal to generateMetadata method from Form.Generators class, 
/// but uses direct global references instead of object access
/// For results see:
/// <example>w ##class(Form.Info).getFormMetadata("Form.Test.Simple").$toJSONFormat()</example>
ClassMethod getFormMetadata(className As %String = "") As %DynamicObject
{
	#dim sc As %Status = $$$OK
	set formName = $parameter(className, $$$formNameParam)
	
	set metadata = {}
	set metadata.name = ##class(Form.Util.Translate).get(formName)
	set metadata.class = className
	set metadata.displayProperty = $parameter(className, $$$displayProp)
	set metadata.objpermissions = $parameter(className, "OBJPERMISSIONS")
	
	set metadata.fields = []
	
	set property=$$$comMemberNext(className, $$$cCLASSproperty, "")
	while property'="" {
		set internal = $$$comMemberKeyGet(className, $$$cCLASSproperty, property, $$$cPROPinternal)
		set displayName = ##class(Form.Property).getPropertyParam(className, property, $$$propDisplayNameParam)
		if ((internal '= $$$YES) && (displayName'="")) {
			set propertyMetaData = ##class(Form.Property).propertyToMetadata(className, property)
			set position = $$$comMemberKeyGet(className, $$$cCLASSproperty, property, $$$cPROPsequencenumber)
			
			while metadata.fields.%IsDefined(position) {
				set position = position + 100
			}
			
			do metadata.fields.%Set(position, propertyMetaData)
		}
		set property=$$$comMemberNext(className, $$$cCLASSproperty, property)		
	}
	
	/// we're moving from the end of array to the beginning 
	/// so we can delete null elements without affecting 
	/// the position of elements we're yet to check
	for i = metadata.fields.%Size()-1:-1:0 {
		if metadata.fields.%GetTypeOf(i)="unassigned" {
			 do metadata.fields.%Remove(i)
		}
	}

	
	set callback = "onGenerateMetadata"
	if ##class(%Dictionary.CompiledMethod).IDKEYExists(className, callback) {
		set sc = $classmethod(className, callback, .metadata)
	}
	
	return metadata
}

}
