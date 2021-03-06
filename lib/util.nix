{ stdenv, lib }:

with lib; rec {
  combination = x:
    if x == [ ] then
      [ [ ] ]
    else
      let
        h = builtins.head x;
        t = builtins.tail x;
        offComb = combination t;
        onComb = map (c: [ h ] ++ c) offComb;
      in offComb ++ onComb;

  combineFeatures = attrs: sep:
    let
      names = builtins.attrNames attrs;
      namesComb = combination names;
      mergeValueAttrs =
        (names: builtins.foldl' (s: name: s // attrs.${name}) { } names);
      combs_attrs = let
        nameToList = map (names: {
          name = (builtins.concatStringsSep sep names);
          value = mergeValueAttrs names;
        }) namesComb;
      in builtins.listToAttrs nameToList;
    in combs_attrs;

  attrsToList = attrs:
    let names = builtins.attrNames attrs;
    in map (name: {
      name = name;
      value = builtins.getAttr name attrs;
    }) names;

  snakeVersion = version:
    builtins.replaceStrings [ "." "-" ] [ "_" "_" ] version;

  makeFeatureString = features: sep:
    if features == "" then
      ""
    else
      "${sep}${builtins.replaceStrings [ "_" ] [ sep ] features}";

  makePkgPath = prefix: version: features:
    "${prefix}${snakeVersion version}${makeFeatureString features "_"}";

  makePkgName = prefix: version: features:
    "${prefix}${version}${makeFeatureString features "-"}";

  filterDerivations = attrs:
    attrsets.filterAttrs (k: v: attrsets.isDerivation v) attrs;

  mergeListOfAttrs = listOfAttrs:
    builtins.foldl' (acc: attrs: acc // attrs) { } listOfAttrs;

  # This helper not exists nixpkgs-20.03
  recurseIntoAttrs = attrs: attrs // { recurseForDerivations = true; };

  findByPrefix = root: prefix:
    let
      basenames = lib.attrsets.attrNames (lib.attrsets.filterAttrs
        (path: type: (lib.strings.hasPrefix prefix path))
        (builtins.readDir root));
    in builtins.map (path: root + ("/" + path)) basenames;
}
