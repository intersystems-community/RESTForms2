Include Form

/// Base form adaptor class, all forms must inherit from this class
Class Form.Adaptor Extends (Form.Security, Form.Generators) [ Abstract, CompileAfter = Form.Info, DependsOn = Form.Info, PropertyClass = Form.Field ]
{

/// Form name, not a global key so it can be anything
/// Set to empty string (like here) to not have a class as a form 
Parameter FORMNAME As %String;

/// Default permissions
/// Objects of this form can be Created, Read, Updated and Deleted
/// Redefine this parameter to change permissions for everyone
/// Redefine checkPermission method (see Form.Security) for this class 
/// to add custom security based on user/roles/etc.
Parameter OBJPERMISSIONS As %String = "CRUD";

/// Property used for basic information about the object
/// By default getObjectDisplayName method gets its value from it
Parameter DISPLAYPROPERTY As %String = "displayName";

/// Use value of this parameter in SQL, as ORDER BY clause value 
Parameter FORMORDERBY As %String;

/// Выводит объект Id в формате JSON на текущее устройство
/// Переопределите этот метод для конкретной формы, если есть какие-то особенности её обработки
/// Возможно: заменить метод на генератор, который будет генерить код для формы
/// Подразумевается, что форма хранимая
ClassMethod toJSON(id As %Integer = "") As %Status
{
	#dim sc As %Status = $$$OK
	set obj = ..%OpenId(id,,.sc)
	return:$$$ISERR(sc) sc
	return ##class(Form.JSON.OBJ).%ObjectToJSON(obj,,,$$$formatJSON)
}

/// Открывает объект по Id и перезаписывает все его свойства 
/// соответствующими значениями из object 
/// После чего сохраняет объект
ClassMethod updateIdFromObject(id As %Integer = "", object = "") As %Status
{
	#dim sc As %Status = $$$OK
	return:'$isObject(object) $$$ERROR($$$GeneralError, "Pass an object as a second argument to updateIdFromObject from " _ $className())
	set obj = ..%OpenId(id,,.sc)
	return:$$$ISERR(sc) sc
	set sc = obj.updateFromObject(object)
	return:$$$ISERR(sc) sc
	set sc = obj.%Save()
	return sc
}

/// Устанавливает все поля текущего объекта из переданного объекта
/// Это может быть динамический объект или объект того же класса
Method updateFromObject(object) As %Status [ CodeMode = objectgenerator ]
{
	for i = 1:1:%class.Properties.Count() {
        set prop = %class.Properties.GetAt(i)
        if prop.Internal || prop.Calculated || prop.ReadOnly || prop.Private || prop.Identity || prop.MultiDimensional continue
        
        // Вопросы:
        // 1. Что с объектами - в принципе
        // 2. Что со списками
        // 3. Пустые поля - пропускать или что делать? 
        // 4. Что с потоками
        do %code.WriteLine(" set .." _ prop.Name _ " = object." _ prop.Name)
    }
    do %code.WriteLine(" Quit $$$OK")
}

/// Get basic information about one object
ClassMethod getObjectInfo(id As %Integer) As %DynamicObject [ Abstract ]
{
	set item = {}
	set item."_id" = id
	set item.displayName = ..getObjectDisplayName(id)
	return item
}

/// Get basic information about several form objects.<br>
/// <var>list</var> - contains objects ids (not oids)
ClassMethod getObjectsInfo(list As %ListOfDataTypes) As %DynamicArray
{
	set objectsList = []
	for i=1:1:list.Count() {
		set id = list.GetAt(i)
		set item = ..getObjectInfo(id)
		do objectsList.%Push(item)
	}
	return objectsList
}

/// Get value of a property specified in DISPLAYPROPERTY parameter.
/// If it is stored, then GetStored value would be taken
/// If it is calculated, then the object would be opened and the value would be calculated
/// Redefine to implement your custom logic. 
/// Note, that if you redefine this method, it must be availible as an sql procedure and would be used as a display property.
/// Also remenber to limit result length to 250-490 symbols depending on a collation in use. 
ClassMethod getObjectDisplayName(id As %Integer) As %String(MAXLEN=250) [ CodeMode = objectgenerator, GenerateAfter = generateMetadata, SqlProc ]
{
	#Include Form
	#dim sc As %Status = $$$OK
	set className = %compiledclass.Name
	set formName = %parameter($$$formNameParam)
	return:((className="Form.Adaptor")||(formName="")) sc
	
	set propName = %parameter($$$displayProp)
	set key = %compiledclass.Properties.FindObjectId(className _ "||" _ propName)
	return:key="" $$$ERROR($$$GeneralError, "Display property '" _ propName _"' does not exist in '" _ className _ "' class. Redefine " _ $$$displayProp _ " parameter")
	
	#dim prop As %Dictionary.CompiledProperty
	set prop = %compiledclass.Properties.GetAt(key)
	
	if ((prop.Calculated = $$$YES) || (prop.Transient = $$$YES)) {
		do %code.WriteLine(" set obj = ..%OpenId(id)")
		do %code.WriteLine(" return obj." _ propName)
	} else {
		do %code.WriteLine(" return .." _ propName _ "GetStored(id)")
	}
		
	quit sc
}

}
