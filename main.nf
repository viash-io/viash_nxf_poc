nextflow.enable.dsl=2

include { poc } from "./target/nextflow/poc_new/main.nf" params(params)

tupleOutToTupleIn = { [ input_one: it[1].output_one, input_multi: it[1].output_multi ] }

// TODO: add check for nxf version for opt & multiple outputs

workflow run_main {
    main:
    // TODO: test multiple inputs and outputs

    output_ = Channel.value(
        [ 
          "foo", // id
          [  // data
            input_one: file("run.sh"), 
            input_multi: [ file("README.md"), file("run.sh") ], 
            // input_multi: [ file("README.md"), file("utils.nf") ],
            // input_multi: [ file("README.md") ], 
            input_opt: file("main.nf"), 
            string: "step 1" 
          ],
          "step2" // passthrough
        ] 
      )
      | view{ "STEP0: " + it }
      | poc
      | view{ "STEP1: " + it }
      | poc.run(
          key: "poc2", 
          map: { [
            it[0], 
            [ input_one: it[1].output_one, input_multi: it[1].output_multi, string: it[2] ], 
            it[1].output_opt
          ] } // put passthrough in string arg, put output_opt in passthrough
        )
      | view{ "STEP2: " + it }
      | poc.run(
          key: "poc3",
          directives: [
            publishDir: [
              [ path: "output/", pattern: "*output_one*", mode: "copy", enabled: true, saveAs: "{ it + '.derp' }" ], // test closure workaround for saveas
              [ path: "output/", pattern: "*output_multi*", mode: "copy", enabled: true ],
              [ path: "output/", pattern: "*output_opt*", mode: "copy", enabled: true ] 
            ],
            cache: true,
            executor: "local",
            label: ["foo", "bar"],
            memory: "{ id == 'foo1' ? '10GB' : '5GB' }" // test workaround for closures
          ],
          // include passthrough in data tuple again
          // remove input_multi
          map: { [ it[0], [ input_one: it[1].output_one, input_multi: [], input_opt: it[2] ] ] },
          args: [ string: "step 3", integer: 456, "double": 0.456 ]
        )
      | view{ "STEP3: " + it }
    emit: output_
}
