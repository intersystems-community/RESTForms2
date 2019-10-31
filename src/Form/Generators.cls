/// Various generators called on form compilation which does not actually generate any code 
/// Generators that actually generate the code should be placed into Form.Adaptor class
Class Form.Generators [ Abstract ]
{

/// End form callback method
ClassMethod onGenerateMetadata(ByRef metadata As %DynamicObject) As %Status
{
	Return $$$OK
}

/// Validate FORMORDERBY parameter value if present
ClassMethod validateOrderBy() As %String [ CodeMode = objectgenerator, GenerateAfter = generateMetadata, Internal ]
{
	#Include Form
	#dim sc As %Status = $$$OK
	set className = %compiledclass.Name
	set formNameKey = %class.Parameters.FindObjectId(className _ "||" _ $$$formNameParam)
	set formName = $get(%parameter($$$formNameParam))
	return:(($$$skipClasses[className)||(formName="")||(formNameKey="")) sc
	
	set orderBy = $get(%parameter($$$orderByParam))
	return:(orderBy = "") sc
	
	set key = %compiledclass.Properties.FindObjectId(className _ "||" _ orderBy)
	return:key="" $$$ERROR($$$GeneralError, "Order by property '" _ orderBy _"' does not exist in '" _ className _ "' class. Redefine " _ $$$orderByParam _ " parameter")
	
	quit sc
}

/// Validate FORMORDERBY parameter value if present
ClassMethod validatePermissions() As %String [ CodeMode = objectgenerator, GenerateAfter = generateMetadata, Internal ]
{
	#Include Form
	#dim sc As %Status = $$$OK
	set className = %compiledclass.Name
	set formNameKey = %class.Parameters.FindObjectId(className _ "||" _ $$$formNameParam)
	set formName = $get(%parameter($$$formNameParam))
	return:(($$$skipClasses[className)||(formName="")||(formNameKey="")) sc
	
	/// checkObjPermission method is redefined, so we don't check this class
	set key = %class.Methods.FindObjectId(className _ "||checkObjPermission")
	return:key'="" sc

	set permParam = $get(%parameter($$$objPermParam))
	/// $$$objPermParam parameter is not set
	return:permParam="" $$$ERROR($$$GeneralError, "Object permissions param '" _ $$$objPermParam _"' does not exist in '" _ className _ "' class. Define it.") 
	
	/// strip everything from $$$objPermParam except 'CRUD' characters
	set permParamStripped = $zstrip(permParam,"*E",,"CRUD")
	
	if permParam'=permParamStripped {
		set sc = $$$ERROR($$$GeneralError, "Object permissions param '" _ $$$objPermParam _"' = '" _ permParam _ "' in '" _ className _ "' class contains characters beyond 'CRUD'") 
	}
	
	quit sc
}

/// Fill ^CacheMsg global for further translation
ClassMethod translate() [ CodeMode = objectgenerator, GenerateAfter = generateMetadata, Internal ]
{
	#Include Form
	#dim sc As %Status = $$$OK
	set className = %compiledclass.Name
	set formNameKey = %class.Parameters.FindObjectId(className _ "||" _ $$$formNameParam)
	set formName = $get(%parameter($$$formNameParam))
	return:(($$$skipClasses[className)||(formName="")||(formNameKey="")) sc
	
	do ##class(Form.Util.Translate).insert(formName)
	
	#dim prop As %Dictionary.PropertyDefinition
	for i = 1:1:%class.Properties.Count() {
        set prop = %class.Properties.GetAt(i)
        set displayName = prop.Parameters.GetAt($$$propDisplayNameParam)
        if prop.Internal || prop.Calculated || prop.ReadOnly || prop.Private || prop.Identity || prop.MultiDimensional || displayName = ""  continue
		
		do ##class(Form.Util.Translate).insert(displayName)
    }
    quit $$$OK
}

}
