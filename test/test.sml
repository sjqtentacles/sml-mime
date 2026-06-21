(* Tests for sml-mime. *)

structure MimeTests =
struct
  open Harness

  fun run () =
    let
      val () = section "media-type parse"
      val mt = valOf (MediaType.parse "text/html; charset=utf-8")
      val () = checkString "type" ("text", #typ mt)
      val () = checkString "subtype" ("html", #subtype mt)
      val () = checkString "essence" ("text/html", MediaType.essence mt)
      val () = checkBool "param" (true, MediaType.param mt "charset" = SOME "utf-8")
      val () = checkBool "param case-insensitive" (true, MediaType.param mt "CharSet" = SOME "utf-8")
      val () = checkBool "missing param" (true, MediaType.param mt "boundary" = NONE)

      val () = section "media-type lowercasing & whitespace"
      val mt2 = valOf (MediaType.parse "  Application/JSON  ")
      val () = checkString "lower type" ("application", #typ mt2)
      val () = checkString "lower subtype" ("json", #subtype mt2)

      val () = section "media-type quoted params"
      val mt3 = valOf (MediaType.parse "multipart/form-data; boundary=\"a;b=c\"")
      val () = checkBool "quoted boundary" (true, MediaType.param mt3 "boundary" = SOME "a;b=c")

      val () = section "media-type format round-trips"
      val () = checkString "format simple"
                 ("text/html; charset=utf-8", MediaType.format mt)
      val () = checkString "format quotes when needed"
                 ("multipart/form-data; boundary=\"a;b=c\"", MediaType.format mt3)

      val () = section "media-type invalid"
      val () = checkBool "no slash" (true, MediaType.parse "texthtml" = NONE)
      val () = checkBool "empty subtype" (true, MediaType.parse "text/" = NONE)

      val () = section "mime table"
      val () = checkBool "html" (true, MimeTable.byExtension "html" = SOME "text/html; charset=utf-8")
      val () = checkBool "HTML upper" (true, MimeTable.byExtension "HTML" = SOME "text/html; charset=utf-8")
      val () = checkBool "png" (true, MimeTable.byExtension "png" = SOME "image/png")
      val () = checkBool "unknown" (true, MimeTable.byExtension "xyz" = NONE)
      val () = checkBool "byFilename" (true, MimeTable.byFilename "a/b/index.html" = SOME "text/html; charset=utf-8")
      val () = checkBool "byFilename no ext" (true, MimeTable.byFilename "README" = NONE)
      val () = checkString "default" ("application/octet-stream", MimeTable.default)

      val () = section "multipart split"
      val boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
      val body =
        "--" ^ boundary ^ "\r\n" ^
        "Content-Disposition: form-data; name=\"field1\"\r\n\r\n" ^
        "value1\r\n" ^
        "--" ^ boundary ^ "\r\n" ^
        "Content-Disposition: form-data; name=\"file\"; filename=\"a.txt\"\r\n" ^
        "Content-Type: text/plain\r\n\r\n" ^
        "file contents\r\n" ^
        "--" ^ boundary ^ "--\r\n"
      val parts = valOf (Multipart.split { boundary = boundary, body = body })
      val () = checkInt "two parts" (2, List.length parts)
      val p1 = List.nth (parts, 0)
      val p2 = List.nth (parts, 1)
      val () = checkString "part1 body" ("value1", #body p1)
      val () = checkBool "part1 name" (true, Multipart.fieldName p1 = SOME "field1")
      val () = checkString "part2 body" ("file contents", #body p2)
      val () = checkBool "part2 name" (true, Multipart.fieldName p2 = SOME "file")
      val () = checkBool "part2 filename" (true, Multipart.fileName p2 = SOME "a.txt")

      val () = section "multipart build round-trip"
      val built =
        Multipart.build
          { boundary = boundary
          , parts =
              [ { headers = [("Content-Disposition", "form-data; name=\"x\"")]
                , body = "1" }
              , { headers = [("Content-Disposition", "form-data; name=\"y\"")]
                , body = "two" } ] }
      val reparsed = valOf (Multipart.split { boundary = boundary, body = built })
      val () = checkInt "round-trip count" (2, List.length reparsed)
      val () = checkBool "round-trip name x"
                 (true, Multipart.fieldName (List.nth (reparsed, 0)) = SOME "x")
      val () = checkString "round-trip body two"
                 ("two", #body (List.nth (reparsed, 1)))

      val () = section "multipart edge cases"
      val () = checkBool "empty boundary rejected"
                 (true, Multipart.split { boundary = "", body = "x" } = NONE)
    in
      ()
    end
end
