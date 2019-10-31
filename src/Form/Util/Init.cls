Include Form

Class Form.Util.Init [ Abstract ]
{

/// <example>do ##class(Form.Util.Init).populateTestForms()</example>
ClassMethod populateTestForms(count As %Integer = 100, verbose As %Boolean = {$$$NO}) As %Status
{
	#dim sc,sc1,sc2 AS %Status = $$$OK
	set sc = ##class(Form.Test.Company).Populate(count, verbose, , , $$$NO)
	set sc1 = ##class(Form.Test.Person).Populate(count, verbose, , , $$$NO)
	set sc2 = ##class(Form.Test.Simple).Populate(count, verbose, , , $$$NO)
	set sc = $$$ADDSC(sc, $$$ADDSC(sc1, sc2))
	return sc
}

/// <example>do ##class(Form.Util.Init).deleteTestForms()</example>
ClassMethod deleteTestForms() As %Status
{
	#dim sc AS %Status = $$$OK
	set sc = ##class(Form.Test.Person).%DeleteExtent()
	set sc1 = ##class(Form.Test.Company).%DeleteExtent()
	set sc2 = ##class(Form.Test.Simple).%DeleteExtent()
	set sc = $$$ADDSC(sc, $$$ADDSC(sc1, sc2))
	return sc
}

/// <example>do ##class(Form.Util.Init).killTestForms()</example>
ClassMethod killTestForms() As %Status
{
	do ##class(Form.Test.Person).%KillExtent()
	do ##class(Form.Test.Company).%KillExtent()
	do ##class(Form.Test.Simple).%KillExtent()
	return $$$OK
}

}
