/// This broker does file-related work.
/// All file properies are assumed to be of Form.File class
Class Form.REST.File Extends Form.REST.Abstract
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/:class/:id/:property" Method="POST" Call="addFiles"/>
<Route Url="/:class/:id/:property" Method="DELETE" Call="deleteFiles"/>
<Route Url="/:class/:id/:property/:filename" Method="DELETE" Call="deleteFile"/>
<Route Url="/:class/:id/:property/:filename" Method="GET" Call="serveFile"/>
</Routes>
}

/// class and id are object identificators.  
/// If it's not a list property, then the first file is set as property value 
ClassMethod addFiles(class As %String = "", id As %Integer = "", property As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "U")
	return:$$$ISERR(sc) sc
	
	set obj = $classMethod(class, "%OpenId", id, , .sc)
	return:$$$ISERR(sc) sc
	
	set propertyType = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPtype)
	return:propertyType'=$$$fileClass $$$ERROR($$$GeneralError, property _ " is not file property")

	set propertyCollectionType = $$$comMemberKeyGet(class ,$$$cCLASSproperty, property, $$$cPROPcollection)
	
	
	#dim stream As %CSP.BinaryStream
	set filename = ""
	if propertyCollectionType = "" {
		set filename = %request.NextMimeData(filename)
		quit:filename=""
		set stream = %request.GetMimeData(filename) // Проверить на больших файлах/делит ли ангулар
		set attachment = ##class(Form.File).%New(stream.FileName, filename, stream)
		set $property(obj, property) = attachment  
	} else {
		set propertyOREF = $property(obj, property)
		for {
	        set filename = %request.NextMimeData(filename)
	        quit:filename=""
	        
	        set stream = %request.GetMimeData(filename) // Проверить на больших файлах/делит ли ангулар
	        set attachment = ##class(Form.File).%New(stream.FileName, ..getFileDir(class, id, property), filename, stream)
	        if propertyCollectionType="list" {
		        // propertyOREF тут %Collection.ListOfObj
	        	do $method(propertyOREF, "Insert", attachment)
	        } else {
		        /// Тут если массивы. 
		        /// Как получить следующий индекс
		        /// Так как у нас пока нет, то не пишу		        
	        }
	    }
	}
	set sc = obj.%Save()
	
	return sc
}

/// Clear property value for object with class/id
/// do ##class(Form.REST.File).deleteFiles("Form.Test.Simple", 1, "file")
ClassMethod deleteFiles(class As %String = "", id As %Integer = "", property As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "U")
	return:$$$ISERR(sc) sc
	
	set obj = $classMethod(class, "%OpenId", id, , .sc)
	return:$$$ISERR(sc) sc
	
	set propertyType = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPtype)
	
	return:propertyType'=$$$fileClass $$$ERROR($$$GeneralError, property _ " is not file property")
	
	set $property(obj, property) = ""
	set sc = obj.%Save()
	
	return sc
}

/// Delete value with name=filename from property for object with class/id
ClassMethod deleteFile(class As %String = "", id As %Integer = "", property As %String = "", filename = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "U")
	return:$$$ISERR(sc) sc
	
	set obj = $classMethod(class, "%OpenId", id, , .sc)
	return:$$$ISERR(sc) sc
	
	set propertyType = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPtype)
	
	return:propertyType'=$$$fileClass $$$ERROR($$$GeneralError, property _ " is not file property")
	
	set propertyCollectionType = $$$comMemberKeyGet(class ,$$$cCLASSproperty, property, $$$cPROPcollection)
	
	
	#dim stream As %CSP.BinaryStream
	if propertyCollectionType = "" {
		set propertyOREF = $property(obj, property)
		set storedFilename = propertyOREF.name
		if (storedFilename = filename) {
			set fullFilename = propertyOREF.realName
			do ##class(%File).Delete(fullFilename)
			set $property(obj, property) = ""
		}  else {
			set sc = $$$ERROR($$$GeneralError, filename _ " is incorrect")
		}
	} else {
		#dim propertyOREF As %Collection.ListOfObj
		set propertyOREF = $property(obj, property)
		for i=1:1:propertyOREF.Count() {
			set file = propertyOREF.GetAt(i)
			set storedFilename = file.name
			if (storedFilename=filename) {
				set fullFilename = propertyOREF.realName
				do ##class(%File).Delete(fullFilename)
				do propertyOREF.RemoveAt(i)
				/// Delete only first file
				quit
			}
		}
	}
	
	return:$$$ISERR(sc) sc
	set sc = obj.%Save()
	
	
		
	return sc
}

/// Serve file with name=filename from property for object with class/id
ClassMethod serveFile(class As %String = "", id As %Integer = "", property As %String = "", filename = "") As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(Form.Info).formExistsStatus(class)
	return:$$$ISERR(sc) sc
	set sc = ..checkObjPermission(class, "R")
	return:$$$ISERR(sc) sc
	
	set class = ##class(Form.Info).getFormClass(class)
	set obj = $classMethod(class, "%OpenId", id, , .sc)
	return:$$$ISERR(sc) sc
	
	set propertyType = $$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPtype)
	
	return:propertyType'=$$$fileClass $$$ERROR($$$GeneralError, property _ " is not file property")
	
	set propertyCollectionType = $$$comMemberKeyGet(class ,$$$cCLASSproperty, property, $$$cPROPcollection)
	
	
	#dim stream As %CSP.BinaryStream
	if propertyCollectionType = "" {
		set propertyOREF = $property(obj, property)
		set realFilename = $property(propertyOREF, "name")
		if (realFilename = filename) {
			#dim file As Form.File
			set file = $property(obj, property)
			set sc = file.serve()
		}  else {
			set sc = $$$ERROR($$$GeneralError, filename _ " is incorrect, right one is " _ realFilename)
		}
	} else {
		#dim propertyOREF As %Collection.ListOfObj
		set propertyOREF = $property(obj, property)
		for i=1:1:propertyOREF.Count() {
			set file = propertyOREF.GetAt(i)
			set realFilename = file.name
			if (realFilename=filename) {
				set sc = file.serve()
				quit
			}
		}
	}
	
	return sc
}

/// Get directory path based on structure: basedir/class/id/property 
ClassMethod getFileDir(class As %String, id As %String, property As %String) As %String
{
	set directory = ##class(%File).NormalizeDirectory($$$fileDir)
	set directory = ##class(%File).NormalizeDirectory(directory _ class)
	set directory = ##class(%File).NormalizeDirectory(directory _ id)
	set directory = ##class(%File).NormalizeDirectory(directory _ property)
	if '##class(%File).DirectoryExists(directory) {
		do ##class(%File).CreateDirectoryChain(directory)
	}
	quit directory
}

/// Get file extension ext and filename (without extension) name from filename (without path)
ClassMethod filenameToNameExt(filename As %String, Output name As %String, Output ext As %String)
{
	set ext = "", name = ""
	if $length(filename, ".") > 1 {
		set name = $piece(filename, ".", 1, *-1)
		set ext = $piece(filename, ".", *)
	} else {
		set name = filename
		set ext = ""
	}
}

}
