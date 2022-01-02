module Model exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser
import Html exposing (a)


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    }


-- Route

type Route
    = Index
    | Add


routeParser: Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map Index Url.Parser.top
        , Url.Parser.map Add (Url.Parser.s "add")
        ]