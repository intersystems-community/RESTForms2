Class Form.REST.Main Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Map Prefix="/form" Forward="Form.REST.Form"/>

<Route Url="/logout" Method="GET" Call="logout"/>
<Route Url="/test" Method="GET" Call="test"/>
<Route Url="/test" Method="POST" Call="test"/>
<Route Url="/info" Method="GET" Call="info"/>
</Routes>
}

/// Logout user from current session
ClassMethod logout() As %Status
{
    #dim %session As %CSP.Session
    set st = %session.Logout(1)
    set %session.EndSession = 1
    return st
}

/// Test method
ClassMethod test() As %Status
{
    write "{""Status"": ""OK""}"
    return $$$OK
}

/// Language info
ClassMethod info() As %Status
{
	set info = {}
	set info.languages = ##class(Form.Util.Translate).getLanguages()
	write info.%ToJSON()	
	quit $$$OK
}

}

