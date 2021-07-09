nextflow.enable.dsl=2

include  { normalize }               from "./normalize/main.nf"                          params(params)

workflow test {
    main:
    rna = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_rna.h5ad")
    mod2 = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_mod2.h5ad")
    
    output_ = rna
      | combine(mod2) 
      | map { [ "test", [ input_rna: it[0], input_mod2: it[1] ], params ] }
      | view { [ "DEBUG1", it[0], it[1] ] }
      | normalize
      | view { [ "DEBUG2", it[0], it[1] ] }
      
    emit: output_
}
