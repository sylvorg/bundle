with builtins; with import <nixpkgs> {}; with lib; let
    recursiveUpdateAll' = delim: a: b: let
        a-names = attrNames a;
    in (mapAttrs (n: v: if (isAttrs v) then (if (any (attr: (isAttrs attr) || (isList attr) || (isString attr)) (attrValues v))
                                                then (recursiveUpdateAll' delim v (b.${n} or {}))
                                                else (v // (b.${n} or {})))
                        else if (isList v) then (v ++ (b.${n} or []))
                        else if (isString v) then (v + delim + (b.${n} or ""))
                        else (b.${n} or v)) a) // (filterAttrs (n: v: ! (elem n a-names)) b);
    test = recursiveUpdateAll' "\n" { a.b = [ 1 2 ]; b.c.d = "Hello, "; e = 15; } { a.b = [ 3 4 ]; b.c.d = "world!"; e = 16; f.g = { h.i = [ 5 6 ]; }; };
in mkShell { shellHook = ''
    ${trace test.a.b ":"}
    ${trace test.e ":"}
    ${trace test.b.c.d ":"}
    ${trace test.f.g.h.i ":"}
    exit
''; }
