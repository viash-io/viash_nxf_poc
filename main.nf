nextflow.enable.dsl=2

include { poc } from "./target/nextflow/poc/main.nf" params(params)

workflow run_main {
    main:
    input_one = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_rna.h5ad")
    input_multi = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_mod2.h5ad")
    
    output_ = input_one
      | combine(input_multi)
      | view{ "STEP0: " + it }
      | poc(
          directives: [ echo: false, maxForks: 1 ],
          // publish: false, // need to rework this
          // publishDir: "output",
          // publishMode: "symlink",
          map: { ["foo", [ input_one: it[0], input_multi: it[1], string: it[0].name ], "testpassthrough"] }
        )
      | view{ "STEP1: " + it }
      | poc(
          key: "poc2",
          // publish: true, // need to rework this
          // publishDir: "output",
          mapData: { [ input_one: it[1].output_one, input_multi: it[1].output_multi, string: it[2] ] },
          args: [ integer: 456, "double": 0.456 ]
        )
      | view{ "STEP2: " + it }
      
    emit: output_
}
