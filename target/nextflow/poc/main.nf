nextflow.enable.dsl=2

import nextflow.script.IncludeDef
import nextflow.script.ScriptBinding
import nextflow.script.ScriptMeta

// look for some global variables
metaThis = ScriptMeta.current()
resourcesDir = metaThis.getScriptPath().getParent()

// replace $ with {} or %%
fun = [
  'name': 'poc',
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

// default values for the nextflow process
defaultDirectives = [
  echo: false,
  label: null,
  labels: [],
  queue: null,
  publish: [],
  container: [ registry: null, image: "rocker/tidyverse", tag: "4.0.5" ]
]

defaultProcessArgs = [
  key: fun['name'],
  directives: [:],
  args: [:],
  map: { it -> it },
  mapId: { it -> it[0] },
  mapData: { it -> it[1] }
]

def assertMapKeys(Map map, List expectedKeys, List requiredKeys = [], String mapName = "") {
  assert map instanceof HashMap : "Expected publish argument '$elem' to be a String or a HashMap. Found: class ${elem.getClass()}"
  map.forEach { key, val -> 
    assert key in expectedKeys : "Unexpected key '$key' in ${mapName ? mapName + " " : ""}map"
  }
  requiredKeys.forEach { requiredKey -> 
    assert map.containsKey(requiredKey) : "Missing required key '$key' in ${mapName ? mapName + " " : ""}map"
  }
}

def processDirectives(Map directives) {
  def drctv = defaultDirectives + directives

  /* DIRECTIVE accelerator
     accepted examples:
     - [ amount: 4, type: "nvidia-tesla-k80" ]
   */
  if (drctv.containsKey("accelerator")) {
    assertMapKeys(drctv["accelerator"], ["amount", "type"], ["amount", "type"], "accelerator")
  }

  /* DIRECTIVE afterScript
     accepted examples:
     - "source /cluster/bin/cleanup"
   */
  if (drctv.containsKey("afterScript")) {
    assert drctv["afterScript"] instanceof String
  }

  /* DIRECTIVE beforeScript
     accepted examples:
     - "source /cluster/bin/setup"
   */
  if (drctv.containsKey("beforeScript")) {
    assert drctv["beforeScript"] instanceof String
  }

  /* DIRECTIVE cache
     accepted examples:
     - true
     - false
     - "deep"
     - "lenient"
   */
  if (drctv.containsKey("cache")) {
    assert drctv["cache"] instanceof String || drctv["cache"] instanceof Boolean
    if (drctv["cache"] instanceof String) {
      assert drctv["cache"] in ["deep", "lenient"] : "Unexpected value for cache"
    }
  }

  /* DIRECTIVE container
     accepted examples:
     - "foo/bar:tag"
     - [ registry: "reg", image: "im", tag: "ta" ]
       is transformed to "reg/im:ta"
     - [ image: "im" ] 
       is transformed to "im:latest"
   */
  if (drctv.containsKey("container")) {
    assert drctv["container"] instanceof HashMap || drctv["container"] instanceof String
    if (drctv["container"] instanceof HashMap) {
      def m = drctv["container"]
      assertMapKeys(m, [ "registry", "image", "tag" ], ["image"], "container")
      def part1 = m.registry ? m.registry + "/" : ""
      def part2 = m.image
      def part3 = m.tag ? ":" + m.tag : ":latest"
      drctv["container"] = part1 + part2 + part3
    }
  }

  /* DIRECTIVE publishDir
     accepted examples:
     - []
     - [ [ path: "foo", enabled: true ], [ path: "bar", enabled: false ] ]
     - "/path/to/dir" 
       is transformed to [[ path: "/path/to/dir" ]]
     - [ path: "/path/to/dir", mode: "cache" ]
       is transformed to [[ path: "/path/to/dir", mode: "cache" ]]
   */
  // TODO: should we also look at params["publishDir"]?
  if (drctv.containsKey("publishDir")) {
    def pblsh = drctv["publishDir"]
    
    // check different options
    assert pblsh instanceof ArrayList || pblsh instanceof HashMap || pblsh instanceof String
    
    // turn into list if not already so
    // for some reason, 'if (!pblsh instanceof ArrayList) pblsh = [ pblsh ]' doesn't work.
    pblsh = pblsh instanceof ArrayList ? pblsh : [ pblsh ]

    // check elements of publishDir
    pblsh = pblsh.collect{ elem ->
      // turn into map if not already so
      elem = elem instanceof String ? [ path: elem ] : elem

      // check types and keys
      assert elem instanceof HashMap : "Expected publish argument '$elem' to be a String or a HashMap. Found: class ${elem.getClass()}"
      assertMapKeys(elem, [ "path", "mode", "overwrite", "pattern", "saveAs", "enabled" ], ["path"], "publishDir")

      // check elements in map
      assert elem.containsKey("path")
      assert elem["path"] instanceof String
      if (elem.containsKey("mode")) {
        assert elem["mode"] instanceof String
        assert elem["mode"] in [ "symlink", "rellink", "link", "copy", "copyNoFollow", "move" ]
      }
      if (elem.containsKey("overwrite")) {
        assert elem["overwrite"] instanceof Boolean
      }
      if (elem.containsKey("pattern")) {
        assert elem["pattern"] instanceof String
      }
        // todo: saveAs doesn't really work atm
      assert !elem.containsKey("saveAs") : "saveAs is currently not supported. Contact Viash developers if this functionality is desired / required."
      if (elem.containsKey("saveAs")) {
        assert elem["saveAs"] instanceof Closure
      }
      if (elem.containsKey("enabled")) {
        assert elem["enabled"] instanceof Boolean
      }

      // return final result
      elem
    }
    // store final directive
    drctv["publishDir"] = pblsh
  }

  return drctv
}

def processProcessArgs(Map args) {
  // TODO: add assert messages

  // insert default processArgs if none were specified in args
  def processArgs = defaultProcessArgs + args

  // check whether 'key' exists
  assert processArgs.containsKey("key")
  assert processArgs["key"] instanceof String
  assert processArgs["key"] ==~ /^[a-zA-Z_][a-zA-Z0-9_]*$/

  // check whether directives exists and apply defaults
  assert processArgs.containsKey("directives")
  assert processArgs["directives"] instanceof HashMap
  processArgs["directives"] = processDirectives(processArgs["directives"])

  // todo: process labels
  for (nam in [ "map", "mapId", "mapData" ]) {
    if (processArgs.containsKey(nam)) {
      assert processArgs[nam] instanceof Closure : "Expected process argument '$nam' to be null or a Closure. Found: class ${processArgs[nam].getClass()}"
    }
  }

  // return output
  
  return processArgs
}

def scriptFactory() {
  // TODO in viash: check in viash whether script contains `'''` and escape

  // NOTE for implementation in viash:
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

  def drctv = processArgs.directives

  // convert publish array into tags
  def publishStrs = drctv["publishDir"].collect{ elem ->
    "\npublishDir " + elem.collect{ k, v -> k + ": " + v.inspect() }.join(", ")
  }.join()

  // generate process string
  def procStr = """nextflow.enable.dsl=2
  
process $procKey {
  tag "\$id"$publishStrs

  ${drctv.containsKey("echo") ? "echo ${drctv['echo']}" : ""}
  ${drctv.containsKey("container") ? "container \"${drctv['container']}\"" : ""}

  input:
    tuple val(id), path(paths), val(args), val(passthrough)
  output:
    tuple val("\$id"), path("\${args.output_one}"), path("\${args.output_multi}"), val(passthrough)
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
# TO DO: VIASH_TEMP // needs to be mounted
# TO DO: VIASH_RESOURCES_DIR // needs to be mounted
# TO DO: optional args
export VIASH_RESOURCES_DIR="${resourcesDir}"
export VIASH_TEMP="./"
export VIASH_META_FUNCTIONALITY_NAME="${fun["name"]}"

\$parInject

${scriptFactory()}

$tripQuo
}
"""

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

def poc(Map args) {
  def processArgs = processProcessArgs(args)
  def processKey = processArgs["key"]

  // write process to temporary nf file and parse it in memory
  // def processObj = poc_process_tmp
  def processObj = processFactory(processArgs)

  workflow poc_wf_instance {
    take:
    input_

    main:
    output_= input_
        | map{ elem ->
          // TODO: add debug option to see what goes in and out of the workflow
          if (processArgs.map) {
            elem = processArgs.map(elem)
          }
          if (processArgs.mapId) {
            elem[0] = processArgs.mapId(elem)
          }
          if (processArgs.mapData) {
            elem[1] = processArgs.mapData(elem)
          }
          
          assert elem instanceof AbstractList : "Error in process '${processKey}': element in channel should be a tuple [id, parameters, ...otherargs...\nExample of expected input: [\"id\", [input: file('foo.txt'), arg: 10]]. Found: elem.getClass() is ${elem.getClass()}"
          assert elem.size() >= 2 : "Error in process '${processKey}': expected length of element in input channel to be two or greater.\nExpected: elem.size() >= 2. Found: elem.size() == ${elem.size()}"
          assert elem[0] instanceof String : "Error in process '${processKey}': element in channel should be a tuple [id, parameters, ...otherargs...\nExample of expected input: [\"id\", [input: file('foo.txt'), arg: 10]]. Found: ${elem}"
          assert elem[1] instanceof HashMap | elem[1] instanceof Path : ""
          if (elem[1] instanceof Path) {
            // assert ...
          }
          // assert elem[0] instanceof String : "Error in process '${processKey}': element in channel should be a tuple [id, parameters, ...otherargs...\nExample of expected input: [\"id\", [input: file('foo.txt'), arg: 10]]. Found: ${elem}"
          // TODO: add checks on id_input_obj to see if it is in the right format
          def id = elem[0]
          def data = elem[1]

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
          
          [ id, paths, combinedArgs2, elem.drop(2) ]
        }
        // | view{ ["middle", it]}
        | processObj
        | map { output ->
          
          def out = [ output[0], [ output_one: output[1], output_multi: output[2] ] ]

          // passthrough additional items
          if (output[3]) {
            out.addAll(output[3])
          }

          out
        }

    emit:
    output_
  }

  return poc_wf_instance
}