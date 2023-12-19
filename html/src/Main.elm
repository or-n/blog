module Main exposing (..)

import Animation
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Model exposing (..)
import Task
import Update exposing (..)
import Update.Image exposing (..)
import Update.Route exposing (..)
import Url
import View exposing (documentView)


type alias Flags =
    { path : String
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = documentView
        , subscriptions = subscriptions
        , onUrlChange = .path >> Load >> RouteMsg
        , onUrlRequest = UrlRequest >> RouteMsg
        }


init : Flags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model.init key
    , Cmd.batch
        [ loadNames
        , Task.perform (Load >> RouteMsg) (Task.succeed url.path)
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.route of
        ImageUpload data ->
            Animation.subscription (Animate >> ImageMsg) [ data.anim_scale, data.anim_alpha ]

        _ ->
            Sub.none
