nextflow.enable.dsl=2

include { poc } from "./target/nextflow/poc/main.nf" params(params)

workflow run_main {
    main:
    input_one = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_rna.h5ad")
    input_multi = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_mod2.h5ad")
    
    output_ = input_one
      | combine(input_multi)

      | poc(
          publish: false,
          map: { ["foo", [ "input_one": it[0], "input_multi": it[1], "string": it[0].name ] ] }
        )

      | poc(
          publish: true,
          publishDir: "output",
          map: { [it[0], [ "input_one": it[1].output_one, "input_multi": it[1].output_multi, "integer": 456, "double": 0.456 ]] },
          key: "poc2" // setting a key allows you to run the same component twice
        )

    emit: output_
}
