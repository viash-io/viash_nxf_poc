nextflow.enable.dsl=2

import nextflow.ast.NextflowDSLImpl

println(this)
println(this.processFactory)

println("test: ${NextflowDSLImpl.WORKFLOW_TAKE}")
// process test_process {
//   tag { id }
//   echo true
//   cache 'deep'
//   stageInMode "symlink"
//   maxForks "${println("processArgs at time of maxForks " + processArgs); 1}"
//   container { processArgs.container }
//   publishDir { processArgs.publishDir }, mode: 'copy', overwrite: true, enabled: { processArgs.publish }
//   input:
//     tuple val(id), path(input), val(output), val(arguments), val(processArgs)
//   output:
//     tuple val(id), path(output)
//   script:

//     println "processArgs: ${processArgs}"

//     """
//     echo "K: ${arguments.k}"
//     cat ${input} > ${output}
//     """
// }


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
	println obj.getProperties().toString()
}


printAllMethods(this)

// printAllMethods(test_process)
// printAllMethods(test_process.getProcessConfig())

// def f = test_process.getClass().getDeclaredField("taskBody")
// f.setAccessible(true)
// println "owner: ${test_process.owner}"
// println "processName: ${test_process.processName}"
// println "simpleName: ${test_process.simpleName}"
// println "baseName: ${test_process.baseName}"
// // println "rawBody: ${test_process.rawBody}"
// println "processConfig: ${test_process.processConfig}"
// println "taskBody: ${test_process.taskBody}"

process test_process {
  input:
    tuple val(id), path(input), val(output), val(arguments), val(processArgs)
  output:
    tuple val(id), path(output)
  script:
    """
    echo "K: ${arguments.k}"
    cat ${input} > ${output}
    """
}


def test_wf(Map args = [:]) {
  def defaultProcArgs = [publish: false, container: "bash:4.0", map: { it -> it }]
  def processArgs = defaultProcArgs + args

  tripQuo = "\"\"\""

  File file = File.createTempFile("temp",".tmp.nf")
  file.deleteOnExit()

  def proc_name = "test_process"

  file << """process ${proc_name} {
    input:
      tuple val(id), path(input), val(output), val(arguments), val(processArgs)
    output:
      tuple val(id), path(output)
    script:
      ${tripQuo}
      echo "K: \${arguments.k}"
      cat \${input} > \${output}
      ${tripQuo}
  }"""

  include { test_process } from file.absolutePath params(params)
  
  

  workflow test_workflow {
    take:
      channel_in
    main:
      println "processConfig2: ${test_process.processConfig}"


      channel_out = channel_in
        | map{ it -> 
          def defaultArgs = [ "output": "id.poc.output.txt", k: 10 ]
          def mappedTuple = processArgs.map(it)

          id = mappedTuple[0]
          arguments = defaultArgs + mappedTuple[1]
          processArgs = args + [ publishDir: "test_output/$id" ]
          
          processArgs.remove("map")
          
          return [ id, arguments.input, arguments.output, arguments, processArgs ]
        }
        | test_process


      println "processConfig3: ${test_process.processConfig}"
    emit: 
      channel_out
  }
  
  return test_workflow
}

//include { test_wf } from "target/nextflow/test_wf/main.nf" params(params)
def test = test_wf(container: "rocker/tidyverse:4.0.5")

workflow {
  Channel.fromPath("test.nf")
    | map { [ "foo", [ input: it ] ] }
    | view{ [ "DEBUG1", it ] }
    | test
    // | test2
    | view{ [ "DEBUG3", it ] }
}
