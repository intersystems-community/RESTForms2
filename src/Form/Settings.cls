Include Form

/// Get and set settings
Class Form.Settings [ Abstract ]
{

/// Get setting value by name (name is always lowercase)
/// Possible settings:
/// queryclass - class for SQL queries. See Form.REST.Objects for implementation details
/// fileDir - directory for files. Defaults to MGR\DB directory
/// <programlisting language="COS">w {}.$toJSON()</programlisting>
ClassMethod getSetting(name As %String) As %String [ CodeMode = expression ]
{
$get($$$settingsGlobal($zcvt(name, "l")))
}

/// Set setting "name" value
ClassMethod setSetting(name As %String = "", value As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	
	if name = "queryclass" {
		if '##class(%Dictionary.ClassDefinition).%ExistsId(value) {
			set sc = $$$ERROR($$$GeneralError, "Class '" _value _ "' does not exis")
		}
	} elseif name = "fileDir" {
		// TODO add valid&writable checks
		set value = ##class(%File).NormalizeDirectory(value)
	} elseif name = "timezone" {
		set value = $zcvt(value, "l")
		if ((value'="utc") && (value'="ignore")) {
			set sc = $$$ERROR($$$GeneralError, "Value '" _value _ "' is not a valid timezone setting. Valid values are: ignore, utc")
		}
	} elseif name = "visited" {
		/// TODO add check	
	}elseif name = "canModify" {
		/// TODO add check	
	} else {
		set sc = $$$ERROR($$$GeneralError, "Setting '" _ name _ "' does not exist")
	}
	
	set:$$$ISOK(sc) $$$settingsGlobal($zcvt(name, "l")) = value
	return sc
}

}
