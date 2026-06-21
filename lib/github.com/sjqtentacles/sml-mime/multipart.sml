(* multipart.sml -- multipart/form-data (RFC 7578) split/build. *)

structure Multipart :> MULTIPART =
struct
  type part = { headers : (string * string) list, body : string }

  val crlf = "\r\n"

  (* Find the first index >= start where `needle` occurs in `hay`. *)
  fun indexFrom (hay, needle, start) =
    let
      val hl = String.size hay
      val nl = String.size needle
      fun matchesAt i =
        let
          fun loop j =
            if j >= nl then true
            else if String.sub (hay, i + j) = String.sub (needle, j)
            then loop (j + 1)
            else false
        in
          loop 0
        end
      fun scan i =
        if i + nl > hl then NONE
        else if matchesAt i then SOME i
        else scan (i + 1)
    in
      if nl = 0 then SOME start else scan start
    end

  fun lower s = String.map Char.toLower s

  fun trim s =
    Substring.string (Substring.dropr Char.isSpace
                        (Substring.dropl Char.isSpace (Substring.full s)))

  (* Parse a part's header block (text before the blank line) into pairs. *)
  fun parseHeaders headerText =
    let
      val lines = String.fields (fn c => c = #"\n") headerText
      fun clean l =
        if String.size l > 0 andalso String.sub (l, String.size l - 1) = #"\r"
        then String.substring (l, 0, String.size l - 1)
        else l
      fun parseLine l =
        let val l = clean l in
          case CharVector.findi (fn (_, c) => c = #":") l of
              NONE => NONE
            | SOME (i, _) =>
                SOME (trim (String.substring (l, 0, i)),
                      trim (String.extract (l, i + 1, NONE)))
        end
    in
      List.mapPartial parseLine lines
    end

  (* Split a raw part (headers CRLF CRLF body) into a `part`. *)
  fun parsePart raw =
    case indexFrom (raw, crlf ^ crlf, 0) of
        NONE => { headers = [], body = raw }
      | SOME i =>
          { headers = parseHeaders (String.substring (raw, 0, i))
          , body = String.extract (raw, i + 4, NONE) }

  fun split { boundary, body } =
    let
      val dashBoundary = "--" ^ boundary
      (* Each part is preceded by CRLF-- boundary; the first may start at 0. *)
      fun collect (pos, acc) =
        case indexFrom (body, dashBoundary, pos) of
            NONE => SOME (List.rev acc)   (* no closing delimiter: tolerate *)
          | SOME i =>
              let
                val afterDelim = i + String.size dashBoundary
              in
                (* Closing delimiter "--boundary--" ends the body. *)
                if afterDelim + 1 < String.size body
                   andalso String.sub (body, afterDelim) = #"-"
                   andalso String.sub (body, afterDelim + 1) = #"-"
                then SOME (List.rev acc)
                else
                  let
                    (* Skip the CRLF after the boundary line. *)
                    val partStart =
                      if afterDelim + 1 < String.size body
                         andalso String.sub (body, afterDelim) = #"\r"
                         andalso String.sub (body, afterDelim + 1) = #"\n"
                      then afterDelim + 2
                      else afterDelim
                  in
                    case indexFrom (body, crlf ^ dashBoundary, partStart) of
                        NONE => SOME (List.rev acc)
                      | SOME nextDelim =>
                          let
                            val raw = String.substring
                                        (body, partStart, nextDelim - partStart)
                          in
                            collect (nextDelim + String.size crlf,
                                     parsePart raw :: acc)
                          end
                  end
              end
    in
      if boundary = "" then NONE else collect (0, [])
    end

  fun build { boundary, parts } =
    let
      val dashBoundary = "--" ^ boundary
      fun renderPart ({ headers, body } : part) =
        dashBoundary ^ crlf ^
        String.concat (List.map (fn (k, v) => k ^ ": " ^ v ^ crlf) headers) ^
        crlf ^ body ^ crlf
    in
      String.concat (List.map renderPart parts) ^ dashBoundary ^ "--" ^ crlf
    end

  (* Pull an attribute value (possibly quoted) from a Content-Disposition. *)
  fun dispositionAttr (p : part) attr =
    case List.find (fn (k, _) => lower k = "content-disposition") (#headers p) of
        NONE => NONE
      | SOME (_, v) =>
          let
            val needle = lower attr ^ "="
            val lowered = lower v
          in
            case indexFrom (lowered, needle, 0) of
                NONE => NONE
              | SOME i =>
                  let
                    val start = i + String.size needle
                    val rest = String.extract (v, start, NONE)
                  in
                    if String.size rest > 0 andalso String.sub (rest, 0) = #"\""
                    then
                      let
                        val rest' = String.extract (rest, 1, NONE)
                      in
                        case CharVector.findi (fn (_, c) => c = #"\"") rest' of
                            NONE => SOME rest'
                          | SOME (j, _) => SOME (String.substring (rest', 0, j))
                      end
                    else
                      (* unquoted: up to ';' or end *)
                      case CharVector.findi (fn (_, c) => c = #";") rest of
                          NONE => SOME (trim rest)
                        | SOME (j, _) => SOME (trim (String.substring (rest, 0, j)))
                  end
          end

  fun fieldName p = dispositionAttr p "name"
  fun fileName p = dispositionAttr p "filename"
end
