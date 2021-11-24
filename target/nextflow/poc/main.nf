nextflow.enable.dsl=2

import nextflow.script.IncludeDef
import nextflow.script.ScriptBinding
import nextflow.script.ScriptMeta


// replace $ with {} or %%
fun = [
  'name': 'poc',
  'container': 'poc',
  'containerTag': 'latest',
  'containerRegistry': '',
  'arguments': [
    [
      'name': 'input_one',
      'otype': '--',
      'required': true,
      'type': 'file',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'example': 'input.txt',
      'ext': 'txt',
      'description': 'Input one.'
    ],
    [
      'name': 'input_multi',
      'otype': '--',
      'required': true,
      'type': 'file',
      'direction': 'Input',
      'multiple': true,
      'multiple_sep': ':',
      'example': 'input.txt',
      'ext': 'txt',
      'description': 'Input multiple.'
    ],
    [
      'name': 'input_opt',
      'otype': '--',
      'required': false,
      'type': 'file',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'example': 'input.txt',
      'ext': 'txt',
      'description': 'Input optional.'
    ],
    [
      'name': 'output_one',
      'otype': '--',
      'required': true,
      'type': 'file',
      'direction': 'Output',
      'multiple': false,
      'multiple_sep': ':',
      'example': 'output.txt',
      'default': '$id.$key.output_one.txt',
      'ext': 'txt',
      'description': 'Output one.'
    ],
    [
      'name': 'output_multi',
      'otype': '--',
      'required': true,
      'type': 'file',
      'direction': 'Output',
      'multiple': true,
      'multiple_sep': ':',
      'example': 'output.txt',
      'default': '$id.$key.output_multi.txt',
      'ext': 'txt',
      'description': 'Output multiple.'
    ],
    [
      'name': 'output_opt',
      'otype': '--',
      'required': false,
      'type': 'file',
      'direction': 'Output',
      'multiple': false,
      'multiple_sep': ':',
      'example': 'output.txt',
      'default': '$id.$key.output_default.txt',
      'ext': 'txt',
      'description': 'Output optional.'
    ],
    [
      'name': 'string',
      'otype': '--',
      'required': false,
      'type': 'string',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'default': 'A string',
      'description': 'String'
    ],
    [
      'name': 'integer',
      'otype': '--',
      'required': false,
      'type': 'integer',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'default': '10',
      'description': 'Integer'
    ],
    [
      'name': 'double',
      'otype': '--',
      'required': false,
      'type': 'double',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'default': '5.5',
      'description': 'Double'
    ],
    [
      'name': 'flag_true',
      'otype': '--',
      'required': false,
      'type': 'boolean_true',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'default': 'false',
      'description': 'Flag true'
    ],
    [
      'name': 'flag_false',
      'otype': '--',
      'required': false,
      'type': 'boolean_false',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'default': 'true',
      'description': 'Flag false'
    ],
    [
      'name': 'boolean',
      'otype': '--',
      'required': false,
      'type': 'boolean',
      'direction': 'Input',
      'multiple': false,
      'multiple_sep': ':',
      'default': 'true',
      'description': 'Boolean'
    ]
  ]
]




// TODO: solve container differently
defaultDirectives = [
  echo: false,
  key: "poc",
  label: null,
  labels: [],
  queue: null,
  publish: false, 
  publishDir: ".",
  publishMode: "copy",
  container: "rocker/tidyverse:4.0.5", 
]

defaultProcArgs = [
  key: fun['name'],
  directives: [],
  map: null,
  mapId: { it -> it[0] },
  mapData: { it -> it[1] },
  filter: { it -> true },
  mapOutput : {it -> it},
  filterOutput : {it -> true},
  args: [:]
]

def processArgsCheck(Map processArgs) {
  assert processArgs.containsKey("key")
  assert processArgs["key"] instanceof String
  assert processArgs["key"] ==~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
}

def processScript() {
  // TODO: check in viash whether script contains `'''` and escape

  // NOTE: in the native platform script, \ needs to be escaped to \\ for this to work
  // update: nevermind
  // NOTE: 'VIASHMAIN' needs to be replaced with VIASHMAIN
  // update: nevermind.

  // Use `val code = res.readWithPlaceholder(functionality).get` and
  // `BashWrapper.escapeViash(code)` to get the code below
  // don't forget to include $cdToResources$resourcesToPath as in BashWrapper.wrapScript
  
  /* NOTE: Assumes the following env variables are exported
   *  - VIASH_TEMP
   *  - VIASH_RESOURCES_DIR
   *  - VIASH_META_FUNCTIONALITY_NAME
   *  - VIASH_PAR_*
   */
  def out = '''
set -e
tempscript=".command_script.R"
cat > "$tempscript" << VIASHMAIN
# The following code has been auto-generated by Viash.
# get parameters from cli
par <- list(
  "input_one" = $( if [ ! -z ${VIASH_PAR_INPUT_ONE+x} ]; then echo "'$VIASH_PAR_INPUT_ONE'"; else echo NULL; fi ),
  "input_multi" = $( if [ ! -z ${VIASH_PAR_INPUT_MULTI+x} ]; then echo "strsplit('$VIASH_PAR_INPUT_MULTI', split = ':')[[1]]"; else echo NULL; fi ),
  "input_opt" = $( if [ ! -z ${VIASH_PAR_INPUT_OPT+x} ]; then echo "'$VIASH_PAR_INPUT_OPT'"; else echo NULL; fi ),
  "output_one" = $( if [ ! -z ${VIASH_PAR_OUTPUT_ONE+x} ]; then echo "'$VIASH_PAR_OUTPUT_ONE'"; else echo NULL; fi ),
  "output_multi" = $( if [ ! -z ${VIASH_PAR_OUTPUT_MULTI+x} ]; then echo "strsplit('$VIASH_PAR_OUTPUT_MULTI', split = ':')[[1]]"; else echo NULL; fi ),
  "output_opt" = $( if [ ! -z ${VIASH_PAR_OUTPUT_OPT+x} ]; then echo "'$VIASH_PAR_OUTPUT_OPT'"; else echo NULL; fi ),
  "string" = $( if [ ! -z ${VIASH_PAR_STRING+x} ]; then echo "'$VIASH_PAR_STRING'"; else echo NULL; fi ),
  "integer" = $( if [ ! -z ${VIASH_PAR_INTEGER+x} ]; then echo "as.integer($VIASH_PAR_INTEGER)"; else echo NULL; fi ),
  "double" = $( if [ ! -z ${VIASH_PAR_DOUBLE+x} ]; then echo "as.numeric($VIASH_PAR_DOUBLE)"; else echo NULL; fi ),
  "flag_true" = $( if [ ! -z ${VIASH_PAR_FLAG_TRUE+x} ]; then echo "as.logical(toupper('$VIASH_PAR_FLAG_TRUE'))"; else echo NULL; fi ),
  "flag_false" = $( if [ ! -z ${VIASH_PAR_FLAG_FALSE+x} ]; then echo "as.logical(toupper('$VIASH_PAR_FLAG_FALSE'))"; else echo NULL; fi ),
  "boolean" = $( if [ ! -z ${VIASH_PAR_BOOLEAN+x} ]; then echo "as.logical(toupper('$VIASH_PAR_BOOLEAN'))"; else echo NULL; fi )
)

# get meta parameters
meta <- list(
  functionality_name = "$VIASH_META_FUNCTIONALITY_NAME",
  resources_dir = "$VIASH_RESOURCES_DIR"
)

# get resources dir
resources_dir = "$VIASH_RESOURCES_DIR"

print(par)
readr::write_lines("derp", par\\$output_one)
readr::write_lines("derp", par\\$output_multi)
readr::write_lines("derp", par\\$output_opt)
VIASHMAIN

Rscript "$tempscript"
'''
  return out.replace("\\", "\\\\").replace('$', '\\$')
}

def processFactory(Map processArgs) {
  def tripQuo = "\"\"\""
  def procKey = processArgs["key"] + "_process"

  // subset directives and convert to list of tuples
  // todo: extend directive list

  def directiveNames = [ "echo", "label", "queue", "publish", "publishDir", "publishMode", "container" ]
  def directiveArgs = processArgs.directives.subMap(directiveNames)

  def procStr = """nextflow.enable.dsl=2
  
process $procKey {
  tag "\$id"

  ${directiveArgs.containsKey("echo") ? "echo ${directiveArgs['echo']}" : ""}
  ${directiveArgs.containsKey("container") ? "container \"${directiveArgs['container']}\"" : ""}

  input:
    tuple val(id), path(paths), val(args)
  output:
    tuple val("\$id"), path("\${args.output_one}"), path("\${args.output_multi}")
  stub:
    $tripQuo
    touch "\${args.output_one}"
    touch "\${args.output_multi}"
    $tripQuo
  script:
  def parInject = args.collect{ key, value ->
    "export VIASH_PAR_\${key.toUpperCase()}=\\\"\$value\\\""
  }.join("\\n")

$tripQuo
# TO DO: VIASH_TEMP
# TO DO: VIASH_RESOURCES_DIR
# TO DO: optional args
export VIASH_RESOURCES_DIR="./"
export VIASH_TEMP="./"
export VIASH_META_FUNCTIONALITY_NAME="${fun["name"]}"

\$parInject

${processScript()}

$tripQuo
}
"""
// maybe this instead of inject
// ${if (arg.containsKey("VIASH_PAR_INPUT_ONE")) "export VIASH_PAR_INPUT_ONE=\"${arg['input_one']}\"" else ""} 

  File file = new File("test_writefile.nf")
  // File file = File.createTempFile("process_${procKey}_",".tmp.nf")
  file.write procStr

  def meta = ScriptMeta.current()
  def inc = new IncludeDef([new IncludeDef.Module(name: procKey)])
  inc.path = file.getAbsolutePath()
  inc.session = session
  inc.load0(new ScriptBinding.ParamsMap())
  def proc_out = meta.getProcess(procKey)

  return proc_out
}

def poc(Map args = [:]) {
  def processArgs = defaultProcArgs + args
  processArgs["directives"] = defaultDirectives + processArgs["directives"]

  processArgsCheck(processArgs)

  // write process to temporary nf file and parse it in memory
  // def processObj = poc_process_tmp
  def processObj = processFactory(processArgs)

  def processKey = processArgs["key"]

  workflow poc_wf_instance {
    take:
    input_

    main:
    output_= input_
        | map{ id_input_obj ->
          // TODO: add debug option to see what goes in and out of the workflow
          if (processArgs.map) {
            id_input_obj = processArgs.map(id_input_obj)
          }
          
          // TODO: add checks on id_input_obj to see if it is in the right format
          def id = id_input_obj[0]
          def data = id_input_obj[1]

          // fetch default params from functionality
          def defaultArgs = fun.arguments.findAll{ it.default }.collectEntries {
            [ it.name, it.default ]
          }

          // fetch overrides in params
          def paramArgs = fun.arguments
            .findAll { params.containsKey(processKey + "__" + it.name) }
            .collectEntries { [ it.name, params[processKey + "__" + it.name] ] }
          
          // fetch overrides in data
          def dataArgs = fun.arguments
            .findAll { data.containsKey(it.name) }
            .collectEntries { [ it.name, data[it.name] ] }
          
          // combine params
          def combinedArgs = defaultArgs + paramArgs + processArgs.args + dataArgs

          def combinedArgs2 = fun.arguments
            .findAll { combinedArgs.containsKey(it.name) }
            .collectEntries { par ->
              def parVal = combinedArgs[par.name]
              if (par.direction.toLowerCase() == "output" && par.type == "file") {
                def newVal = parVal.replaceAll('\\$id', id).replaceAll('\\$key', processKey)
                [par.name, newVal]
              } else {
                [par.name, parVal]
              }
              
            }

          // TODO: check whether required arguments exist
          // TODO: check whether parameters have the right type

          def paths = [ combinedArgs2.input_one, combinedArgs2.input_multi ]
          
          // todo: add passthrough for other tuple items
          def out = [ id, paths, combinedArgs2 ]

          out
        }
        // | view{ ["middle", it]}
        | processObj
        | map { output ->
          [ output[0], [ output_one: output[1], output_multi: output[2] ] ]
        }

    emit:
    output_
  }

  return poc_wf_instance
}
