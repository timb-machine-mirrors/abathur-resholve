{ lib, resholve, binlore }:

rec {
  /* These functions break up the work of partially validating the
    'solutions' attrset and massaging it into env/cli args.

    Note: some of the left-most args do not *have* to be passed as
    deep as they are, but I've done so to provide more error context
  */

  # for brevity / line length
  spaces = l: builtins.concatStringsSep " " l;
  colons = l: builtins.concatStringsSep ":" l;
  semicolons = l: builtins.concatStringsSep ";" l;

  /* Throw a fit with dotted attr path context */
  nope = path: msg:
    throw "${builtins.concatStringsSep "." path}: ${msg}";

  /* Special-case directive value representations by type */
  makeDirective = solution: env: name: val:
    if builtins.isInt val then builtins.toString val
    else if builtins.isString val then name
    else if true == val then name
    else if false == val then "" # omit!
    else if null == val then "" # omit!
    else if builtins.isList val then "${name}:${semicolons val}"
    else nope [ solution env name ] "unexpected type: ${builtins.typeOf val}";

  /* Build fake/fix/keep directives from Nix types */
  makeDirectives = solution: env: val:
    lib.mapAttrsToList (makeDirective solution env) val;

  /* Custom ~search-path routine to handle relative path strings */
  relSafeBinPath = input:
    if lib.isDerivation input then ((lib.getOutput "bin" input) + "/bin")
    else if builtins.isString input then input
    else throw "unexpected type for input: ${builtins.typeOf input}";

  /* Special-case value representation by type/name */
  makeEnvVal = solution: env: val:
    if env == "inputs" then (colons (map relSafeBinPath val))
    else if builtins.isString val then val
    else if builtins.isList val then spaces val
    else if builtins.isAttrs val then spaces (makeDirectives solution env val)
    else nope [ solution env ] "unexpected type: ${builtins.typeOf val}";

  /* Shell-format each env value */
  shellEnv = solution: env: value:
    lib.escapeShellArg (makeEnvVal solution env value);

  /* Build a single ENV=val pair */
  makeEnv = solution: env: value:
    "RESHOLVE_${lib.toUpper env}=${shellEnv solution env value}";

  /* Discard attrs claimed by makeArgs */
  removeCliArgs = value:
    removeAttrs value [ "scripts" "flags" ];

  /* Verify required arguments are present */
  validateSolution = { scripts, inputs, interpreter, ... }: true;

  /* Pull out specific solution keys to build ENV=val pairs */
  makeEnvs = solution: value:
    spaces (lib.mapAttrsToList (makeEnv solution) (removeCliArgs value));

  /* Pull out specific solution keys to build CLI argstring */
  makeArgs = { flags ? [ ], scripts, ... }:
    spaces (flags ++ scripts);

  /* Build a single resholve invocation */
  makeInvocation = solution: value:
    if validateSolution value then
    # we pass resholve a directory
      "RESHOLVE_LORE=${binlore.collect { drvs = value.inputs; } } ${makeEnvs solution value} ${resholve}/bin/resholve --overwrite ${makeArgs value}"
    else throw "invalid solution"; # shouldn't trigger for now

  /* Build resholve invocation for each solution. */
  makeCommands = solutions:
    lib.mapAttrsToList makeInvocation solutions;
}
