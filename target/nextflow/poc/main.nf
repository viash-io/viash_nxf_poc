nextflow.enable.dsl=2

def fun = [
  "name": "poc",
  "container": "poc",
  "containerTag": "latest",
  "containerRegistry": "",
  "command": "poc",
  "arguments": [
    "input_one": [
      "name": "input_one",
      "otype": "--",
      "required": true,
      "type": "file",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "example": "input.txt",
      "ext": "txt",
      "description": "Input one."
    ],
    "input_multi": [
      "name": "input_multi",
      "otype": "--",
      "required": true,
      "type": "file",
      "direction": "Input",
      "multiple": true,
      "multiple_sep": ":",
      "example": "input.txt",
      "ext": "txt",
      "description": "Input multiple."
    ],
    "input_opt2": [
      "name": "input_opt2",
      "otype": "--",
      "required": false,
      "type": "file",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "example": "input.txt",
      "ext": "txt",
      "description": "Input optional."
    ],
    "output_one": [
      "name": "output_one",
      "otype": "--",
      "required": true,
      "type": "file",
      "direction": "Output",
      "multiple": false,
      "multiple_sep": ":",
      "example": "output.txt",
      "ext": "txt",
      "description": "Output one."
    ],
    "output_multi": [
      "name": "output_multi",
      "otype": "--",
      "required": true,
      "type": "file",
      "direction": "Output",
      "multiple": true,
      "multiple_sep": ":",
      "example": "output.txt",
      "ext": "txt",
      "description": "Output multiple."
    ],
    "output_opt2": [
      "name": "output_opt2",
      "otype": "--",
      "required": false,
      "type": "file",
      "direction": "Output",
      "multiple": false,
      "multiple_sep": ":",
      "example": "output.txt",
      "ext": "txt",
      "description": "Output optional."
    ],
    "string": [
      "name": "string",
      "otype": "--",
      "required": false,
      "type": "string",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "default": "A string",
      "description": "String"
    ],
    "integer": [
      "name": "integer",
      "otype": "--",
      "required": false,
      "type": "integer",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "default": "10",
      "description": "Integer"
    ],
    "double": [
      "name": "double",
      "otype": "--",
      "required": false,
      "type": "double",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "default": "5.5",
      "description": "Double"
    ],
    "flag_true": [
      "name": "flag_true",
      "otype": "--",
      "required": false,
      "type": "boolean_true",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "default": "false",
      "description": "Flag true"
    ],
    "flag_false": [
      "name": "flag_false",
      "otype": "--",
      "required": false,
      "type": "boolean_false",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "default": "true",
      "description": "Flag false"
    ],
    "boolean": [
      "name": "boolean",
      "otype": "--",
      "required": false,
      "type": "boolean",
      "direction": "Input",
      "multiple": false,
      "multiple_sep": ":",
      "default": "true",
      "description": "Boolean"
    ]
  ]
]

/*
// A function to verify (at runtime) if all required arguments are effectively provided.
def checkParams(_params) {
  _params.arguments.collect{
    if (it.value == "viash_no_value") {
      println("[ERROR] option --${it.name} not specified in component poc")
      println("exiting now...")
        exit 1
    }
  }
}
def renderCLI(command, arguments) {

  def argumentsList = arguments.collect{ it ->
    (it.otype == "")
      ? "\'" + escape(it.value) + "\'"
      : (it.type == "boolean_true")
        ? it.otype + it.name
        : (it.value == "no_default_value_configured")
          ? ""
          : it.otype + it.name + " \'" + escape((it.value in List && it.multiple) ? it.value.join(it.multiple_sep): it.value) + "\'"
  }

  def command_line = command + argumentsList

  return command_line.join(" ")
}
def effectiveContainer(processParams) {
  def _registry = params.containsKey("containerRegistry") ? params.containerRegistry : processParams.containerRegistry
  def _name = processParams.container
  def _tag = params.containsKey("containerTag") ? params.containerTag : processParams.containerTag

  return (_registry == "" ? "" : _registry + "/") + _name + ":" + _tag
}
def escape(str) {
  return str.replaceAll('\\\\', '\\\\\\\\').replaceAll("\"", "\\\\\"").replaceAll("\n", "\\\\n").replaceAll("`", "\\\\`")
}

// Use the params map, create a hashmap of the filenames for output
// output filename is <sample>.<method>.<arg_name>[.extension]
def outFromIn(_params) {

  def id = _params.id

  _params
    .arguments
    .findAll{ it -> it.type == "file" && it.direction == "Output" }
    .collect{ it ->
      // If an 'example' attribute is present, strip the extension from the filename,
      // If a 'dflt' attribute is present, strip the extension from the filename,
      // Otherwise just use the option name as an extension.
      def extOrName =
        (it.example != null)
          ? it.example.split(/\./).last()
          : (it.dflt != null)
            ? it.dflt.split(/\./).last()
            : it.name
      // The output filename is <sample> . <modulename> . <extension>
      // Unless the output argument is explicitly specified on the CLI
      def newValue =
        (it.value == "viash_no_value")
          ? "poc." + it.name + "." + extOrName
          : it.value
      def newName =
        (id != "")
          ? id + "." + newValue
          : it.name + newValue
      it + [ value : newName ]
    }

}
*/


def overrideIO(_params, inputs, outputs) {

  // `inputs` in fact can be one of:
  // - `String`,
  // - `List[String]`,
  // - `Map[String, String | List[String]]`
  // Please refer to the docs for more info
  def overrideArgs = _params.arguments.collect{ it ->
    if (it.type == "file") {
      if (it.direction == "Input") {
        (inputs in List || inputs in HashMap)
          ? (inputs in List)
            ? it + [ "value" : inputs.join(it.multiple_sep)]
            : (inputs[it.name] != null)
              ? (inputs[it.name] in List)
                ? it + [ "value" : inputs[it.name].join(it.multiple_sep)]
                : it + [ "value" : inputs[it.name]]
              : it
          : it + [ "value" : inputs ]
      } else {
        (outputs in List || outputs in HashMap)
          ? (outputs in List)
            ? it + [ "value" : outputs.join(it.multiple_sep)]
            : (outputs[it.name] != null)
              ? (outputs[it.name] in List)
                ? it + [ "value" : outputs[it.name].join(it.multiple_sep)]
                : it + [ "value" : outputs[it.name]]
              : it
          : it + [ "value" : outputs ]
      }
    } else {
      it
    }
  }

  def newParams = _params + [ "arguments" : overrideArgs ]

  return newParams

}

process poc_process {


  tag "${id}"
  echo { (params.debug == true) ? true : false }
  cache 'deep'
  stageInMode "symlink"
  container "${container}"
  publishDir "${params.publishDir}/${id}/", mode: 'copy', overwrite: true, enabled: !params.test
  input:
    tuple val(id), path(input), val(output), val(container), val(cli), val(_params)
  output:
    tuple val("${id}"), path(output)
  stub:
    """
    # Adding NXF's `$moduleDir` to the path in order to resolve our own wrappers
    export PATH="${moduleDir}:\$PATH"
    STUB=1 $cli
    """
  script:
    """
    # Some useful stuff
    export NUMBA_CACHE_DIR=/tmp/numba-cache
    # Running the pre-hook when necessary
    # Adding NXF's `$moduleDir` to the path in order to resolve our own wrappers
    export PATH="${moduleDir}:\$PATH"
    $cli
    """
}

workflow poc {

  take:
  id_input_params_

  main:

  def key = "poc"

  def id_input_output_function_cli_params_ =
    id_input_params_.map{ id, input, _params ->

      // Start from the (global) params and overwrite with the (local) _params
      def defaultParams = params[key] ? params[key] : [:]
      def overrideParams = _params[key] ? _params[key] : [:]
      def updtParams = defaultParams + overrideParams
      // Convert to List[Map] for the arguments
      def newParams = argumentsAsList(updtParams) + [ "id" : id ]

      // Generate output filenames, out comes a Map
      def output = outFromIn(newParams)

      // The process expects Path or List[Path], Maps need to be converted
      def inputsForProcess =
        (input in HashMap)
          ? input.collect{ k, v -> v }.flatten()
          : input
      def outputsForProcess = output.collect{ it.value }

      // For our machinery, we convert Path -> String in the input
      def inputs =
        (input in List || input in HashMap)
          ? (input in List)
            ? input.collect{ it.name }
            : input.collectEntries{ k, v -> [ k, (v in List) ? v.collect{it.name} : v.name ] }
          : input.name
      outputs = output.collectEntries{ [(it.name): it.value] }

      def finalParams = overrideIO(newParams, inputs, outputs)

      checkParams(finalParams)

      new Tuple6(
        id,
        inputsForProcess,
        outputsForProcess,
        effectiveContainer(finalParams),
        renderCLI([finalParams.command], finalParams.arguments),
        finalParams
      )
    }

  result_ = poc_process(id_input_output_function_cli_params_) \
    | join(id_input_params_) \
    | map{ id, output, _params, input, original_params ->
        def parsedOutput = _params.arguments
          .findAll{ it.type == "file" && it.direction == "Output" }
          .withIndex()
          .collectEntries{ it, i ->
            // with one entry, output is of type Path and array selections
            // would select just one element from the path
            [(it.name): (output in List) ? output[i] : output ]
          }
        new Tuple3(id, parsedOutput, original_params)
      }

  result_ \
    | filter { it[1].keySet().size() > 1 } \
    | view{
        ">> Be careful, multiple outputs from this component!"
    }

  emit:
  result_.flatMap{ it ->
    (it[1].keySet().size() > 1)
      ? it[1].collect{ k, el -> [ it[0], [ (k): el ], it[2] ] }
      : it[1].collect{ k, el -> [ it[0], el, it[2] ] }
  }
}


