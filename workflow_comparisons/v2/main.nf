nextflow.enable.dsl=2

include { poc } from "./target/nextflow/poc/main.nf" params(params)
include { poc2 } from "./target/nextflow/poc/main.nf" params(params)

def flattenMap(entry) {
  res = [:]
  entry.each{it.each{ res[it.key] = it.value }}
  return res
}

workflow run_main {
    main:
    input_one = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_rna.h5ad")
    input_multi = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_mod2.h5ad")
    
    output_ = input_one
      | combine(input_multi)

      // problem 1: need to pass through params object to every pipeline object
      | map{ [ "input", [ input_one: it[0], input_multi: it[1], string: it[0].name ], params ] }
      | poc
      // returns: [ id, [ output_one:   xxx ], params ]
      // or       [ id, [ output_multi: xxx ], params ]

      // problem 3: processing components with multiple outputs requires many steps
      | groupTuple(sort: true, size: 2)
      | map { id, data, old_params -> [ id, flattenMap(data) ] }
      | map { id, data -> [ id, [ input_one: data.output_one, input_multi: data.output_multi ], params ]}
      | poc2 

      // problem 4: see nextflow.config

      // problem 5: can't change component settings from within pipeline. Examples:
      //   * whether to publish or not
      //   * which publishDir to use
      //   * which publishMode to use

      // problem 6: can't use the same module twice

    emit: output_
}
