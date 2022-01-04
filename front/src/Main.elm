port module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url
import Url.Parser
import Html.Events exposing (onClick, onInput)
import Json.Encode
import Json.Decode
import BigInt

import Model exposing (..)
import Maybe exposing (andThen)



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
    ( Model key url Nothing [] Model.initAddfield , Cmd.none )


-- Ports
port createAccount : Json.Encode.Value -> Cmd msg
port created : (String -> msg) -> Sub msg

port getAccounts : () -> Cmd msg
port gotAccounts : (Json.Decode.Value -> msg) -> Sub msg


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | AddField AddFieldMsg
    | GotAccounts Json.Decode.Value


type AddFieldMsg
    = Subject String
    | Description String
    | ContractAddress String
    | TargetAmount String
    | MonthlyRemittrance String
    | Submit
    | Created String


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
            let
                cmd_ =  case Url.Parser.parse Model.routeParser url of
                    Just Index ->
                        getAccounts ()
                    _ ->
                        Cmd.none
            in
            ( { model | url = url }
            , cmd_
            )
        
        AddField subMsg ->
            let
                addField = model.addField
                (addField_, cmd_) = case subMsg of
                    Subject subject ->
                        ({ addField | subject = subject }, Cmd.none)
                    Description desc ->
                        ({ addField | description = desc }, Cmd.none)
                    ContractAddress ca ->
                        ({ addField | contractAddress = ca }, Cmd.none)
                    TargetAmount maybeTa ->
                        case String.toFloat maybeTa of
                            Just ta ->
                                ({ addField | targetAmount = ta }, Cmd.none)
                            Nothing ->
                                (addField, Cmd.none)
                    MonthlyRemittrance maybeMr ->
                        case String.toFloat maybeMr of
                            Just mr ->
                                ({ addField | monthlyRemittrance = mr }, Cmd.none)
                            Nothing ->
                                (addField, Cmd.none)
                    Submit ->
                        -- validate
                        let
                            errors = addFormValidate addField
                        in
                        if List.length errors == 0 then
                            ( { addField | errors = [], sending = True }
                            , createAccount <| Model.addFieldEncoder model.addField
                            )
                        else
                            ({ addField | errors = errors }, Cmd.none)
                    Created _ ->
                        (Model.initAddfield, Nav.pushUrl model.key "/")
            in
            ( { model | addField = addField_ }
            , cmd_
            )

        GotAccounts json ->
            let
                accounts = case Json.Decode.decodeValue accountsDecoder json of
                   Ok a -> a
                   Err x -> []
            in
            ( { model | accounts = accounts }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ created (\x -> AddField (Created x))
        , gotAccounts GotAccounts
        ]



-- View

view : Model -> Browser.Document Msg
view model =
    let
        subdoc = case Url.Parser.parse Model.routeParser model.url of
            Just Index ->
                accountListView model
            Just Add ->
                addView model
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


notFoundView : Browser.Document Msg
notFoundView =
    { title = "Not Found"
    , body =
        [ div [ class "not found" ]
            [ text "404 Not Found" ]
        ]
    }


accountListView : Model -> Browser.Document Msg
accountListView model =
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
                , div [ class "account-list" ]
                    (List.map accountView model.accounts)
                ]
            ]
        ]
    }


accountView : Account -> Html msg
accountView account =
    let
        current = case balanceToFloatStr 18 account.balance of
            Just x -> x
            Nothing -> "NA"
        target = case balanceToFloatStr 18 account.targetAmount of
            Just x -> x
            Nothing -> "NA"
        monthly = case balanceToFloatStr 18 account.monthlyRemittrance of
            Just x -> x
            Nothing -> "NA"
    in
    div [ class "account-block" ]
        [ p [ class "id" ] [ text <| "ID: " ++ account.id ]
        , h2 [] [ text account.subject ]
        , p [ class "description" ] [ text account.description ]
        , div [ class "balance" ]
            [ table []
                [ tbody []
                    [ tr []
                        [ td []
                            [ text "Balance:" ]
                        , td [ class "val" ]
                            [ span [ class "current" ] 
                                [ text current ]
                            , span [] [ text "/" ]
                            , span [ class "target" ] [ text target ]
                            , span [ class "token-symbol" ] [ text account.tokenSymbol ]
                            ]
                        ]
                    , tr []
                        [ td []
                            [ text "Monthly Remittrance:" ]
                        , td [ class "val" ]
                            [ text monthly
                            , span [ class "token-symbol" ] [ text account.tokenSymbol ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


addView : Model -> Browser.Document Msg
addView model =
    { title = "Create Account"
    , body =
        [ div [ class "add" ]
            [ div [ class "row" ]
                [ div [ class "row-title" ]
                    [ h1 []
                        [ text "Create Account" ]
                    ]
                , div [ class "form" ]
                    [ label [ for "subject" ] [ text "Subject" ]
                    , input
                        [ id "subject", type_ "text"
                        , value model.addField.subject
                        , onInput <| (\x -> AddField <| Subject x)
                        ]
                        []
                    , case List.filter (\(f, _) -> f == Model.SubjectField) model.addField.errors of
                        [] ->
                            p [] []
                        (_, e) :: _ ->
                            p [ class "error" ] [ text e ]
                    , label [ for "description" ] [ text "Description" ]
                    , input
                        [ id "description", type_ "text"
                        , value model.addField.description
                        , onInput <| (\x -> AddField <| Description x)
                        ]
                        []
                    , case List.filter (\(f, _) -> f == Model.DescriptionField) model.addField.errors of
                        [] ->
                            p [] []
                        (_, e) :: _ ->
                            p [ class "error" ] [ text e ]
                    , label [ for "contract-address" ] [ text "Token Contract Address" ]
                    , input
                        [ id "contract-address", type_ "text"
                        , value model.addField.contractAddress
                        , onInput <| (\x -> AddField <| ContractAddress x)
                        ]
                        []
                    , case List.filter (\(f, _) -> f == Model.ContractAddressField) model.addField.errors of
                        [] ->
                            p [] []
                        (_, e) :: _ ->
                            p [ class "error" ] [ text e ]
                    , label [ for "target-amount", class "small" ] [ text "Target Amount" ]
                    , input
                        [ id "target-amount", type_ "number"
                        , value <| String.fromFloat model.addField.targetAmount
                        , step "0.00001"
                        , onInput <| (\x -> AddField <| TargetAmount x)
                        ]
                        []
                    , case List.filter (\(f, _) -> f == Model.TargetAmountField) model.addField.errors of
                        [] ->
                            p [] []
                        (_, e) :: _ ->
                            p [ class "error" ] [ text e ]
                    , label [ for "monthly-remittrance", class "small" ] [ text "Monthly Remittrance" ]
                    , input
                        [ id "monthly-remittrance", type_ "number"
                        , value <| String.fromFloat model.addField.monthlyRemittrance
                        , step "0.00001"
                        , onInput <| (\x -> AddField <| MonthlyRemittrance x)
                        ]
                        []
                    , case List.filter (\(f, _) -> f == Model.MonthlyRemittranceField) model.addField.errors of
                        [] ->
                            p [] []
                        (_, e) :: _ ->
                            p [ class "error" ] [ text e ]
                    , button [ class "submit", onClick <| AddField Submit ]
                        [ text "Create" ]
                    ]
                ]
            ]
        ]
    }




balanceToFloatStr : Int -> String -> Maybe String
balanceToFloatStr decimal strBalance =
    let
        d = BigInt.pow (BigInt.fromInt 10) (BigInt.fromInt decimal)
    in
    BigInt.fromIntString strBalance
        |> andThen (\x -> Just <| BigInt.div x d)
        |> andThen (\x -> Just <| BigInt.toString x)
        |> andThen (\x -> Just <| x ++ "." ++ (String.slice (String.length x) (String.length strBalance) strBalance))
        |> andThen (\x -> Just <| dropRightZero x)
        |> andThen (\x -> Just <| if String.endsWith "." x then x ++ "0" else x )


dropRightZero : String -> String
dropRightZero str =
    if String.length str == 0 then str else
    case String.slice ((String.length str)-1) (String.length str) str of
        "0" ->
            dropRightZero <| String.slice 0 ((String.length str)-1) str
        _ ->
            str