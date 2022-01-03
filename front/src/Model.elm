module Model exposing (..)

import Browser.Navigation as Nav
import Url
import Url.Parser
import Html exposing (a)
import Html exposing (address)


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , address : Maybe Address
    , addField : AddField
    }


type alias Address = String


type AddFieldType
    = SubjectField
    | DescriptionField
    | ContractAddressField
    | TargetAmountField
    | MonthlyRemittranceField

type alias AddField =
    { subject : String
    , description : String
    , contractAddress : Address
    , targetAmount : Float
    , monthlyRemittrance : Float
    , errors : List (AddFieldType, String)
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
