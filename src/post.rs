use crate::{route, util::*};
use std::fs::*;
use warp::{http::StatusCode, path, Filter};

const ROOT: &str = "files";

pub fn api() -> route!(impl warp::Reply) {
    let list_metadata = path("files")
        .and(path::end())
        .and(warp::get())
        .and_then(handle_list_metadata);
    let view_html = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::get())
        .map(handle_view_html);
    let view_markdown = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::put())
        .map(handle_view_markdown);
    let create = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::post())
        .and(string_filter(1_000_1000))
        .map(handle_create);
    let delete = path("del")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::post())
        .map(handle_delete);
    list_metadata
        .or(view_html)
        .or(view_markdown)
        .or(create)
        .or(delete)
}

async fn handle_list_metadata() -> Result<impl warp::Reply, warp::Rejection> {
    let names = file_names(ROOT).map_err(|_| warp::reject())?;
    Ok(warp::reply::json(&names))
}

fn handle_view_html(path: String) -> impl warp::Reply {
    let contents = read_to_string(format!("{ROOT}/{}", &path)).expect(path.as_str());
    let markdown = render_markdown(contents.as_str());
    warp::reply::html(markdown)
}

fn handle_view_markdown(path: String) -> impl warp::Reply {
    let contents = read_to_string(format!("{ROOT}/{}", &path)).expect(path.as_str());
    warp::reply::html(contents)
}

#[derive(Debug)]
struct FileCreationError;

impl warp::reject::Reject for FileCreationError {}

fn handle_create(path: String, body: String) -> impl warp::Reply {
    let full_path = format!("{ROOT}/{}.md", &path);
    match File::create(&full_path) {
        Ok(_) => {
            std::fs::write(&full_path, &body).unwrap();
            println!("content: {}", body);
            warp::reply::with_status(
                format!("File saved successfully at path: \"{}\"", path),
                StatusCode::CREATED,
            )
        }
        Err(_) => warp::reply::with_status(
            format!("Error saving file at path: \"{}\"", path),
            StatusCode::INTERNAL_SERVER_ERROR,
        ),
    }
}

fn handle_delete(path: String) -> impl warp::Reply {
    std::fs::remove_file(format!("{ROOT}/{}.md", &path)).unwrap();
    warp::reply::with_status(
        format!("Deleted file at path: \"{}\"", path),
        StatusCode::OK,
    )
}
