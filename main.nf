nextflow.enable.dsl=2

include { poc } from "./target/nextflow/poc_new/main.nf" params(params)
// include { poc } from "./target/nextflow/poc/main.nf" params(params)
include { printAllMethods } from "./utils.nf"

// printAllMethods(poc)

workflow run_main {
    main:
    input_duplicate = Channel.from([1,2,3])
    input_one = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_rna.h5ad")
    input_multi = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_mod2.h5ad")

    output_ = input_duplicate
      | combine(input_one)
      | combine(input_multi)
      // | view{ "STEP0: " + it }
      | map{ ["foo" + it[0], [ input_one: it[1], input_multi: it[2], string: it[1].name ], "testpassthrough"] }
      | poc
      | poc.run(key: "poc1", mapData: { [ input_one: it[1].output_one, input_multi: it[1].output_multi, string: it[1] ] })
      | poc.run(key: "poc2", mapData: { [ input_one: it[1].output_one, input_multi: it[1].output_multi, string: it[1] ] })
      | poc.run(
          key: "poc3",
          directives: [
            publishDir: [
              [ path: "output/", pattern: "output_multi", mode: "copy", enabled: false ],
              [ path: "output/", pattern: "*output_one*", mode: "copy", enabled: true ]
            ]
          ],
          mapData: { [ input_one: it[1].output_one, input_multi: it[1].output_multi, string: it[1] ] },
          args: [ integer: 456, "double": 0.456 ]
        )
      // | view{ "STEP2: " + it }
    emit: output_
}
