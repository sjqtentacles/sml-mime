(* mediatype.sml -- RFC 9110 media-type parse/format. *)

structure MediaType :> MEDIA_TYPE =
struct
  type media_type =
    { typ : string, subtype : string, params : (string * string) list }

  fun lower s = String.map Char.toLower s

  fun trim s =
    Substring.string (Substring.dropr Char.isSpace
                        (Substring.dropl Char.isSpace (Substring.full s)))

  (* Split on the first occurrence of char c: (before, after-without-c). *)
  fun splitFirst c s =
    case CharVector.findi (fn (_, ch) => ch = c) s of
        NONE => (s, NONE)
      | SOME (i, _) =>
          (String.substring (s, 0, i),
           SOME (String.extract (s, i + 1, NONE)))

  (* A token (RFC 9110 5.6.2) must be non-empty and have no spaces or "/". *)
  fun isTokenChar ch =
    Char.isAlphaNum ch orelse
    (case ch of
         #"!" => true | #"#" => true | #"$" => true | #"%" => true
       | #"&" => true | #"'" => true | #"*" => true | #"+" => true
       | #"-" => true | #"." => true | #"^" => true | #"_" => true
       | #"`" => true | #"|" => true | #"~" => true | _ => false)

  fun isToken s = s <> "" andalso CharVector.all isTokenChar s

  (* Strip surrounding double quotes from a parameter value and unescape. *)
  fun unquote s =
    if String.size s >= 2 andalso String.sub (s, 0) = #"\""
       andalso String.sub (s, String.size s - 1) = #"\""
    then
      let
        val inner = String.substring (s, 1, String.size s - 2)
        fun loop [] acc = String.implode (List.rev acc)
          | loop (#"\\" :: c :: rest) acc = loop rest (c :: acc)
          | loop (c :: rest) acc = loop rest (c :: acc)
      in
        loop (String.explode inner) []
      end
    else s

  (* Split a parameter list on ';' while ignoring ';' inside quoted strings. *)
  fun splitParams s =
    let
      fun loop ([], cur, acc) = List.rev (List.rev cur :: acc)
        | loop (#"\"" :: rest, cur, acc) =
            (* consume a quoted run verbatim, including the quotes *)
            let
              fun quoted ([], q) = (List.rev q, [])
                | quoted (#"\\" :: c :: r, q) = quoted (r, c :: #"\\" :: q)
                | quoted (#"\"" :: r, q) = (List.rev (#"\"" :: q), r)
                | quoted (c :: r, q) = quoted (r, c :: q)
              val (qchars, rest') = quoted (rest, [#"\""])
            in
              loop (rest', List.revAppend (qchars, cur), acc)
            end
        | loop (#";" :: rest, cur, acc) = loop (rest, [], List.rev cur :: acc)
        | loop (c :: rest, cur, acc) = loop (rest, c :: cur, acc)
    in
      List.map String.implode (loop (String.explode s, [], []))
    end

  fun parseParam s =
    case splitFirst #"=" s of
        (_, NONE) => NONE
      | (attr, SOME v) =>
          let val a = trim attr in
            if isToken a
            then SOME (lower a, unquote (trim v))
            else NONE
          end

  fun parse s =
    let
      val (essencePart, rest) =
        case splitFirst #";" s of
            (e, NONE) => (trim e, [])
          | (e, SOME r) =>
              (trim e,
               List.mapPartial parseParam (List.map trim (splitParams r)))
    in
      case splitFirst #"/" essencePart of
          (_, NONE) => NONE
        | (t, SOME sub) =>
            let val t' = trim t and sub' = trim sub in
              if isToken t' andalso isToken sub'
              then SOME { typ = lower t', subtype = lower sub', params = rest }
              else NONE
            end
    end

  fun needsQuote v = v = "" orelse not (isToken v)

  fun quoteVal v =
    if needsQuote v
    then "\"" ^ String.translate
                  (fn #"\"" => "\\\"" | #"\\" => "\\\\" | c => String.str c) v
         ^ "\""
    else v

  fun format ({ typ, subtype, params } : media_type) =
    typ ^ "/" ^ subtype ^
    String.concat
      (List.map (fn (a, v) => "; " ^ a ^ "=" ^ quoteVal v) params)

  fun param ({ params, ... } : media_type) name =
    let val n = lower name in
      Option.map #2 (List.find (fn (a, _) => a = n) params)
    end

  fun essence ({ typ, subtype, ... } : media_type) = typ ^ "/" ^ subtype
end
