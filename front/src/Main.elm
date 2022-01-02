module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url

import Model exposing (Model)
import Html.Events exposing (onClick)


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
    { title = "Application Title"
    , body =
        [ navbar
        , main_ []
            [ accountListView
            ]
        ]
    }


navbar : Html Msg
navbar =
    header []
        [ nav []
            [ h1 [ class "logotext" ] [ text "Hardcore Bank" ]
            ]
        ]


accountListView : Html Msg
accountListView =
    div [ class "accounts" ]
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
