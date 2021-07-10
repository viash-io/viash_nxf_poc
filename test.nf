nextflow.enable.dsl=2


process test_process {
  tag { id }
  echo true
  cache 'deep'
  stageInMode "symlink"
  container { processArgs.container }
  publishDir { processArgs.publishDir }, mode: 'copy', overwrite: true, enabled: { processArgs.publish }
  input:
    tuple val(id), path(input), val(output), val(processArgs)
  output:
    tuple val(id), path(output)
  script:
    """
    echo publishEnabled: ${processArgs.publish}
    echo publishDir: ${processArgs.publishDir}
    echo container: ${processArgs.container}
    cat $input > $output
    """
}


def test_wf(Map args = [:]) {
  def defaultArgs = [publish: false, container: "bash:4.0", pre: { it -> it }]
  def args1 = defaultArgs << args

  workflow test_workflow {
    take:
      channel_in
    main:
      channel_out = channel_in
        //| map{ args1.pre(it) } // todo: doesn't work yet
        | map{ it -> 
            // TODO: check that all parameters are available
            [ it[0], it[1], "test_output.txt", args1 + [ publishDir: "test_output/${it[0]}" ] ]
          }
        | test_process
    emit: 
      channel_out
  }
  
  return test_workflow
}


workflow {
  Channel.fromPath("test.nf")
    | map { [ "foo", it ] }
    | view{ [ "DEBUG1", it ] }
    | test_wf(container: "rocker/tidyverse:4.0.5" )
    | view{ [ "DEBUG3", it ] }
}

