Class Form.File Extends %Persistent
{

/// File name as supplied by user
Property name As %String(MAXLEN = 1000, MINLEN = 1) [ Required ];

/// Directory, where file is stored
Property dir As %String(MAXLEN = 1000, MINLEN = 1) [ Required ];

/// Full path to where file is stored
Property realName As %String(MAXLEN = 1000, MINLEN = 1) [ SqlComputeCode = {set {*} = {dir} _ {attachmentHASH}}, SqlComputed, SqlComputeOnChange = (attachmentHASH, dir) ];

/// Description
Property description As %String(MAXLEN = 500);

/// Attachmentt SHA Hash in Base64
Property attachmentHASH As %String;

/// The file itself (data is stored on disk, it's just a link)
Property stream As %FileBinaryStream;

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// If instead of returning a %Status code this returns an oref and this oref is a subclass of the current
/// class then this oref will be the one returned to the caller of %New method.
Method %OnNew(name As %String = "", dir As %String = "", description As %String = "", stream As %Stream.Object = {##class(%FileBinaryStream).%New()}) As %Status [ Private, ServerOnly = 1 ]
{
	#dim sc As %Status = $$$OK
	set ..name = name
	set ..description = description
	set ..attachmentHASH = $system.Encryption.Base64Encode($zcvt($system.Encryption.SHAHashStream(512, stream, .sc),"O","UTF8"), 1)
	return:$$$ISERR(sc) sc
	
	set ..stream.Filename = dir _ ..attachmentHASH
	set sc = ..stream.CopyFromAndSave(stream)
	quit sc
}

/// Serve file in web context
Method serve() As %Status
{
	#dim sc As %Status = $$$OK
    #dim %response As %CSP.Response
	kill %request.Data
	set %request.Data("STREAMOID",1)= ##class(%CSP.StreamServer).Encrypt(..stream.%Oid())
	if ##class(%CSP.StreamServer).OnPreHTTP() {
		set %response.Headers("Content-Disposition")="attachment; filename*=UTF-8''"_##class(%CSP.Page).EscapeURL(..name,"UTF8")
		set st = ##class(%CSP.StreamServer).OnPage()
	}

	quit sc
}

Storage Default
{
<Data name="FileDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>name</Value>
</Value>
<Value name="3">
<Value>description</Value>
</Value>
<Value name="4">
<Value>attachmentGUID</Value>
</Value>
<Value name="5">
<Value>attachmentHASH</Value>
</Value>
<Value name="6">
<Value>stream</Value>
</Value>
<Value name="7">
<Value>realName</Value>
</Value>
<Value name="8">
<Value>dir</Value>
</Value>
</Data>
<DataLocation>^Form.FileD</DataLocation>
<DefaultData>FileDefaultData</DefaultData>
<IdLocation>^Form.FileD</IdLocation>
<IndexLocation>^Form.FileI</IndexLocation>
<StreamLocation>^Form.FileS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
