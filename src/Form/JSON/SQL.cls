Include Form

Class Form.JSON.SQL Extends %ZEN.Auxiliary.altJSONSQLProvider
{

ClassMethod WriteJSONFromSQL(sql As %String, conditionClass = "") As %Status
{
	#dim sc As %Status = $$$OK
	Set provider = ..%New()
	Set provider.maxRows = $$$MaxCacheInt
	Set provider.%Format = $$$formatJSONSQL

	If ((##class(%Dictionary.CompiledClass).IDKEYExists(conditionClass)) && $$$webContext) {
		Set sc = ..ParseWhere(%request.Get("filter"), %request.Get("collation"), conditionClass, .where)
		Set sc = $$$ADDSC(sc, ..ParseOrderBy(%request.Get("orderby"), conditionClass, .orderBy))
		Set sql = sql _ where _ orderBy
	}
  ElseIf (conditionClass'="") {
		Set sc = $$$ERROR($$$GeneralError, "Condition class " _ conditionClass _ " does not exist")
	}
	Return:$$$ISERR(sc) sc

	Set provider.sql = sql
	If $$$webContext {
		Set provider.pageSize = %request.Get("size", 25)
		Set provider.currPage = %request.Get("page", 1)
	}

	Set nocount = %request.Get("nocount", $$$NO)

	Set sc = provider.%DrawJSON(nocount)
	Return sc
}

/// Parse where condition:
/// <example>w ##class(Form.JSON.SQL).ParseWhere("Text eq Admin Text neq 1", , "Form.Test.Simple", .out)</example>
/// result: out=" WHERE Text='Admin' AND Text='1'"
ClassMethod ParseWhere(input, collation As %String(VALUELIST=",SQLUPPER,EXACT") = "", conditionClass, Output condition) As %Status
{
	#dim sc As %Status = $$$OK
	Kill condition
	Set condition = ""
	Set:$Extract(input,1)="(" input = $Extract(input,2,*-1)
	Return:input="" sc

	Set:collation'="" collation = "%" _ collation
	Set condList = $Listfromstring(input," ")
	Set listLength = $Listlength(condList)

	If listLength#3'=0 {
		Return $$$ERROR($$$GeneralError, "Incorrect number of filter arguments")
	}

	Set condition = " WHERE "

	For i=1:3:listLength {
		Set:i'=1 condition = condition _ " AND "
		Set column = $Listget(condList,i)
		Set predicate = $Listget(condList,i+1)
		Set value = $Translate($Listget(condList,i+2),$Char(9)," ") // replaces <TAB> in filter values eith whitespaces
		Set value = $Translate(value,"'"";")

		Set columnValid = ..ParseColumn(.column, conditionClass, .propertyClass)
		Return:'columnValid $$$ERROR($$$GeneralError,"Filter column '" _column _ "' is not valid for " _ conditionClass)
		Set:$System.SQL.IsReservedWord(column) column = """" _ column _ """"

		Set value = ##class(Form.Util.Converter).jsonToLogical(propertyClass, value)

		Set sqlpredicate = ..TranslatePredicate(predicate)
		If sqlpredicate="" {
			Return $$$ERROR($$$GeneralError,"Incorrect filter predicate")
		}

		#define sq(%str) "'" _ %str _ "'"
		If sqlpredicate = "IN" {

			Set valTemp = "("
			For j=1:1:$Length(value, "~") {
				Set curVal = $Piece(value, "~", j)
				Set curVal = $$$sq(curVal)
				Set:curVal="'$$$NULL'" curVal = "NULL"
				Set:((collation'="") && (curVal'="NULL")) curVal = collation _ "(" _ curVal _ ")"

				Set valTemp = valTemp _ curVal
				Set:j'=$Length(value, "~") valTemp = valTemp _ ", "
			}
			Set value = valTemp _ ")"
		}
    Else {
			Set value = $$$sq(value)
			Set:value="'$$$NULL'" value = "NULL"
		}

		If collation'="" {
			Set:((value'="NULL") && (sqlpredicate '="IN")) value = collation _ "(" _ value _ ")"
			Set column = collation _ "(" _ column _ ")"
		}

		Set condition = condition _ column _ " " _ sqlpredicate _ " " _ value
	}
	Return $$$OK
}

/// Is this column reference valid.
/// <example>w ##class(Form.JSON.SQL).ParseColumn("company->addrerss_City", "Form.Test.Person", .c)</example>
ClassMethod ParseColumn(ByRef column, conditionClass, Output finalPropertyClass) As %Boolean
{
	Kill finalPropertyClass
	Set column = $Replace(column, "_", "->") // Serial references
	Set columnOut = ""

	Set length = $Length(column,"->")
	For j = 1:1:length {
		// Determine current class context and property name
		Set currentClass = $Case(j, 1:conditionClass, :##class(Form.Property).getPropertyType(currentClass, currentProperty)) // first piece - conditionClass, otherwise - previous class
		Set currentProperty = $Piece(column,"->",j)

		// Last property may be an ID (which is not a %Dictionary.CompiledProperty cilumn,
		// so quit from the for cycle
		If ((j=length) && ($ZConvert(currentProperty, "U") = "ID")) {
			Set columnOut = columnOut _ "ID"
			Quit
		}

		// Property does not exist. Abort.
		If '##class(%Dictionary.CompiledProperty).IDKEYExists(currentClass, currentProperty) {
			Return $$$NO
		}

		// Get property SQL name (usually equal to property name)
		Set currentPropertySQLName = ##class(Form.Property).getPropertySQLName(currentClass, currentProperty)
		Set:$System.SQL.IsReservedWord(currentPropertySQLName) currentPropertySQLName = """" _ currentPropertySQLName _ """"

		// Append property SQL name to resulting sql expression
		Set columnOut = columnOut _ currentPropertySQLName

		// Append _ or -> separator if this is not a last column
		If j'=length {
			Set propertyType = ##class(Form.Property).getPropertyType(currentClass, currentProperty)
			If $$$classIsSerial(propertyType) {
				Set separator = "_"
			}
      Else {
				Set separator = "->"
			}
			Set columnOut = columnOut _ separator
		}
	}
	Set finalPropertyClass = ##class(Form.Property).getPropertyType(currentClass, currentProperty)
	Set column = columnOut

	Return $$$YES
}

/// Translate predicate from js into sql
ClassMethod TranslatePredicate(predicate = "") As %String
{
	Quit:predicate="" ""
	Quit:predicate="neq" "!="
	Quit:predicate="eq" "="
	Quit:predicate="gte" ">="
	Quit:predicate="gt" ">"
	Quit:predicate="lte" "<="
	Quit:predicate="lt" "<"
	Quit:predicate="startswith" "%STARTSWITH"
	Quit:predicate="contains" "["
	Quit:predicate="doesnotcontain" "NOT["
	Quit:predicate="in" "IN"
	Quit:predicate="is" "IS"
	Quit:predicate="isnot" "IS NOT"
	Quit:predicate="like" "LIKE"

	Quit ""
}

/// w ##class(Form.JSON.SQL).ParseOrderBy("Value desc", "Form.TestRef")
ClassMethod ParseOrderBy(input, class, Output condition) As %Status
{
	#dim sc As %Status = $$$OK
	Kill condition

	// If input is an empty string use form FORMORDERBY parameter
	Set:input="" input = $Parameter(class, $$$orderByParam)
	Set:input="" input = $Parameter(class, $$$displayProp)
	Set condition = ""
	Return:input="" sc

	Set descPos = $Find(input, " desc")
	If descPos'=0 {
		Set column = $Extract(input, 1, descPos-6) // 6 = $Length("+desc")+1
	}
  Else {
		Set column = input
	}

	If ##class(%Dictionary.CompiledProperty).IDKEYExists(class, column) {
		Set column = ##class(Form.Property).getPropertySQLName(class, column)
		Set:$System.SQL.IsReservedWord(column) column = """" _ column _ """"
	}
  ElseIf $Isvalidnum(column, 0, 1) {
		/// nothing to do here
	}
  Else {
		Set sc = $$$ERROR($$$GeneralError, "Sorting column '" _ column _ "' does not exist")
		Set column = "" // invalidate SQL jic
	}

	Set condition = " ORDER BY " _ column _ $Select(descPos'=0:" DESC",1:"")
	Return sc
}

/// Draw JSON output.
/// nocount - do not output count of rows
Method %DrawJSON(nocount As %Boolean = {$$$NO}) As %Status [ Internal ]
{
	Set ..contentType = "array"
	// override base method to get information from SQL statement
	Set tSC = $$$OK
	Try {
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParms(key) = $$$ZENVAL(value)
			Set key = ..parameters.Next(key)
		}
		Set tOrigSQL = ..sql
		Set tSQL = ..sql

		If (..OnGetSQL '= "") {
			Set tSC = ..%OnGetSQL(.tParms,.tSQL)
			If $$$ISERR(tSC) {
				Quit
			}
			Set ..sql = tSQL
		}

		Set tInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()
		Merge tInfo.parms=tParms

		#Dim tRS As %Library.ResultSet
		Set tRS = ..%CreateResultSet(.tSC,tInfo)
		If $$$ISERR(tSC)||'$IsObject(tRS) {
			Quit
		}

		// find number and name of columns
		Kill tColInfo
		If tRS.%IsA("%Library.ResultSet") {
			Set tCols = tRS.GetColumnCount()
			For c = 1:1:tCols {
				Set tColInfo(c,"name") = tRS.GetColumnHeader(c)
				Set tColInfo(c,"type") = ##class(Form.Util.Converter).sqlTypeToClass(tRS.GetColumnType(c))
			}
		}
		Else {
			Set tCols = tRS.%ResultColumnCount
			For c = 1:1:tCols {
				Set tColInfo(c,"name") = tRS.%Metadata.columns.GetAt(c).label
			}
		}
		Set ..sql = tOrigSQL

		Write "{"
 		// FORMS - debug
		Write:$$$debug """sql"":"""_ tOrigSQL_""","
 		// END - FORMS - debug

		Write """"_..arrayName_""":["

 		// FORMS - pagination
		Set tStartRow = ..pageSize * (..currPage - 1)
		Set tEndRow = tStartRow + ..pageSize
		// END - FORMS - pagination

		// fetch and emit JSON
		// n.b. this should be pushed into the result set itself
		Set tRow = 0
		Set rows = ""
			// The last condition - FORMS - pagination
		While (tRS.%Next(.tSC) && ((..maxRows = 0) || (tRow < ..maxRows)) && (tRow < tEndRow)) {
			Quit:$$$ISERR(tSC)
			Set tRow = tRow + 1

			// FORMS - pagination
			Continue:(tRow<=tStartRow)
			// END - FORMS - pagination

			Set node = ""
			For c = 1:1:tCols {
				Set tVal = tRS.%GetData(c)
				Set tColName = $Get(tColInfo(c,"name"))
				Set tOutVal = ##class(Form.Util.Converter).logicalToJSON($Get(tColInfo(c,"type")), tVal)
				// to surround no numbers values and Id by quotes
				Set:(($Isvalidnum(tOutVal)=$$$NO)||($ZConvert(tColName,"l")="id")||($ZConvert(tColName,"l")="_id")) tOutVal = $Char(34)_tOutVal_$Char(34)
				Set $List(node,*+1) = """"_tColName_""":"_tOutVal
			}
			Set:(node'="") $List(rows, *+1) = "{"_$ListToString(node,",")_"}"
		}
		Write $ListToString(rows,",")_"]"

		// FORMS - results count
		If nocount = $$$NO {
			While tRS.%Next() {}
			Write ",""total"":"_ tRS.%ROWCOUNT
		}
		// END - FORMS - results count

		Write "}"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnCreateResultSet(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set:$IsObject($Get(%request)) tMode = %request.Get("mode", 0)
	Set tRS = ##class(%ResultSet).%New()
	Set tSC = tRS.Prepare(..sql)
	Set tRS.RuntimeMode = $Get(tMode, 0)
	Set pInfo.queryText = "sql: "_..sql
	Return tRS
}

}

