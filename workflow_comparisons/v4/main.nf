nextflow.enable.dsl=2

include { poc } from "./target/nextflow/poc/main.nf" params(params)
include { poc2 } from "./target/nextflow/poc/main.nf" params(params)

workflow run_main {
    main:
    input_one = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_rna.h5ad")
    input_multi = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_mod2.h5ad")
    
    output_ = input_one
      | combine(input_multi)

      | map{ [ "input", [ input_one: it[0], input_multi: it[1], string: it[0].name ] ] }
      | poc
      // returns: [ id, [ output_one:   xxx, output_multi: xxx ] ]

      | map { id, data -> [ id, [ input_one: data.output_one, input_multi: data.output_multi ] ]}
      | poc2 

      // problem 5: can't change component settings from within pipeline. Examples:
      //   * whether to publish or not
      //   * which publishDir to use
      //   * which publishMode to use

      // problem 6: can't use the same module twice

    emit: output_
}
