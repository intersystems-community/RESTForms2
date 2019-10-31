/// Various datatype conversion utilities
Class Form.Util.Converter [ Abstract ]
{

/// Convert delimited string to dynamic array
ClassMethod stringToArray(string As %String, delimiter As %String = ",") As %DynamicArray
{
	set list = $listFromString(string, delimiter)
	return ..listToArray(list)
}

/// Convert $list to dynamic array
ClassMethod listToArray(list As %List) As %DynamicArray
{
	set array = []
	set pointer = 0
	while $listNext(list, pointer, piece) {
		do array.%Push(piece)
	}
	return array
}

/// TODO. Populate on install?
ClassMethod sqlTypeToClass(type As %Integer = "") As %String
{
	if type = 2 {
		set result = "%Library.Date"
	} elseif type = 8 {
		set result = "%Library.Time"
	} elseif type = 9 {
		set result = "%Library.TimeStamp"
	} else {
		set result = ""
	}
	return result
}

ClassMethod logicalToJSON(datatype As %String = "", value As %String) As %String
{
    return:datatype="" value
    if datatype = "%Library.Date" {
        set result = ##class(%Date).LogicalToXSD(value)
    } elseif datatype = "%Library.TimeStamp" {
	    set result = ##class(%TimeStamp).LogicalToXSD(value)
	    if ##class(Form.Settings).getSetting("timezone") = "ignore" {
		    set result = $extract(result, 1, *-1) // Remove trailing Z  
	    }
    } elseif datatype = "%Library.PosixTime" {
	    set result = ##class(%PosixTime).LogicalToXSD(value)
	    if ##class(Form.Settings).getSetting("timezone") = "ignore" {
		    set result = $extract(result, 1, *-1) // Remove trailing Z  
	    }
    } elseif datatype = "%Library.Time" {
        set result = ##class(%Time).LogicalToXSD(value)
    } elseif datatype = "%Library.Binary" {
    	set result = $zcvt(value, "O", "JSON")
    } elseif datatype = "%Library.Status" {
    	set result = $System.Status.GetErrorText(value)
    } elseif datatype="Security.Datatype.Password"{
    	set result = ##class(Security.Datatype.Password).LogicalToDisplay(value)
    } else {
        set result = value
    }
    return result
}

ClassMethod jsonToLogical(datatype As %String = "", value As %String) As %String
{
    return:datatype="" value
    if datatype = "%Library.Date" {
        set result = ##class(%Date).XSDToLogical(value)
    } elseif datatype = "%Library.TimeStamp" {
        set result = ##class(%TimeStamp).XSDToLogical(value)
    } elseif datatype = "%Library.PosixTime" {
        set result = ##class(%PosixTime).XSDToLogical(value)
    }  elseif datatype = "%Library.Time" {
        set result = ##class(%Time).XSDToLogical(value)
    } elseif datatype = "%Library.Binary" {
		set result = $zcvt(value, "I", "JSON")
    } else {
        set result = value
    }
    return result
}

}
