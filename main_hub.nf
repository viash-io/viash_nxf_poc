nextflow.enable.dsl=2

method_a = Viash.include("myorg/myns/method_a")
method_b = Viash.include("myorg/myns/method_b")
method_c = Viash.include("myorg/myns/method_c")

workflow run_main {
    main:
    // TODO: test multiple inputs and outputs

    output_ = Channel.value(
        [ 
          "foo", // id
          [  // data
            input_one: file("run.sh"), 
            // input_multi: [ file("README.md"), file("run.sh") ], 
            input_multi: [ file("README.md") ], 
            input_opt: file("main.nf"), 
            string: "step 1" 
          ],
          "step2" // passthrough
        ] 
      )
      | method_a
      | method_b
      | method_c
      | view{ "STEP3: " + it }
    emit: output_
}
