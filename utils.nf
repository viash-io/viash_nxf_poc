
void printAllMethods( obj ){
  if( !obj ){
		println( "Object is null\r\n" )
		return
  }
	if( !obj.metaClass && obj.getClass() ){
    printAllMethods( obj.getClass() )
		returns
  }
	def str = "class ${obj.getClass().name}\nfunctions:\n"
	obj.metaClass.methods.name.unique().each{ 
		str += it+"(); "
	}
	println "${str}\n"
	// println obj.getProperties().toString()
}
