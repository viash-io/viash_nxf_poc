nextflow.enable.dsl=2

// TODO: add some documentation on how this file was created and how to use it.

import nextflow.script.IncludeDef
import nextflow.script.ScriptBinding
import nextflow.script.ScriptMeta
import java.nio.file.Files
import java.nio.file.Paths

// look for some global variables
metaThis = ScriptMeta.current()
resourcesDir = metaThis.getScriptPath().getParent()

tempDir = Paths.get(
  System.getenv('NXF_TEMP') ?:
    System.getenv('VIASH_TEMP') ?: 
    System.getenv('TEMPDIR') ?: 
    System.getenv('TMPDIR') ?: 
    '/tmp'
).toAbsolutePath()


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
      'required': false,
      'type': 'file',
      'direction': 'Output',
      'multiple': true,
      'multiple_sep': ':',
      'example': 'output.txt',
      'default': '$id.$key.output_multi_*.txt',
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
      'default': '$id.$key.output_opt.txt',
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


def assertMapKeys(map, expectedKeys, requiredKeys, mapName) {
  assert map instanceof HashMap : "Expected publish argument '$elem' to be a String or a HashMap. Found: class ${elem.getClass()}"
  map.forEach { key, val -> 
    assert key in expectedKeys : "Unexpected key '$key' in ${mapName ? mapName + " " : ""}map"
  }
  requiredKeys.forEach { requiredKey -> 
    assert map.containsKey(requiredKey) : "Missing required key '$key' in ${mapName ? mapName + " " : ""}map"
  }
}

// TODO: unit test processDirectives
def processDirectives(drctv) {
  /* DIRECTIVE accelerator
     accepted examples:
     - [ limit: 4, type: "nvidia-tesla-k80" ]
   */
  if (drctv.containsKey("accelerator")) {
    assertMapKeys(drctv["accelerator"], ["type", "limit", "request", "runtime"], [], "accelerator")
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

  /* DIRECTIVE conda
     accepted examples:
     - "bwa=0.7.15"
     - "bwa=0.7.15 fastqc=0.11.5"
     - ["bwa=0.7.15", "fastqc=0.11.5"]
   */
  if (drctv.containsKey("conda")) {
    if (drctv["conda"] instanceof ArrayList) {
      drctv["conda"] = drctv["conda"].join(" ")
    }
    assert drctv["conda"] instanceof String
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

  /* DIRECTIVE containerOptions
     accepted examples:
     - "--foo bar"
     - ["--foo bar", "-f b"]
   */
  if (drctv.containsKey("containerOptions")) {
    if (drctv["containerOptions"] instanceof ArrayList) {
      drctv["containerOptions"] = drctv["containerOptions"].join(" ")
    }
    assert drctv["containerOptions"] instanceof String
  }

  /* DIRECTIVE cpus
     accepted examples:
     - 1
     - 10
   */
  if (drctv.containsKey("cpus")) {
    assert drctv["cpus"] instanceof Integer
  }

  /* DIRECTIVE disk
     accepted examples:
     - "1 GB"
     - "2TB"
     - "3.2KB"
     - "10.B"
   */
  if (drctv.containsKey("disk")) {
    assert drctv["disk"] instanceof String
    // assert drctv["disk"].matches("[0-9]+(\\.[0-9]*)? *[KMGTPEZY]?B")
    // ^ does not allow closures
  }

  /* DIRECTIVE echo
     accepted examples:
     - true
     - false
   */
  if (drctv.containsKey("echo")) {
    assert drctv["echo"] instanceof Boolean
  }

  /* DIRECTIVE errorStrategy
     accepted examples:
     - "terminate"
     - "finish"
   */
  if (drctv.containsKey("errorStrategy")) {
    assert drctv["errorStrategy"] instanceof String
    assert drctv["errorStrategy"] in ["terminate", "finish", "ignore", "retry"] : "Unexpected value for errorStrategy"
  }

  /* DIRECTIVE executor
     accepted examples:
     - "local"
     - "sge"
   */
  if (drctv.containsKey("executor")) {
    assert drctv["executor"] instanceof String
    assert drctv["executor"] in ["local", "sge", "uge", "lsf", "slurm", "pbs", "pbspro", "moab", "condor", "nqsii", "ignite", "k8s", "awsbatch", "google-pipelines"] : "Unexpected value for executor"
  }

  /* DIRECTIVE machineType
     accepted examples:
     - "n1-highmem-8"
   */
  if (drctv.containsKey("machineType")) {
    assert drctv["machineType"] instanceof String
  }

  /* DIRECTIVE maxErrors
     accepted examples:
     - 1
     - 3
   */
  if (drctv.containsKey("maxErrors")) {
    assert drctv["maxErrors"] instanceof Integer
  }

  /* DIRECTIVE maxForks
     accepted examples:
     - 1
     - 3
   */
  if (drctv.containsKey("maxForks")) {
    assert drctv["maxForks"] instanceof Integer
  }

  /* DIRECTIVE maxRetries
     accepted examples:
     - 1
     - 3
   */
  if (drctv.containsKey("maxRetries")) {
    assert drctv["maxRetries"] instanceof Integer
  }

  /* DIRECTIVE memory
     accepted examples:
     - "1 GB"
     - "2TB"
     - "3.2KB"
     - "10.B"
   */
  if (drctv.containsKey("memory")) {
    assert drctv["memory"] instanceof String
    // assert drctv["memory"].matches("[0-9]+(\\.[0-9]*)? *[KMGTPEZY]?B")
    // ^ does not allow closures
  }

  /* DIRECTIVE module
     accepted examples:
     - "ncbi-blast/2.2.27"
     - "ncbi-blast/2.2.27:t_coffee/10.0"
     - ["ncbi-blast/2.2.27", "t_coffee/10.0"]
   */
  if (drctv.containsKey("module")) {
    if (drctv["module"] instanceof ArrayList) {
      drctv["module"] = drctv["module"].join(":")
    }
    assert drctv["module"] instanceof String
  }

  /* DIRECTIVE penv
     accepted examples:
     - "smp"
   */
  if (drctv.containsKey("penv")) {
    assert drctv["penv"] instanceof String
  }

  /* DIRECTIVE pod
     accepted examples:
     - [ label: "key", value: "val" ]
     - [ annotation: "key", value: "val" ]
     - [ env: "key", value: "val" ]
     - [ [label: "l", value: "v"], [env: "e", value: "v"]]
   */
  if (drctv.containsKey("pod")) {
    if (drctv["pod"] instanceof HashMap) {
      drctv["pod"] = [ drctv["pod"] ]
    }
    assert drctv["pod"] instanceof ArrayList
    drctv["pod"].forEach { pod ->
      assert pod instanceof HashMap
      // TODO: should more checks be added?
      // See https://www.nextflow.io/docs/latest/process.html?highlight=directives#pod
      // e.g. does it contain 'label' and 'value', or 'annotation' and 'value', or ...?
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
      if (elem.containsKey("saveAs")) {
        assert elem["saveAs"] instanceof String //: "saveAs as a Closure is currently not supported. Surround your closure with single quotes to get the desired effect. Example: '\{ foo \}'"
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

  /* DIRECTIVE queue
     accepted examples:
     - "long"
     - "short,long"
     - ["short", "long"]
   */
  if (drctv.containsKey("queue")) {
    if (drctv["queue"] instanceof ArrayList) {
      drctv["queue"] = drctv["queue"].join(",")
    }
    assert drctv["queue"] instanceof String
  }

  /* DIRECTIVE label
     accepted examples:
     - "big_mem"
     - "big_cpu"
     - ["big_mem", "big_cpu"]
   */
  if (drctv.containsKey("label")) {
    if (drctv["label"] instanceof String) {
      drctv["label"] = [ drctv["label"] ]
    }
    assert drctv["label"] instanceof ArrayList
    drctv["label"].forEach { label ->
      assert label instanceof String
      // assert label.matches("[a-zA-Z0-9]([a-zA-Z0-9_]*[a-zA-Z0-9])?")
      // ^ does not allow closures
    }
  }

  /* DIRECTIVE scratch
     accepted examples:
     - true
     - "/path/to/scratch"
     - '$MY_PATH_TO_SCRATCH'
     - "ram-disk"
   */
  if (drctv.containsKey("scratch")) {
    assert drctv["scratch"] == true || drctv["scratch"] instanceof String
  }

  /* DIRECTIVE storeDir
     accepted examples:
     - "/path/to/storeDir"
   */
  if (drctv.containsKey("storeDir")) {
    assert drctv["storeDir"] instanceof String
  }

  /* DIRECTIVE stageInMode
     accepted examples:
     - "copy"
     - "link"
   */
  if (drctv.containsKey("stageInMode")) {
    assert drctv["stageInMode"] instanceof String
    assert drctv["stageInMode"] in ["copy", "link", "symlink", "rellink"]
  }

  /* DIRECTIVE stageOutMode
     accepted examples:
     - "copy"
     - "link"
   */
  if (drctv.containsKey("stageOutMode")) {
    assert drctv["stageOutMode"] instanceof String
    assert drctv["stageOutMode"] in ["copy", "move", "rsync"]
  }

  /* DIRECTIVE tag
     accepted examples:
     - "foo"
     - '$id'
   */
  if (drctv.containsKey("tag")) {
    assert drctv["tag"] instanceof String
  }

  /* DIRECTIVE time
     accepted examples:
     - "1h"
     - "2days"
     - "1day 6hours 3minutes 30seconds"
   */
  if (drctv.containsKey("time")) {
    assert drctv["time"] instanceof String
    // todo: validation regex?
  }

  return drctv
}

def processProcessArgs(Map args, Map defaultProcessArgs, Map defaultDirectives) {
  // override defaults with args
  def processArgs = defaultProcessArgs + args

  // check whether 'key' exists
  assert processArgs.containsKey("key")
  assert processArgs["key"] instanceof String
  assert processArgs["key"] ==~ /^[a-zA-Z_][a-zA-Z0-9_]*$/

  // check whether directives exists and apply defaults
  if (!processArgs.containsKey("directives")) {
    processArgs["directives"] = [:]
  }
  assert processArgs["directives"] instanceof HashMap
  processArgs["directives"] = processDirectives(defaultDirectives + processArgs["directives"])

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
  resources_dir = "$VIASH_META_RESOURCES_DIR"
)

# get resources dir
resources_dir = "$VIASH_RESOURCES_DIR"

input_one <- readr::read_lines(par\\$input_one)
input_multi <- lapply(par\\$input_multi, readr::read_lines)

print(par)

readr::write_lines(c(input_one, par\\$string), par\\$output_one)

for (i in seq_along(input_multi)) {
  if (length(par\\$output_multi) == 1 && grepl("\\\\\\\\*", par\\$output_multi)) {
    path <- gsub("\\\\\\\\*", i, par\\$output_multi)
  } else if (length(par\\$output_multi) == length(input_multi)) {
    path <- par\\$output_multi[[i]]
  } else {
    stop("Unexpected output_multi format.")
  }
  readr::write_lines(c(input_multi[[i]], par\\$string), path)
}

if (!is.null(par\\$input_opt)) {
  input_opt <- readr::read_lines(par\\$input_opt)
  readr::write_lines(c(input_opt, par\\$string), par\\$output_opt)
}
VIASHMAIN

Rscript "$tempscript"
'''
  return out.replace("\\", "\\\\").replace('$', '\\$')
}

def processFactory(Map processArgs) {
  def tripQuo = "\"\"\""
  def procKey = processArgs["key"] + "_process"

  // subset directives and convert to list of tuples
  def drctv = processArgs.directives

  // TODO: unit test the two commands below
  // convert publish array into tags
  def valueToStr = { val ->
    // ignore closures
    if (val instanceof String) {
      if (!val.matches('^[{].*[}]$')) {
        '"' + val + '"'
      } else {
        val
      }
    } else if (val instanceof List) {
      "[" + val.collect{valueToStr(it)}.join(", ") + "]"
    } else if (val instanceof Map) {
      "[" + val.collect{k, v -> k + ": " + valueToStr(v)}.join(", ") + "]"
    } else {
      val.inspect()
    }
  }
  // multiple entries allowed: label, publishdir
  def drctvStrs = drctv.collect { key, value ->
    if (key in ["label", "publishDir"]) {
      value.collect{ val ->
        if (val instanceof Map) {
          "\n  $key " + val.collect{ k, v -> k + ": " + valueToStr(v) }.join(", ")
        } else {
          "\n  $key " + valueToStr(val)
        }
      }.join()
    } else if (value instanceof Map) {
      "\n  $key " + value.collect{ k, v -> k + ": " + valueToStr(v) }.join(", ")
    } else {
      "\n  $key " + valueToStr(value)
    }
  }.join()

  def outputPaths = fun.arguments
    .findAll { it.type == "file" && it.direction.toLowerCase() == "output" }
    .collect { par ->
      ', path("${args.' + par.name + '}"' + (par.required ? "" : ", optional: true") + ')'
    }
    .join()

  // generate process string
  def procStr = """nextflow.enable.dsl=2
  
process $procKey {$drctvStrs
  
  input:
    tuple val(id), path(paths), val(args), val(inject), val(passthrough)
  output:
    // tuple val("\$id"), val(passthrough), path("\${args.output_one}"), path("\${args.output_multi}", optional: true), path("\${args.output_opt}", optional: true)
    tuple val("\$id"), val(passthrough)$outputPaths
  stub:
$tripQuo
\${inject["stub"]}
$tripQuo
  script:
$tripQuo
\${inject["before_script"]}
${scriptFactory()}
\${inject["after_script"]}
$tripQuo
}
"""

  // TODO: clean up tempdir after run?
  File file = Files.createTempFile(dir = tempDir, prefix = "process_${procKey}_", suffix = ".tmp.nf").toFile()
  file.write procStr

  def meta = ScriptMeta.current()
  def inc = new IncludeDef([new IncludeDef.Module(name: procKey)])
  inc.path = file.getAbsolutePath()
  inc.session = session
  inc.load0(new ScriptBinding.ParamsMap())
  def proc_out = meta.getProcess(procKey)

  return proc_out
}

def workflowFactory(Map args) {
  // these defaults are defined by the viash config
  def defaultDirectives = [
    tag: '$id',
    container: [ registry: null, image: "rocker/tidyverse", tag: "4.0.5" ]
  ]

  // these defaults are defined by the viash config
  def defaultProcessArgs = [
    key: fun['name'],
    args: [:],
    simplifyInput: false, // todo: implement
    simplifyOutput: false // todo: implement
    // map: { it -> it },
    // mapId: { it -> it[0] },
    // mapData: { it -> it[1] }
    // renameKeys: [ "new": "old" ]
  ]

  def processArgs = processProcessArgs(args, defaultProcessArgs, defaultDirectives)
  def processKey = processArgs["key"]

  // write process to temporary nf file and parse it in memory
  // def processObj = poc_process_tmp
  def processObj = processFactory(processArgs)

  workflow pocInstance {
    take:
    input_

    main:
    output_= input_
        | map{ tuple ->
          // TODO: add debug option to see what goes in and out of the workflow
          // if (params.debug) {
          //   println("Process '$processKey' input: $tuple")
          // }

          if (processArgs.map) {
            tuple = processArgs.map(tuple)
          }
          if (processArgs.mapId) {
            tuple[0] = processArgs.mapId(tuple)
          }
          if (processArgs.mapData) {
            tuple[1] = processArgs.mapData(tuple)
          }

          // check tuple
          assert tuple instanceof AbstractList : 
            "Error in process '${processKey}': element in channel should be a tuple [id, data, ...otherargs...]\n" +
            "  Example: [\"id\", [input: file('foo.txt'), arg: 10]].\n" +
            "  Expected class: List. Found: tuple.getClass() is ${tuple.getClass()}"
          assert tuple.size() >= 2 : 
            "Error in process '${processKey}': expected length of tuple in input channel to be two or greater.\n" +
            "  Example: [\"id\", [input: file('foo.txt'), arg: 10]].\n" +
            "  Found: tuple.size() == ${tuple.size()}"
          
          // check id field
          assert tuple[0] instanceof String : 
            "Error in process '${processKey}': first element of tuple in channel should be a String\n" +
            "  Example: [\"id\", [input: file('foo.txt'), arg: 10]].\n" +
            "  Found: ${tuple[0]}"
          
          // match file to input file
          if (processArgs.simplifyInput && tuple[1] instanceof Path) {
            def inputFiles = fun.arguments
              .findAll { it.type == "file" && it.direction.toLowerCase() == "input" }
            
            assert inputFiles.size() == 1 : 
                "Error in process '${processKey}' id '${tuple[0]}'.\n" +
                "  Anonymous file inputs are only allowed when the process has exactly one file input.\n" +
                "  Expected: inputFiles.size() == 1. Found: inputFiles.size() is ${inputFiles.size()}"

            tuple[1] = [[ inputFiles[0].name, tuple[1] ]].collectEntries()
          }

          // check data field
          assert tuple[1] instanceof HashMap : 
            "Error in process '${processKey}' id '${tuple[0]}': second element of tuple in channel should be a HashMap\n" +
            "  Example: [\"id\", [input: file('foo.txt'), arg: 10]].\n" +
            "  Expected class: HashMap. Found: tuple[1].getClass() is ${tuple[1].getClass()}"

          // rename keys of data field in tuple
          if (processArgs.renameKeys) {
            assert processArgs.renameKeys instanceof HashMap : 
                "Error renaming data keys in process '${processKey}' id '${tuple[0]}'.\n" +
                "  Example: renameKeys: ['new_key': 'old_key'].\n" +
                "  Expected class: HashMap. Found: renameKeys.getClass() is ${processArgs.renameKeys.getClass()}"
            assert tuple[1] instanceof HashMap : 
                "Error renaming data keys in process '${processKey}' id '${tuple[0]}'.\n" +
                "  Expected class: HashMap. Found: tuple[1].getClass() is ${tuple[1].getClass()}"

            processArgs.renameKeys.each { newKey, oldKey ->
              assert newKey instanceof String : 
                "Error renaming data keys in process '${processKey}' id '${tuple[0]}'.\n" +
                "  Example: renameKeys: ['new_key': 'old_key'].\n" +
                "  Expected class of newKey: String. Found: newKey.getClass() is ${newKey.getClass()}"
              assert oldKey instanceof String : 
                "Error renaming data keys in process '${processKey}' id '${tuple[0]}'.\n" +
                "  Example: renameKeys: ['new_key': 'old_key'].\n" +
                "  Expected class of oldKey: String. Found: oldKey.getClass() is ${oldKey.getClass()}"
              assert tuple[1].containsKey(oldKey) : 
                "Error renaming data keys in process '${processKey}' id '${tuple[0]}'.\n" +
                "  Key '$oldKey' is missing in the data map. tuple[1].keySet() is '${tuple[1].keySet()}'"
              tuple[1].put(newKey, tuple[1][oldKey])
            }
            tuple[1].removeAll(processArgs.renameKeys.collect{ newKey, oldKey -> oldKey })
          }

          /*
          // rename map with wrong name
          if (processArgs.simplifyInput) {
            def inputFiles = fun.arguments
              .findAll { it.type == "file" && it.direction.toLowerCase() == "input" }
            def foundFiles = tuple[1].findAll{k, v -> v instanceof Path}.collect{k, v -> k}
            if (inputFiles.size() == 1 && foundFiles.size() == 1) {
              // if (params.debug) println("process '${processKey}' id '${tuple[0]}' - Renaming key '${foundFiles[0]}' to '${inputFiles[0].name}'.")
              tuple[1].put(inputFiles[0].name, tuple[1].remove(foundFiles[0]))
            }
          }
          */
          
          def id = tuple[0]
          def data = tuple[1]

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

          def procArgs = fun.arguments
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

          // check whether required arguments exist
          fun.arguments
            .forEach { par ->
              if (par.required) {
                assert procArgs.containsKey(par.name): "Argument ${par.name} is required but does not have a value"
              }
            }

          // TODO: check whether parameters have the right type

          // check for filename clashes
          def fileNames = procArgs.collectMany { name, val ->
            if (!val) {
              []
            } else if (val instanceof Collection) {
              val.collect{ it.getName() }
            } else if (val instanceof Path) {
              [ val.getName() ]
            } else {
              []
            }
          }
          // resolve filename clashes if need be
          if (fileNames.unique(false).size() != fileNames.size()) {
            print("WARNING: Detected input filename clashes. Resolving by creating temporary directory with symlinks.")
            // create tempdir, add symlinks to input files
            tmpdir = Files.createTempDirectory(dir = tempDir, prefix = "nxf_clash_linking")
            // TODO: make tmpdir absolute
            // TODO: Remove temp directory after use
            // the following doesn't work:
            print("tmpdir: $tmpdir")
            // addShutdownHook {
            //   tmpdir.deleteDir()
            // }
            //printAllMethods(tmpdir)
            procArgs = procArgs.collectEntries { name, val ->
              if (val && val instanceof List) {
                files_with_index = [1..val.size(), val].transpose()
                val_new = files_with_index.collect { index, file_i ->
                  dest = tmpdir.resolve(file_i.getBaseName() + ".clash_" + name + "_" + index + "." + file_i.getExtension())
                  file_i.mklink(dest)
                }
                
                print("  Renamed $name: $val to $val_new")
              } else if (val && val instanceof Path) {
                dest = tmpdir.resolve(val.getBaseName() + ".clash_" + name + "." + val.getExtension())
                val_new = val.mklink(dest)

                print("  Renamed $name: $val to $val_new")
              } else {
                val_new = val
              }
              [ name, val_new ]
            }
          }

          def meta = [
            'resources_dir' : resourcesDir,
            'functionality_name': fun['name'],
            'temp_dir': tempDir
          ]

          // find all paths
          def inputPathsFromArgs = fun.arguments
            .findAll { it.type == "file" && it.direction.toLowerCase() == "input" && procArgs.containsKey(it.name) }
            .collect { procArgs[it.name] }
          def inputPathsFromMeta = meta

          def inputPaths = (inputPathsFromArgs + inputPathsFromMeta)
            .collectMany{ val ->
              if (val == null) {
                []
              } else if (val instanceof List) {
                val
              } else if (val instanceof Path) {
                [ val ]
              } else {
                []
              }
            }
            .findAll{ it.exists() }

          // construct injects
          def parVariables = procArgs.collect{ key, value ->
            if (value instanceof Collection) {
              "export VIASH_PAR_${key.toUpperCase()}=\"${value.join(":")}\""
            } else {
              "export VIASH_PAR_${key.toUpperCase()}=\"$value\""
            }
          }
          def metaVariables = meta.collect{ key, value ->
            if (value instanceof Collection) {
              "export VIASH_META_${key.toUpperCase()}=\"${value.join(":")}\""
            } else {
              "export VIASH_META_${key.toUpperCase()}=\"$value\""
            }
          }

          def beforeScript = """
${metaVariables.join("\n")}
# synonyms
export VIASH_RESOURCES_DIR="\$VIASH_META_RESOURCES_DIR"
export VIASH_TEMP="\$VIASH_META_TEMP_DIR"
export TEMP_DIR="\$VIASH_META_TEMP_DIR"
${parVariables.join("\n")}
"""
          def afterScript = ""

          def stub = fun.arguments
            .findAll { it.type == "file" && it.direction.toLowerCase() == "output" }
            .collect { "touch \"${procArgs[it.name]}\"" }
            .join("\n")
          
          def inject = [
            "stub": stub,
            "before_script": beforeScript,
            "after_script": afterScript
          ]

          [ id, inputPaths, procArgs, inject, tuple.drop(2) ]
        }
        | processObj
        | map { output ->
          def outputFiles = fun.arguments
            .findAll { it.type == "file" && it.direction.toLowerCase() == "output" }
            .indexed()
            .collectEntries{ index, par ->
              out = output[index + 2]
              if (out instanceof List && out.size() <= 1) {
                out = out[0] // out will become null if out is []
              }
              [ par.name, out ]
            }

          if (processArgs.simplifyOutput && outputFiles.size() == 1) {
            outputFiles = outputFiles.values()[0]
          }

          def out = [ output[0], outputFiles ]

          // passthrough additional items
          if (output[1]) {
            out.addAll(output[1])
          }

          out
        }

    emit:
    output_
  }

  return pocInstance.cloneWithName(processKey)
}

// initialise standard workflow
poc = workflowFactory(key: "poc")

// add factory function
poc.metaClass.run = { args ->
  workflowFactory(args)
}

// add workflow to environment
ScriptMeta.current().addDefinition(poc)

// Implicit workflow for running this module standalone
workflow {
  params.id = "id"
  params.publishDir = "./"

  if (params.containsKey("help") && params[["help"]]) {
    exit 0, "pipeline docs"
  }

  // fetch parameters
  def args = fun.arguments
    .findAll { params.containsKey(it.name) }
    .collectEntries { par ->
      if (par.type == "file" && par.direction.toLowerCase() == "input") {
        [ par.name, file(params[par.name]) ]
      } else {
        [ par.name, params[par.name] ]
      }
    }
          
  Channel.value([ params.id, args ])
    | view { "input: $it" }
    | poc.run(
        key: "poc_run",
        directives: [publishDir: params.publishDir]
      )
    | view { "output: $it" }
}
