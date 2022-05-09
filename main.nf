nextflow.enable.dsl=2

 include { poc } from "./target/nextflowpoc/poc/main.nf" params(params)

workflow run_main {
    Channel.fromList(
        [
          [ 
            "foo",
            [
              input_one: file("nextflow.config"),
              input_multi: [ file("README.md"), file("run.sh") ], 
              input_opt: file("main.nf"),
              string: "foo"
            ]
          ],
          [ 
            "bar",
            [
              input_one: file("nextflow.config"),
              input_multi: [ file("README.md"), file("run.sh") ], 
              input_opt: file("main.nf"),
              string: "bar"
            ]
          ]
        ]
      )
      | view{ "STEP0: " + it }
      | poc.run(
          args: [ integer: 10 ],
          directives: [
            label: ["highmem", "highcpu"]
          ],
          // auto: [ publish: true, transcript: true ]
        )
      | view{ "STEP1: $it"}
      | poc.run(
          key: "poc2", 
          map: { [
            it[0], 
            [ input_one: it[1].output_one, input_multi: it[1].output_multi, string: it[2] ], 
            it[1].output_opt
          ] }, // put passthrough in string arg, put output_opt in passthrough
          // auto: [ publish: true ]
        )
      | view{ "STEP2: " + it }
      | poc.run(
          key: "poc3",
          directives: [
            publishDir: [
              [ path: "output/manual/", pattern: "*output_one*", mode: "copy", enabled: true, saveAs: "{ it + '.derp' }" ], // test closure workaround for saveas
              [ path: "output/manual/", pattern: "*output_multi*", mode: "copy", enabled: true ],
              [ path: "output/manual/", pattern: "*output_opt*", mode: "copy", enabled: true ] 
            ],
            cache: true,
            executor: "local",
            label: ["foo", "bar"],
            memory: "{ id == 'foo1' ? '10GB' : '5GB' }" // test workaround for closures
          ],
          // include passthrough in data tuple again
          // remove input_multi
          map: { [ it[0], [ input_one: it[1].output_one, input_multi: [], input_opt: it[2] ] ] },
          args: [ string: "step 3", integer: 456, "doubles": [0.456, .123] ],
          auto: [ publish: true ]
        )
      | view{ "STEP3: " + it }
}
