/// Преобразует объект класса Cache в JSON. 
/// Изменения ищутся по слову FORMS
Class Form.JSON.OBJ Extends %ZEN.Auxiliary.jsonProvider [ DependsOn = Form.Settings ]
{

/// On JSON -> Obj parsing, check what forms can be modified by user  
ClassMethod CanModify(pObject As Form.Adaptor, pLevel As %Integer) [ CodeMode = objectgenerator ]
{
	set %code.CodeMode = "expression"
	set code = ##class(Form.Settings).getSetting("canModify")
	if code'="" {
		do %code.WriteLine(code)
	} else {
		do %code.WriteLine("pLevel=1")
	}
}

/// Write out the contents of object instance <var>pObject</var> to
/// the current device using JSON notation.
ClassMethod %ObjectToJSON(pObject As %RegisteredObject, ByRef pVisited, pLevel As %Integer = 0, pFormat As %String = "aceloqtw") As %Status
{
	quit pObject.%JSONExport()
}

/// Parse the string <var>pJSON</var> containing JSON notation
/// and convert it to an object instance <var>pObject</var>.<br/>
/// <var>pJSON</var> could also be a character stream.<br/>
/// <var>pClass</var> is the name of the class to create to hold
/// the instantiated object. This class must match the data within the JSON
/// notation. If <var>pClass</var> is empty (""), then an instance
/// of the generic class <class>%ZEN.proxyObject</class> will be created.
/// <var>pCharsProcessed</var> and <var>pLevel</var> are used
/// internally and do not have to be supplied.
/// <var>pIgnoreUnknownProps</var> controls whether we will
/// ignore errors when we process a property that isn't expected. The default 
/// behaviour is to treat this as an error.<br/>
/// Note that this method assumes well-formed JSON notation: it does
/// not perform complete error checking.
ClassMethod %ParseJSON(pJSON As %String, pClass As %String = "", Output pObject As %RegisteredObject, Output pCharsProcessed As %Integer, pLevel As %Integer = 1, pFirstChar As %String = "", pIgnoreUnknownProps As %Boolean = 0) As %Status [ Internal ]
{
#define WHITESPACE(%c) (((%c)=" ")||((%c)=$C(10))||((%c)=$C(13))||((%c)=$C(9)))
#define MATCHHEXCHARS(%hex,%n) (%hex ? %n(1N,1(1"A",1"B",1"C",1"D",1"E",1"F",1"a",1"b",1"c",1"d",1"e",1"f")))

	Set tSC = $$$OK
	Try {
		Set tOrigClass = pClass
		Set tClass = $S(pClass="":"%ZEN.proxyObject",1:pClass)
		Set pObject = ""
		Set pCharsProcessed = 0

		Set p = 1
		Set tToken = ""
		Set tProperty = ""
		Set tValue = ""
		Set tState = 0
		Set tInArray = 0
		Set tArrayType = ""
		Set tArrayState = "value"
		Set tArrayKey = ""
		Set tIsString = 0
		Set tQuote = ""
		Set tPropQuoted = 0
		Set tUnicodeHex = ""
		Set tHex = ""
		Set tJSONArray = 0
		While ($$$ISOK(tSC)) {
			// test end condition; get next character
			If ($IsObject(pJSON)) {
				If (pFirstChar'="") {
					Set ch = pFirstChar
					Set pFirstChar = ""
				}
				Else {
	 				If (pJSON.AtEnd) Quit
					Set ch = pJSON.Read(1,.tSC)
					If $$$ISERR(tSC) Quit
				}
			}
			Else {
 				If (p > $L(pJSON)) Quit
				Set ch = $E(pJSON,p)
			}

			Set p = p + 1
			Set pCharsProcessed = pCharsProcessed + 1
			If (tState = 0) {
				If (ch = "{") {
					// start of object
					// we will hold the property values in here until the end
					Kill tPropValues	
					Set pObject = ""
					Set tState = 1
				}
				ElseIf (ch = "[") {
					Set tJSONArray = 1
					Kill tPropValues
					Set pObject = ""
					Set tCollectionClass = $select((pClass '= "")&&$classmethod(pClass,"%Extends","%Collection.AbstractList"): pClass, 1 :"")
					// start of list/array-valued property
					Set tInArray = 1
					Set tArrayType = "list"
					Kill tArray
					Set tArrayIndex = 0
					Set tToken = ""
					Set tIsString = 0
					Set tState = 5
					Set tArrayState = "value"
				}
				ElseIf '$$$WHITESPACE(ch) {
					Set tSC = $$$ERROR($$$GeneralError,"Expected { at start of JSON text.")
					Quit
				}
			}
			ElseIf (tState = 1) {
				If (ch = "}") {
					// end of object
					// create object, stuff properties into it
					Set pClass = $G(tPropValues("_class"),pClass)
					Set tClass = $G(tPropValues("_class"),tClass)
					
					// FORMS - instantiate object by id
					Set tId = $G(tPropValues("_id"))
					
					If tId'="" {
						Set pObject = $classmethod(tClass,"%OpenId", tId)
					} Else {
						Set pObject = $classmethod(tClass,"%New")
					}
					// FORMS - END - instantiate object by id
					
					Set p = $O(tPropValues(""))
					While (p'="") {
						If (p '= "_class") && (p '= "_id") {
							Try {
								// test for stream property
								Set tStream = $property(pObject,p)
								If ($IsObject(tStream) && (tStream.%Extends("%Stream.Object") || tStream.%Extends("%IO.I.Stream"))) {
									Do tStream.Rewind()
									Do tStream.Write($G(tPropValues(p)))
								}
								Else {
									Set $property(pObject,p) = $G(tPropValues(p))
								}
							}
							Catch ex {
								If $case(ex.Name, "<CANNOT SET THIS PROPERTY>" : 0, "<PROPERTY DOES NOT EXIST>": 'pIgnoreUnknownProps, :1) Throw ex
							}
						}
						Set p = $O(tPropValues(p))
					}
					Quit
				}
				ElseIf (ch = """") && ('tPropQuoted) {
					Set tPropQuoted = 1
				}
				ElseIf ('$$$WHITESPACE(ch) && (ch'="")) {
					// start of property name
					Set tToken = ch
					Set tState = 2
				}
			}
			ElseIf (tState = 2) {
				// property name
				If (ch = "\") {
					Set tState = "2a"
				}
				ElseIf (tPropQuoted) {
					If (ch = """") {
						Set tPropQuoted = 0
					}
					Else {
						Set:'$IsObject(tToken) tToken = tToken _ ch
					}
				}
				Else {
					If (ch = ":") {
						Set tProperty = tToken
						#; Set tProperty = $select($IsObject(tToken): tToken, 1: ..%UnescapeJSONString(tToken))
						Set tToken = ""
						Set tState = 3
						Set tIsString = 0
					}
					ElseIf ('$$$WHITESPACE(ch)) {
						Set:'$IsObject(tToken) tToken = tToken _ ch
					}
				}
			}
			// NOTE: States 2a, 2b and 2c are defined as the last few states as we expect escaped property names to be very rare
			ElseIf (tState = 3) {
				// value
				If (ch = ",") {
					// end of value
					If (tIsString || $IsObject(tToken)) {
						Set tValue = tToken
					}
					Else {
						Set tValue = $Case(tToken,"null":"","true":1,"false":0,:+tToken)
					}
					If (tProperty '= "") {
						Set tPropValues(tProperty) = tValue
					}
					Set pClass = $G(tPropValues("_class"),pClass)
					Set tToken = ""
					Set tValue = ""
					Set tState = 1
				}
				ElseIf (ch = "}") {
					// end of value and object
					If (tIsString || $IsObject(tToken)) {
						Set tValue = tToken
					}
					Else {
						Set tValue = $Case(tToken,"null":"","true":1,"false":0,:+tToken)
					}
					If (tProperty '= "") {
						Set tPropValues(tProperty) = tValue
					}

					// create object, stuff properties into it
					Set pClass = $G(tPropValues("_class"),pClass)
					Set tClass = $G(tPropValues("_class"),tClass)
					
					// FORMS - instantiate object by id
					Set tId = $G(tPropValues("_id"))
					
					If tId'="" {
						Set pObject = $classmethod(tClass,"%OpenId", tId)
						If ((##class(Form.Info).formExists(pObject.%ClassName(1))) && ('..CanModify(pObject, pLevel))) {
							/// FORMS - object is a form, but not a base form
							/// so we open it and that's it
							/// CanModify method can be affected by canModify setting
							Quit
						}
					} Else {
						Set pObject = $classmethod(tClass,"%New")
					}
					// FORMS - END - instantiate object by id

					Set p = $O(tPropValues(""))
					While (p'="") {
						If (p '= "_class") && (p '= "_id") {
							Try {
								// test for stream property
								Set tStream = $property(pObject,p)
								If ($IsObject(tStream) && (tStream.%Extends("%Stream.Object") || tStream.%Extends("%IO.I.Stream"))) {
									Do tStream.Rewind()
									Do tStream.Write($G(tPropValues(p)))
								} ElseIf ($IsObject(tStream) && tStream.%Extends("%Library.Persistent")) {
									// FORMS - set persistent properties
									If $IsObject($G(tPropValues(p))) {
										Set tStream = tPropValues(p)
									} Else {
										Set tStream = tStream.%OpenId($G(tPropValues(p)),,.st)
									}
									
									Set $property(pObject,p) = tStream
									// set relashonship
								} ElseIf ($$$comMemberKeyGet($classname(pObject),$$$cCLASSproperty,p,$$$cPROPrelationship)) {
									Set cardinality = $$$defMemberKeyGet($classname(pObject),$$$cCLASSproperty,p,$$$cPROPcardinality)
									
									If cardinality = "one" {
										Set $property(pObject,p) = tPropValues(p)
									} Else {
										// TODO: parent-child	
										#dim list As %Collection.ListOfObj
										Set list = tPropValues(p)
										For i = 1:1:list.Count() {
											Do $method($property(pObject,p),"Insert",list.GetAt(i))
										}
									}							
								}Else {
									// set datatypes
									Set tPropClassName = ##class(Form.Property).getPropertyType($classname(pObject), p)
									Set $property(pObject,p) = ##class(Form.Util.Converter).jsonToLogical(tPropClassName, $G(tPropValues(p)))
									// FORMS - END - set persistent properties
								}
							}
							Catch ex {
								If $case(ex.Name, "<CANNOT SET THIS PROPERTY>": 0, "<PROPERTY DOES NOT EXIST>": 'pIgnoreUnknownProps, :1) Throw ex
							}
						}
						Set p = $O(tPropValues(p))
					}
					Set tToken = ""
					Set tValue = ""
					Quit
				}
				ElseIf (ch = "{") {
					// start of object-valued property
					Set pClass = $G(tPropValues("_class"),pClass)

					If ((pClass="")||(tProperty="")) {
						Set tChildClass = ""
						Set tCollection = ""
					}
					Else {
						// lookup type in meta data
						Set tChildClass = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tProperty,$$$cPROPtype)
						Set tCollection = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tProperty,$$$cPROPcollection)
					}
					// Note: This if block assumes pClass and tProperty are defined when tCollection '= ""
					If (tCollection = "array") {
						// start of array-valued property
						Set tArrayType = "array"
						Set tArrayKey = ""
						Set tInArray = 1
						Kill tArray
						Set tToken = ""
						Set tIsString = 0
						Set tState = 5
						Set tArrayState = "name"

						// look up the runtime type of the array
						// set tCollectionClass to the runtime type if the runtime type is not in %Library or %Collection
						Set tCollectionClass = ""
						Set tArrayRuntimeType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tProperty,$$$cPROPruntimetype)
						If (tArrayRuntimeType '= "") {
							Set tArrayRuntimePackage = $piece(tArrayRuntimeType,".",1)
							If (tArrayRuntimePackage '= "%Library") && (tArrayRuntimePackage '= "%Collection") {
								Set tCollectionClass = tArrayRuntimeType
							}
						}
					}
					Else {
						If ($IsObject(pJSON)) {
							Set tSubJSON = pJSON
							Set tPoke = ch  // simulate stream unwind
						}
						Else {
							Set tSubJSON = $E(pJSON,p-1,*)
							Set tPoke = ""
						}
						Set tSC = ..%ParseJSON(tSubJSON,tChildClass,.tToken,.tChars,pLevel+1,tPoke,pIgnoreUnknownProps)
						If $$$ISERR(tSC) Quit
						Set p = p + tChars - 1
						Set pCharsProcessed = pCharsProcessed + tChars - 1
					}
				}
				ElseIf (ch = "[") {
					Set tCollectionClass = ""
					If ((pClass'="")&&(tProperty'="")) {
						// lookup type in meta data
						// we could have a normal collection: List Of PropType
						// OR
						// the proptype could be a subclass of a collection
						Set tCollectionClass = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tProperty,$$$cPROPtype)
						If (tCollectionClass '= "") && (($$$comClassKeyGet(tCollectionClass,$$$cCLASSclasstype)="datatype") || '$classmethod(tCollectionClass,"%Extends","%Collection.AbstractIterator")) {
							// use "built-in" collection
							Set tCollectionClass = ""
						}
					}

					// start of list/array-valued property
					Set tInArray = 1
					Set tArrayType = "list"
					Kill tArray
					Set tArrayIndex = 0
					Set tToken = ""
					Set tIsString = 0
					Set tState = 5
					Set tArrayState = "value"
				}
				ElseIf ((ch = """")||(ch = "'")) {
					// start of string
					Set tToken = ""
					Set tIsString = 1
					Set tQuote = ch
					Set tState = 4
				}
				ElseIf ('$$$WHITESPACE(ch)) {
					// must be a numeric value, or true,false,or null
					Set:'$IsObject(tToken) tToken = tToken _ ch
				}
			}
			ElseIf (tState = 4) {
				// string literal
				If (ch = "\") {
					// escape?
					Set tState = "4a"
				}
				ElseIf (ch = tQuote) {
					// end of string
					If (tInArray) {
						Set tState = 5
					}
					Else {
						Set tState = 3
					}
				}
				Else {
					Set:'$IsObject(tToken) tToken = tToken _ ch
				}
			}
			// NOTE: States 4a, 4b and 4c are defined *after* state 5 as we expect escaped text less often than arrays (state 5)
			ElseIf (tState = 5) {
				// array items
				If (ch = ",") {
					// end of array item
					If (tArrayType = "list") {
						Set tArrayIndex = tArrayIndex + 1
					}
					If (tIsString || $IsObject(tToken)) {
						Set tValue = tToken
					}
					Else {
						Set tValue = $Case(tToken,"null":"","true":1,"false":0,:+tToken)
					}
					If (tArrayType = "list") {
						Set tArray(tArrayIndex) = tValue
					}
					ElseIf (tArrayKey'="") {
						Set tArray(tArrayKey) = tValue
					}
					Set tToken = ""
					Set tArrayKey = ""
					Set tIsString = 0
					If (tArrayType = "list") {
						Set tArrayState = "value"
					}
					Else {
						Set tArrayState = "name"
					}
				}
				ElseIf ((tArrayType="list")&&(ch = "]")) {
					// end of list array
					If (tToken '= "") {
						Set tArrayIndex = tArrayIndex + 1
						If (tIsString || $IsObject(tToken)) {
							Set tValue = tToken
						}
						Else {
							Set tValue = $Case(tToken,"null":"","true":1,"false":0,:+tToken)
						}
						Set tArray(tArrayIndex) = tValue
					}

					If ($G(tCollectionClass)'="") {
						Set tListObj = $classmethod(tCollectionClass,"%New")
					}
					Else {
						#; Look for first non-"" value to determine whether the list contains objects or datatypes
						Set tUseObjectArray = 1
						Set n = $O(tArray(""))
						While n {
							If $IsObject($G(tArray(n))) Quit
							If ($G(tArray(n)) '= "") {
								Set tUseObjectArray = 0
								Quit
							}
							Set n = $O(tArray(n))
						}
						Set tListObj = $select(tUseObjectArray: ##class(%Library.ListOfObjects).%New(), 1: ##class(%Library.ListOfDataTypes).%New())
					}
					Set tCollectionClass = ""
					Set n = $O(tArray(""))
					While (n'="") {
						Do tListObj.Insert(tArray(n))
						Set n = $O(tArray(n))
					}

					Set tToken = tListObj
					Set tListObj = ""
					Set tInArray = 0
					Kill tArray
					Set tArrayIndex = 0
					Set tState = 3
					If tJSONArray {
						Set pObject = tToken
						Set tJSONArray = 0
						Quit
					}
				}
				ElseIf ((tArrayType="array")&&(ch = "}")) {
					// end of array
					If (tToken '= "") {
						If (tIsString || $IsObject(tToken)) {
							Set tValue = tToken
						}
						Else {
							Set tValue = $Case(tToken,"null":"","true":1,"false":0,:+tToken)
						}
						If (tArrayKey'="") {
							Set tArray(tArrayKey) = tValue
						}
					}

					If ($G(tCollectionClass)'="") {
						Set tArrayObj = $classmethod(tCollectionClass,"%New")
					}
					Else {
						Set tUseObjectArray = 1
						Set n = $O(tArray(""))
						While n '= "" {
							If $IsObject($G(tArray(n))) Quit
							If ($G(tArray(n)) '= "") {
								Set tUseObjectArray = 0
								Quit
							}
							Set n = $O(tArray(n))
						}
						Set tArrayObj = $select(tUseObjectArray: ##class(%Library.ArrayOfObjects).%New(), 1: ##class(%Library.ArrayOfDataTypes).%New())
					}
					Set tCollectionClass = ""

					Set n = $O(tArray(""))
					While (n'="") {
						Do tArrayObj.SetAt(tArray(n),n)
						Set n = $O(tArray(n))
					}

					Set tToken = tArrayObj
					Set tArrayObj = ""
					Set tInArray = 0
					Kill tArray
					Set tArrayIndex = 0
					Set tArrayKey = ""
					Set tState = 3
				}
				ElseIf (ch = "{") {
					// object-valued item: token is the object
					If (pClass'="") && (tProperty="") && $classmethod(pClass,"%Extends","%Library.ListOfObjects") {
						Set tPropElementType = $parameter(pClass,"ELEMENTTYPE")
						Set tChildClass = $select(tPropElementType = "%RegisteredObject": "", 1: tPropElementType)
					}
					ElseIf ((pClass="")||(tProperty="")) {
						Set tChildClass = ""
					}
					Else {
						// lookup type in meta data
						If (tCollectionClass="") {
							// property types tells us the type of items in the collection
							Set tChildClass = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tProperty,$$$cPROPtype)
						}
						Else {
							// we have to get the element type from the collection class
							Set tChildClass = $parameter(tCollectionClass,"ELEMENTTYPE")
						}
					}
					If ($IsObject(pJSON)) {
						Set tSubJSON = pJSON
						Set tPoke = ch  // simulate stream unwind
					}
					Else {
						Set tSubJSON = $E(pJSON,p-1,*)
						Set tPoke = ""
					}
						
					Set tSC = ..%ParseJSON(tSubJSON,tChildClass,.tToken,.tChars,pLevel+1,tPoke,pIgnoreUnknownProps)
					If $$$ISERR(tSC) Quit
					Set p = p + tChars - 1
					Set pCharsProcessed = pCharsProcessed + tChars - 1
				}
				ElseIf (ch = "[") {
					If ((pClass="")||(tProperty="")) {
						Set tChildCollectionClass = ""
					}
					Else {
						Set tChildCollectionClass = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tProperty,$$$cPROPtype)
						If (tChildCollectionClass '= "") && (($$$comClassKeyGet(tCollectionClass,$$$cCLASSclasstype)="datatype") || '$classmethod(tCollectionClass,"%Extends","%Collection.AbstractIterator")) {
							// use "built-in" collection
							Set tChildCollectionClass = ""
						}
					}
					If ($IsObject(pJSON)) {
						Set tSubJSON = pJSON
						Set tPoke = ch  // simulate stream unwind
					}
					Else {
						Set tSubJSON = $E(pJSON,p-1,*)
						Set tPoke = ""
					}
					Set tSC = ..%ParseJSON(tSubJSON,tChildCollectionClass,.tToken,.tChars,pLevel+1,tPoke,pIgnoreUnknownProps)
					If $$$ISERR(tSC) Quit
					Set p = p + tChars - 1
					Set pCharsProcessed = pCharsProcessed + tChars - 1
				}
				ElseIf ((ch = """")||(ch = "'")) {
					// start of string
					Set tToken = ""
					Set tIsString = 1
					Set tQuote = ch
					Set tState = 4
				}
				ElseIf ((tArrayType="array")&&(ch=":")) {
					// end of name
					If (tArrayState = "name") {
						Set tArrayState = "value"
						Set tArrayKey = tToken
						Set tToken = ""
					}
				}
				ElseIf ('$$$WHITESPACE(ch)) {
					// literal
					Set:'$IsObject(tToken) tToken = tToken _ ch
				}
			}
			// NOTE: States 4a, 4b and 4c precede states 2a, 2b and 2c as we expect literal strings to need escaping more often than property names
			ElseIf (tState = "4a") {
				// \ in string
				If (ch = "u") {
					Set tUnicodeHex = ""
					Set tState = "4b"
				}
				// add special case support for \xNN escape sequences that are valid in Javascript
				ElseIf (ch = "x") {
					Set tHex = ""
					Set tState = "4c"
				}
				Else {
					// Support escape sequences defined in RFC 4627, as well as \'
					Set tToken = tToken _ $Case(ch, "\": "\", "'": "'", """": """", "/": "/", "b": $char(8), "f": $char(12), "n": $char(10), "r": $char(13), "t": $char(9), : "\" _ ch)
					Set tState = 4
				}
			}
			ElseIf (tState = "4b") {
				// in \uXXXX escape sequence
				Set tUnicodeHex = tUnicodeHex _ ch
				If ($length(tUnicodeHex) = 4) {
					// Check that we do actually have a Hex value
					If $$$MATCHHEXCHARS(tUnicodeHex,4) {
						Set tUnicodeDecimal = $zhex(tUnicodeHex)
						Set tToken = tToken _ $char(tUnicodeDecimal)
					}
					Else {
						Set tToken = tToken _ "\u" _ tUnicodeHex
					}
					Set tState = 4
				}
			}
			ElseIf (tState = "4c") {
				// in \xNN escape sequence
				Set tHex = tHex _ ch
				If ($length(tHex) = 2) {
					// Check that we do actually have a Hex value
					If $$$MATCHHEXCHARS(tHex,2) {
						Set tCodeDecimal = $zhex(tHex)
						Set tToken = tToken _ $char(tCodeDecimal)
					}
					Else { // Not a hex escape
						Set tToken = tToken _ "\x" _ tHex
					}
					Set tState = 4
				}
			}
			ElseIf (tState = "2a") {
				// \ in property name
				If (ch = "u") {
					Set tUnicodeHex = ""
					Set tState = "2b"
				}
				// add special case support for \xNN escape sequences that are valid in Javascript
				ElseIf (ch = "x") {
					Set tHex = ""
					Set tState = "2c"
				}
				Else {
					// Support escape sequences defined in RFC 4627, as well as \'
					Set tToken = tToken _ $Case(ch, "\": "\", "'": "'", """": """", "/": "/", "b": $char(8), "f": $char(12), "n": $char(10), "r": $char(13), "t": $char(9), : "\" _ ch)
					Set tState = 2
				}
			}
			ElseIf (tState = "2b") {
				// in \uXXXX escape sequence
				Set tUnicodeHex = tUnicodeHex _ ch
				If ($length(tUnicodeHex) = 4) {
					#; Check that we do actually have a Hex value
					If $$$MATCHHEXCHARS(tUnicodeHex,4) {
						Set tUnicodeDecimal = $zhex(tUnicodeHex)
						Set tToken = tToken _ $char(tUnicodeDecimal)
					}
					Else {
						Set tToken = tToken _ "\u" _ tUnicodeHex
					}
					Set tState = 2
				}
			}
			ElseIf (tState = "2c") {
				// in \xNN escape sequence
				Set tHex = tHex _ ch
				If ($length(tHex) = 2) {
					#; Check that we do actually have a Hex value
					If $$$MATCHHEXCHARS(tHex,2) {
						Set tCodeDecimal = $zhex(tHex)
						Set tToken = tToken _ $char(tCodeDecimal)
					}
					Else { // Not a hex escape
						Set tToken = tToken _ "\x" _ tHex
					}
					Set tState = 2
				}
			}
		}
	}
	Catch ex {
		// Do ..%WriteJSONToFile(pJSON,"jsonout.txt")
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
