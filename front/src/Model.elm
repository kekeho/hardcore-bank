module Model exposing (..)

import Browser.Navigation as Nav
import Url


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    }
