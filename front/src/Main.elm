module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url
import Url.Parser
import Html.Events exposing (onClick)
import Browser exposing (Document)

import Model exposing (..)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init () url key =
    ( Model key url , Cmd.none )


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- View


view : Model -> Browser.Document Msg
view model =
    let
        subdoc = case Url.Parser.parse Model.routeParser model.url of
            Just Index ->
                accountListView
            Just Add ->
                addView
            Nothing ->
                notFoundView
    in
    { title = "Hardcore Bank | " ++ subdoc.title
    , body =
        [ navbar
        , main_ [] subdoc.body
        ]
    }


navbar : Html Msg
navbar =
    header []
        [ nav []
            [ a [ href "/" ]
                [ h1 [ class "logotext" ]
                    [ text "Hardcore Bank" ]
                ]
            ]
        ]


notFoundView : Document Msg
notFoundView =
    { title = "Not Found"
    , body =
        [ div [ class "not found" ]
            [ text "404 Not Found" ]
        ]
    }


accountListView : Document Msg
accountListView =
    { title = "My page"
    , body =
        [ div [ class "accounts" ]
            [ div [ class "row" ]
                [ div [ class "row-title" ]
                    [ h1 [ ]
                        [ text "Accounts" 
                        ]
                    , a [ href "/add" ]
                        [ button [ class "add" ]
                            [ text "Add" ]
                        ]
                    ]
                ]
            ]
        ]
    }


addView : Document Msg
addView =
    { title = "Create Account"
    , body =
        []
    }
