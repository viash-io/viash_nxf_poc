nextflow.enable.dsl=2

print("PARAMS1: ${params}")
print("")

include  { normalize }               from "./normalize2/main.nf"                          params(params)

print("PARAMS2: ${params}")
print("")

workflow test {
    main:
    rna = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_rna.h5ad")
    mod2 = Channel.fromPath("data/pbmc_1k_protein_v3.normalize.output_mod2.h5ad")
    
    output_ = rna
      | combine(mod2) 
      | map { [ "test", [ input_rna: it[0], input_mod2: it[1] ] ] }
      | view { [ "DEBUG1", it[0], it[1] ] }
      | normalize
      | view { [ "DEBUG2", it[0], it[1] ] }
      
    emit: output_
}

// | map { [ "test", [ input_rna: it[0], input_mod2: it[1] ], params ] }
