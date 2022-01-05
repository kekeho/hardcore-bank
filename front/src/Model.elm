module Model exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser exposing ((</>))
import Html exposing (a)
import Html exposing (address)
import Json.Encode
import Json.Decode
import Json.Decode.Pipeline exposing (required)


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , address : Maybe Address
    , accounts : List Account
    , addField : AddField
    , depositField : DepositField
    }


type alias Address = String


type AddFieldType
    = SubjectField
    | DescriptionField
    | ContractAddressField
    | TargetAmountField
    | MonthlyRemittranceField


type alias Account =
    { id : String
    , subject : String
    , description : String
    , contractAddress : Address
    , tokenName : String
    , tokenSymbol : String
    , targetAmount : String  -- big int
    , monthlyRemittrance : String  -- big int
    , created : Int  -- timestamp
    , balance : String -- big int
    }


type alias AddField =
    { subject : String
    , description : String
    , contractAddress : Address
    , targetAmount : Float
    , monthlyRemittrance : Float
    , errors : List (AddFieldType, String)
    , sending : Bool
    }


type alias DepositField =
    { value : Float
    , tokenBalance : String
    , amountError : Maybe String
    , result : Bool
    }


initAddfield : AddField
initAddfield =
    AddField
        ""
        ""
        ""
        0.0
        0.0
        []
        False


initDepositField : DepositField
initDepositField =
    DepositField 0.0 "0" Nothing True


-- Func

addFormValidate : AddField -> List (AddFieldType, String)
addFormValidate field =
    List.filterMap 
        (\x -> x)
        [ validateStringLength SubjectField field.subject
        , validateStringLength DescriptionField field.description
        , validateContractAddress field.contractAddress
            |> (\(b, s) -> if b then Nothing else Just (ContractAddressField, s))
        , validateMin TargetAmountField 0.0 field.targetAmount
        , validateMin MonthlyRemittranceField 0.0 field.monthlyRemittrance
        ]


validateMin : AddFieldType -> Float -> Float -> Maybe (AddFieldType, String)
validateMin field min val =
    if val > min then
        Nothing
    else
        Just (field, "Value must be greater than " ++ String.fromFloat min)


validateStringLength : AddFieldType -> String -> Maybe (AddFieldType, String)
validateStringLength field str =
    if String.length str == 0 then
        Just (field, "The length of the string must be greater than or equal to 1.")
    else
        Nothing


validateContractAddress : Address -> (Bool, String)
validateContractAddress address =
    if String.length address /= 42 then
        (False, "The contract address must be 42 characters long.")
    else
        case String.slice 0 2 address of
            "0x" ->
                if onlyHex <| String.slice 2 (String.length address) address then                   
                    (True, "")
                else
                    (False, "The contract address should be in hexadecimal notation.")
            _ ->
                (False, "The beginning of the contract address should be \"0x\".")
        

isJust : Maybe a -> Bool
isJust maybe =
    case maybe of
        Just x ->
            True
        Nothing ->
            False


onlyHex : String -> Bool
onlyHex str =
    if String.length str == 0 then
        True
    else
        let 
            head =
                String.slice 0 1 str
                    |> String.toLower
        in
        if String.contains head "0123456789abcdef" then
            onlyHex <| String.slice 1 (String.length str) str
        else
            False
           

-- Json

addFieldEncoder : AddField -> Json.Encode.Value
addFieldEncoder addfield =
    Json.Encode.object
        [ ( "subject", Json.Encode.string addfield.subject )
        , ( "description", Json.Encode.string addfield.description )
        , ( "tokenContractAddress", Json.Encode.string addfield.contractAddress )
        , ( "targetAmount", Json.Encode.string <| toStr 18 addfield.targetAmount )
        , ( "monthlyRemittrance", Json.Encode.string <| toStr 18 addfield.monthlyRemittrance )
        ]


accountsDecoder : Json.Decode.Decoder (List Account)
accountsDecoder =
    Json.Decode.list accountDecoder


accountDecoder : Json.Decode.Decoder Account
accountDecoder =
    Json.Decode.succeed Account
        |> required "id" Json.Decode.string
        |> required "subject" Json.Decode.string
        |> required "description" Json.Decode.string
        |> required "contractAddress" Json.Decode.string
        |> required "tokenName" Json.Decode.string
        |> required "tokenSymbol" Json.Decode.string
        |> required "targetAmount" Json.Decode.string
        |> required "monthlyRemittrance" Json.Decode.string
        |> required "created" Json.Decode.int
        |> required "balance" Json.Decode.string


depositEncoder : Address -> String -> Float -> Json.Encode.Value
depositEncoder contractAddr id amount =
    Json.Encode.object
        [ ("tokenContractAddress", Json.Encode.string contractAddr)
        , ("amount", Json.Encode.string <| toStr 18 amount)
        , ("id", Json.Encode.string id)
        ]


-- Route

type Route
    = Index
    | Add
    | Deposit String


routeParser: Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map Index Url.Parser.top
        , Url.Parser.map Add (Url.Parser.s "add")
        , Url.Parser.map Deposit (Url.Parser.s "deposit" </> Url.Parser.string)
        ]


-- Function

toStr : Int -> Float -> String
toStr decimal val =
    let
        dotIndex =
            case (String.fromFloat val |> String.reverse |> String.indexes "." |> List.head) of
               Just idx -> idx
               Nothing -> 0
        plainVal = String.fromFloat val |> String.replace "." ""
    in
    plainVal ++ (String.repeat (decimal - dotIndex) "0")
