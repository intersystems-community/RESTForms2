/// Work with forms and their contents
Class Form.REST.Form Extends Form.REST.Abstract
{

Parameter CHARSET = "UTF-8";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Map Prefix="/field" Forward="Form.REST.Field"/>
<Map Prefix="/object" Forward="Form.REST.Object"/>
<Map Prefix="/objects" Forward="Form.REST.Objects"/>

<Route Url="/info" Method="GET" Call="getFormsList"/>
<Route Url="/info/all" Method="GET" Call="getFormsMetadata"/>
<Route Url="/info/:form" Method="GET" Call="getFormInfo"/>
</Routes>
}

/// Get available forms list as a JSON array
ClassMethod getFormsList() As %Status
{
	set forms = ##class(Form.Info).getFormsList()
	write ""
	write forms.%ToJSON()
	return $$$OK
}

/// Get available forms metadata as JSON object
ClassMethod getFormsMetadata() As %Status
{
	set metadata = ##class(Form.Info).getFormsMetadata()
	write ""
	write metadata.%ToJSON()
	return $$$OK
}

/// Get form metainformation by name
ClassMethod getFormInfo(form As %String = "") As %Status
{
	set metadata = ##class(Form.Info).getFormMetadata(form)
	write ""
	write metadata.%ToJSON()
	return $$$OK
}

}

