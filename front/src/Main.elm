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
    ( Model key url Nothing [] Model.initAddfield Model.initDepositField , Cmd.none )


-- Ports
port createAccount : Json.Encode.Value -> Cmd msg
port created : (String -> msg) -> Sub msg

port getAccounts : () -> Cmd msg
port gotAccounts : (Json.Decode.Value -> msg) -> Sub msg

port getTokenBalance : Address -> Cmd msg
port gotTokenBalance : (String -> msg) -> Sub msg

port deposit : Json.Encode.Value -> Cmd msg
port depositDone : (Bool -> msg) -> Sub msg

port withdraw : String -> Cmd msg  -- id
port withdrawDone : (Bool -> msg) -> Sub msg


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | AddField AddFieldMsg
    | GotAccounts Json.Decode.Value
    | DepositField DepositFieldMsg
    | WithdrawField WithdrawMsg


type AddFieldMsg
    = Subject String
    | Description String
    | ContractAddress String
    | TargetAmount String
    | MonthlyRemittrance String
    | Submit
    | Created String


type DepositFieldMsg
    = GotTokenBalance String
    | Amount String
    | DepositSubmit String  -- id
    | DepositDone Bool


type WithdrawMsg
    = Withdraw String  -- id
    | WithdrawDone Bool 


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
                    Just (Deposit id) ->
                        let
                            maybeAccount = 
                                List.filter (\x -> x.id == id) model.accounts
                                    |> List.head
                        in
                        case maybeAccount of
                            Just account -> getTokenBalance account.contractAddress
                            Nothing -> Cmd.none
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

        DepositField submsg ->
            case submsg of
                GotTokenBalance balance ->
                    let
                        depositField = model.depositField
                        depositField_ = { depositField | tokenBalance = balance }
                    in
                    ( { model | depositField = depositField_ }
                    , Cmd.none
                    )
                Amount amount ->
                    let
                        depositField = model.depositField
                        floatAmount = String.toFloat amount
                        depositField_ = case floatAmount of
                            Just a ->
                                { depositField | amountError = Nothing, value = a }
                            Nothing ->
                                { depositField | amountError = Just "Incorrect number." } 
                    in
                    ( { model | depositField = depositField_}
                    , Cmd.none
                    )
                
                DepositSubmit id ->
                    let
                        maybeAccount =
                            List.filter (\a -> a.id == id) model.accounts |> List.head
                    in
                    case maybeAccount of
                        Just account ->
                            ( model
                            , deposit <| depositEncoder account.contractAddress id model.depositField.value
                            )
                        Nothing ->
                            (model, Cmd.none)
                
                DepositDone result ->
                    let
                        depositField = model.depositField  
                    in
                    if result then
                        ( { model | depositField = initDepositField }
                        , Nav.pushUrl model.key "/"
                        )
                    else
                        ( { model | depositField = { depositField | result = result } }
                        , Cmd.none
                        )

        WithdrawField submsg ->
            case submsg of
                Withdraw id ->
                    ( model
                    , withdraw id
                    )
                WithdrawDone result ->
                    if result then
                        ( model
                        , Nav.pushUrl model.key "/"
                        )
                    else
                        (model, Cmd.none)



subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ created (\x -> AddField (Created x))
        , gotAccounts GotAccounts
        , gotTokenBalance (\x -> DepositField (GotTokenBalance x))
        , depositDone (\x -> DepositField (DepositDone x))
        , withdrawDone (\x -> WithdrawField (WithdrawDone x))
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
            Just (Deposit id) ->
                let
                    maybeAccount =
                        List.filter (\a -> a.id == id) model.accounts
                            |> List.head
                in
                case maybeAccount of
                    Just account -> depositView model account
                    Nothing -> notFoundView
            Just (Model.Withdraw id) ->
                let
                    maybeAccount =
                        List.filter (\a -> a.id == id) model.accounts
                            |> List.head
                in
                case maybeAccount of
                    Just account -> withdrawView model account
                    Nothing -> notFoundView
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


accountView : Account -> Html Msg
accountView account =
    div [ class "account-block" ]
        [ p [ class "id" ] [ text <| "ID: " ++ account.id ]
        , h2 [] [ text account.subject ]
        , p [ class "description" ] [ text account.description ]
        , div [ class "balance" ]
            [ balanceView account
            , div []
                [ a [ href <| "/deposit/" ++ account.id ]
                    [ button []
                        [ text "Deposit" ]
                    ]
                , a [ href <| "/withdraw/" ++ account.id ]
                    [ button []
                        [ text "Withdraw" ]
                    ]
                ]
            ]
        ]

balanceView : Account -> Html msg
balanceView account =
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
    table []
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


depositView : Model -> Account -> Browser.Document Msg
depositView model account =
    let
        tokenBalance = 
            case balanceToFloatStr 18 model.depositField.tokenBalance of
                Just x -> x
                Nothing -> "NA"
    in
    { title = "Deposit"
    , body =
        [ div [ class "deposit" ]
            [ div [ class "row" ]
                [ div [ class "row-title" ]
                    [ h1 []
                        [ text <| "Deposit #" ++ account.id  ]
                    ]
                , div [ class "form" ]
                    [ h2 [] [ text account.subject ]
                    , p [] [ text account.description ]
                    , balanceView account
                    , div [ class "border" ]
                        [ div [ class "token-balance" ]
                            [ p []
                                [ text <| account.tokenName ++ " balance: " ++ tokenBalance ++ " " ++ account.tokenSymbol ]
                            ]
                        , div [ class "send" ]
                            [ label [ for "value" ] [ text "Amount: " ]
                            , input 
                                [ id "value", type_ "number"
                                , step "0.00001"
                                , value <| String.fromFloat model.depositField.value
                                , onInput (\x -> DepositField (Amount x))
                                ] []
                            , button [ class "submit", onClick <| DepositField (DepositSubmit account.id) ]
                                [ text "Send" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    }



withdrawView : Model -> Account -> Browser.Document Msg
withdrawView model account =
    let
        isBig =
            case BigInt.fromIntString account.targetAmount of
                Just target ->
                    case BigInt.fromIntString account.balance of
                        Just balance ->
                            BigInt.gte balance target
                        Nothing -> False
                Nothing -> False

        submitButtonClass = 
            if isBig then
                [ class "submit", onClick <| WithdrawField <| Withdraw account.id ]
            else
                [ class "submit",  class "disabled" ]

    in
    { title = "Withdraw"
    , body = 
        [ div [ class "withdraw" ]
            [ div [ class "row" ]
                [ div [ class "row-title" ]
                    [ h1 []
                        [ text <| "Deposit #" ++ account.id  ]
                    ]
                , div [ class "form" ]
                    [ h2 [] [ text account.subject ]
                    , p [] [ text account.description ]
                    , balanceView account
                    , button submitButtonClass
                        [ text "Withdraw" ]
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
