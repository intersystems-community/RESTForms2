/// Broker class to work with queries
Class Form.REST.Objects Extends Form.REST.Abstract
{

/// Query to return all availible information about form objects
Parameter ALL = "*, %CLASSNAME AS _class";

/// Query to return objects count
Parameter COUNT = "count(1) ""count""";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/:form/custom/:query" Method="GET" Call="getFormObjectsCustom"/>
<Route Url="/:form/:query" Method="GET" Call="getFormObjects"/>
</Routes>
}

/// Get all form objects
ClassMethod getFormObjects(class As %String = "", queryType As %String) As %Status
{
	#dim sc As %Status = $$$OK
	Set sc = ##class(Form.Info).formExistsStatus(class)
	Return:$$$ISERR(sc) sc
	Set sc = ..checkObjPermission(class, "R")
	Return:$$$ISERR(sc) sc
	Set sc = ..getBaseQuery(queryType, class, .queryBase)
	Return:$$$ISERR(sc) sc

	Set table = ##class(%CSP.UI.Portal.SQL.Home).Quoter2($$$ClassSQLTable(class))
	Set sql = queryBase _ table

	Set sc = ##class(Form.JSON.SQL).WriteJSONFromSQL(sql, class)
	Return sc
}

/// Returns the part between SELECT and FORM (queryBase) based on queryType and target class
/// Supported queryBase sources:<br>
/// 1. Uppercase parameter values defined in this class<br>
/// 2. ClassMethods, defined in this class with the name: queryQUERYTYPE
ClassMethod getBaseQuery(queryType As %String, class As %String, Output queryBase As %String) As %Status
{
	Set queryBase = ""
	Set queryType = $ZConvert(queryType, "U")
	Set userQueryClass = ##class(Form.Settings).getSetting("queryclass")
	#dim sc As %Status = $$$OK
	If ##class(%Dictionary.CompiledMethod).IDKEYExists(class, "query" _ queryType) {
		Set queryBase = $Classmethod(class, "query" _ queryType)
	}
  elseif ((userQueryClass'="") && (##class(%Dictionary.CompiledParameter).IDKEYExists(userQueryClass, queryType))) {
		Set queryBase = $Parameter(userQueryClass, queryType)
	}
  elseif ((userQueryClass'="") && (##class(%Dictionary.CompiledMethod).IDKEYExists(userQueryClass, "query" _ queryType))) {
		Set queryBase = $Classmethod(userQueryClass, "query" _ queryType, class)
	}
  elseif ##class(%Dictionary.CompiledParameter).IDKEYExists($Classname(), queryType) {
		Set queryBase = $Parameter(, queryType)
	}
  elseif ##class(%Dictionary.CompiledMethod).IDKEYExists($Classname(), "query" _ queryType) {
		Set queryBase = $Classmethod(, "query" _ queryType, class)
	}
  elseif 0 {
		/// TODO Some other type of "get stuff between SELECT and FROM"
	}
  else {
		Set sc = $$$ERROR($$$GeneralError, "Query type " _ queryType _ " not found")
	}

	If (queryBase'="") {
		Set queryBase = "SELECT " _ queryBase _ " FROM "
	}

	Return sc
}

/// Return id and dislpayName
/// <example>w ##class(Form.REST.Objects).queryINFO("Form.Test.Simple")</example>
ClassMethod queryINFO(class As %String) As %String
{
	Set method = "getObjectDisplayName"

	If ##class(%Dictionary.CompiledMethod).IDKEYExists(class, method) {
		Set sqlProc = $$$ClassSQLTable(class) _ "_" _ method _ "(id)"
	}
  else {
		Set sqlProc = $Parameter(class, $$$displayProp)
	}

	Set queryBase = "id AS _id, " _ sqlProc _ " As displayName"
	Return queryBase
}

/// Return all non collection object fields
/// <example>w ##class(Form.REST.Objects).queryALLOBJ("Form.Test.Simple")</example>
ClassMethod queryALLOBJ(class As %String) As %String
{
	Set queryBase = "%ID ID, "
	Set property=$$$comMemberNext(class, $$$cCLASSproperty, "")
	While property'="" {
		Set internal = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPinternal)
		Set displayName = ##class(Form.Property).getPropertyParam(class, property, $$$propDisplayNameParam)
		Set collection = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPcollection)
		If ((internal '= $$$YES) && (displayName'="") && (collection = "")) {
			Set type = ##class(Form.Property).getPropertyType(class, property)
			Set category = ##class(Form.Property).determineClassCategory(type)
			Set sqlName = ##class(Form.Property).getPropertySQLName(class, property)
	
			If category = "serial" {
				Set queryBase = queryBase _ ..SerialToJSONOBJECT(sqlName, type)
			} Else {
				Set:$system.SQL.IsReservedWord(sqlName) sqlName = $$$QUOTE(sqlName)
				Set queryBase = queryBase _ sqlName
			}
			Set queryBase = queryBase _ ", "
		}
		
		Set property=$$$comMemberNext(class, $$$cCLASSproperty, property)		
	}

	Set queryBase = $e(queryBase, 1,*-2) 
	Return queryBase
}

/// refProperty - property name for a serial class
/// class - serial class
ClassMethod SerialToJSONOBJECT(refProperty As %String, class As %Dictionary.Classname, level As %Integer = 0) As %String
{
	Set queryBase = "JSON_OBJECT("
	Set property=$$$comMemberNext(class, $$$cCLASSproperty, "")
	While property'="" {
		Set internal = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPinternal)
		Set collection = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPcollection)
		If ((internal '= $$$YES) && (collection = "")) {
			Set type = ##class(Form.Property).getPropertyType(class, property)
			Set category = ##class(Form.Property).determineClassCategory(type)
			Set sqlName = ##class(Form.Property).getPropertySQLName(class, property)
		
			If category = "serial" {
				Set queryBase = queryBase _ "'" _ sqlName _ "':" _ ..SerialToJSONOBJECT(refProperty _ "_" _ sqlName, type, level + 1)
			} Else {
				Set queryBase = queryBase _ "'" _ sqlName _ "':" _  refProperty _ "_" _ sqlName
			}
			Set queryBase = queryBase _ ", "
		}
		
		Set property=$$$comMemberNext(class, $$$cCLASSproperty, property)		
	}

	Set queryBase = $e(queryBase, 1,*-2) _ ") " _ $s(level=0:"JSON@" _ refProperty, 1:"")
	Return queryBase
}

/// Return id, dislpayName and class
/// <example>w ##class(Form.REST.Objects).queryINFOCLASS("Form.Test.Simple")</example>
ClassMethod queryINFOCLASS(class As %String) As %String
{
	Set queryBase = ..queryINFO(class) _ ", %CLASSNAME AS _class "
	Return queryBase
}

/// Get form objects by a custom query
ClassMethod getFormObjectsCustom(class As %String = "", queryType As %String) As %Status
{
	#dim sc As %Status = $$$OK
	Set sc = ##class(Form.Info).formExistsStatus(class)
	Return:$$$ISERR(sc) sc
	Set sc = ..checkObjPermission(class, "R")
	Return:$$$ISERR(sc) sc

	Set queryType = $ZConvert(queryType, "U")

	If ##class(%Dictionary.CompiledMethod).IDKEYExists(class, "customquery" _ queryType) {
		Set sql = $Classmethod(class, "customquery" _ queryType)
	}
  else {
		Set sc = $$$ERROR($$$GeneralError, "Custom query type " _ queryType _ " not found")
	}

	Return:$$$ISERR(sc) sc

	Set sc = ##class(Form.JSON.SQL).WriteJSONFromSQL(sql)
	Return sc
}

}

