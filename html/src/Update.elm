module Update exposing (..)

import Http
import Json.Decode exposing (list, string, succeed, andThen)
import Model exposing (..)
import Task
import Update.Edit exposing (..)
import Update.Image exposing (..)
import Update.Route exposing (..)
import Url


loadNames =
    Http.get
        { url = "/files/"
        , expect = Http.expectJson MetaLoaded (list (list string))
        }

pair a b =
    a |> andThen (\a_value -> b |> andThen (\b_value -> succeed (a_value, b_value)))


type Msg
    = ImageMsg ImageMsg
    | EditMsg EditMsg
    | Delete String
    | Deleted (Result Http.Error String)
    | MetaLoaded (Result Http.Error (List (List String)))
    | NoOp
    | RouteMsg RouteMsg
    | Edit String
    | FileContentLoaded String (Result Http.Error String)


internal path =
    { protocol = Url.Https
    , host = ""
    , port_ = Nothing
    , path = path
    , query = Nothing
    , fragment = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ImageMsg m ->
            case model.route of
                ImageUpload data ->
                    let
                        ( new_data, new_shared, cmd ) =
                            update_image m data model.shared
                    in
                    ( { route = ImageUpload new_data, shared = new_shared }
                    , Cmd.map ImageMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        EditMsg m ->
            case model.route of
                EditFile data ->
                    let
                        ( new_data, new_shared, cmd ) =
                            update_edit m data model.shared
                    in
                    ( { model | route = EditFile new_data }
                        |> update_shared (\_ -> new_shared)
                    , Cmd.map EditMsg cmd
                    )

                _ ->
                    ( model, Cmd.none )

        Delete name ->
            ( model
            , Http.post
                { url = "del/" ++ name
                , body = Http.emptyBody
                , expect = Http.expectString Deleted
                }
            )

        Deleted result ->
            case result of
                Ok _ ->
                    ( model
                    , Cmd.batch
                        [ loadNames
                        , Task.perform
                            (InternalUrlRequest >> RouteMsg)
                            (Task.succeed (internal "/"))
                        ]
                    )

                Err e ->
                    ( model
                        |> update_shared (set_error (Just (showError e)))
                    , Cmd.none
                    )

        RouteMsg m ->
            let
                ( new, cmd ) =
                    update_route m model
            in
            ( new, cmd |> Cmd.map RouteMsg )

        MetaLoaded result ->
            case result of
                Ok list_meta ->
                    let
                        meta = list_meta
                            |> List.map to_pair

                        to_pair xs = case xs of
                            [a, b] -> (a, b)
                            _ -> ("", "")
                    in
                    ( model
                        |> update_shared (\shared -> { shared | meta = Just meta })
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        Edit name ->
            ( model
            , Http.request
                { method = "PUT"
                , headers = []
                , url = "file/" ++ name ++ ".md"
                , body = Http.emptyBody
                , expect = Http.expectString (FileContentLoaded name)
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        FileContentLoaded name result ->
            case result of
                Ok content ->
                    let
                        route =
                            { initial_title = Just name
                            , title = name
                            , content = content
                            }
                                |> EditFile
                    in
                    ( { model | route = route }, Cmd.none )

                _ ->
                    ( { model | route = NotFound }, Cmd.none )
