Class Form.Security [ Abstract ]
{

/// Default permissions to access form object
Parameter OBJPERMISSIONS As %String = "CRUD";

/// This is an override method to perform an actual permission check
/// By default it uses PERMISSIONS parameter, but the form can override 
/// based on a role/user/whatever
ClassMethod checkObjPermission(action As %String(VALUELIST="C,R,U,D")) As %Boolean
{
	return:action="" $$$NO
	return ..#OBJPERMISSIONS [ action
}

/// Check, if the action we want to perform can be done
/// This method is final. Override checkPermission method
ClassMethod checkObjPermissionStatus(action As %String(VALUELIST="C,R,U,D")) As %Status [ Final ]
{
	#dim sc As %Status = $$$OK
	set permission = ..checkObjPermission(action)
	if 'permission {
		set sc = $$$ERROR($$$GeneralError, "Action '" _ action _ "' cannot be performed in the context of " _ $classname())
	}
	return sc
}

}
