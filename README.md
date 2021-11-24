## POC: new Viash-NXF plugin

This is a proof of concept containing a few experimental components in order to implement a new Viash+Nextflow platform plugin.

Some initial files were generated by running:

```
viash build src/poc/config.vsh.yaml -p docker -o target/docker/poc --setup cb
viash build src/poc/config.vsh.yaml -p native -o target/native/poc
viash build src/poc/config.vsh.yaml -p nextflow -o target/nextflow_orig/poc
```

Directory `component_comparisons` contains an incremental process of how the original viash+nextflow platform is modified step by step in order to make it more dynamic and more practical.

If all goes well, the pipeline should be runnable by running `./run.sh`.
