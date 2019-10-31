Include Form

/// Support for metadata translation 
Class Form.Util.Translate
{

/// Get translated value of a text
/// w ##class(Form.Util.Translate).get()
ClassMethod get(text As %String)
{
	set domain = $$$domain
	set language=""
	
	if $isObject($g(%request)) {
		set language=$$MatchLanguage^%occMessages(%request.GetCgiEnv("HTTP_ACCEPT_LANGUAGE"))
	}	
	
	set:language="" language = $s($mvv(58)="":"en",1:$mvv(58))
	
	set id = $zcrc(text, 7)
	set text = $$$GetAppMessage(language, domain, id, text)
	//set text = $zcvt(text, "O", "UTF8")
	quit text
}

/// Add text to ^CacheMsg
/// do ##class(Form.Util.Translate).Insert()
ClassMethod insert(text)
{
	set text = $$$quote(text)
	set domain = $$$domainq
	set a = $$macroText^%occMessages($lb(text, domain))
}

ClassMethod getLanguages() As %DynamicArray
{
	set languages = []
	#dim list As %ListOfDataTypes
	set list = ##class(%MessageDictionary).GetLanguages($$$domain)
	for i=1:1:list.Count() {
		do languages.%Push(list.GetAt(i))
	}
	quit languages
}

}
