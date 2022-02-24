nextflow.enable.dsl=2

include { poc } from "./target/nextflow/poc_new/main.nf" params(params)

tupleOutToTupleIn = { [ input_one: it[1].output_one, input_multi: it[1].output_multi ] }

workflow run_main {
    main:
    input_duplicate = Channel.from([1,2,3])
    input_one = Channel.fromPath("run.sh")
    input_multi = Channel.fromPath(".gitignore")
    input_opt = Channel.fromPath("README.md")

    // TODO: test multiple inputs and outputs

    output_ = input_duplicate
      | combine(input_one)
      | combine(input_multi)
      | combine(input_opt)
      // | view{ "STEP0: " + it }
      | map{ ["foo" + it[0], [ input_one: it[1], input_multi: it[2], input_opt: it[3], string: "step 1" ], "step 2"] } // put step2 in passthrough
      | poc
      // | view{ "STEP1: " + it }
      | poc.run(
          key: "poc1", 
          map: { [
            it[0], 
            [ input_one: it[1].output_one, input_multi: it[1].output_multi, string: it[2] ], 
            it[1].output_opt
          ] } // put passthrough in string arg, put output_opt in passthrough
        )
      // | view{ "STEP2: " + it }
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
          map: { [ it[0], [ input_one: it[1].output_one, input_multi: it[1].output_multi, input_opt: it[2] ] ] }, // include passthrough in data tuple again
          args: [ string: "step 3", integer: 456, "double": 0.456 ]
        )
      | view{ "STEP3: " + it }
    emit: output_
}
