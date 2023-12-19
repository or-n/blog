use bytes::Bytes;
use pulldown_cmark::{html, Options, Parser};
use std::fs::*;
use std::path::PathBuf;
use warp::{http::StatusCode, path, Filter};

macro_rules! route {
    ($x:ty) => (impl Filter<Extract = ($x,), Error = warp::Rejection> + Clone)
}

fn html() -> route!(impl warp::Reply) {
    warp::fs::dir("html")
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    warp::serve(html().or(api()))
        .run(([127, 0, 0, 1], 3030))
        .await;
    Ok(())
}

fn api() -> route!(impl warp::Reply) {
    let metadata = path("files")
        .and(path::end())
        .and(warp::get())
        .and_then(handle_metadata);
    let view = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::get())
        .map(handle_file_view);
    let create = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::post())
        .and(string_filter(1_000_1000))
        .map(handle_file_create);
    let edit = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::put())
        .map(handle_file_edit);
    let delete = path("del")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::post())
        .map(handle_file_delete);
    let file = view.or(create).or(edit).or(delete);
    let end = warp::path::param().and(warp::get()).map(handle_end);
    metadata.or(file).or(end)
}

fn handle_file_view(path: String) -> impl warp::Reply {
    let contents = read_to_string("files/".to_owned() + &path).expect(path.as_str());
    let markdown = render_markdown(contents.as_str());
    warp::reply::html(markdown)
}

#[derive(Debug)]
struct FileCreationError;

impl warp::reject::Reject for FileCreationError {}

fn handle_file_create(path: String, body: String) -> impl warp::Reply {
    let full_path = format!("files/{}.md", &path);
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

fn handle_file_edit(path: String) -> impl warp::Reply {
    let contents = read_to_string("files/".to_owned() + &path).expect(path.as_str());
    warp::reply::html(contents)
}

fn handle_file_delete(path: String) -> impl warp::Reply {
    std::fs::remove_file(format!("files/{}.md", &path)).unwrap();
    warp::reply::with_status(
        format!("Deleted file at path: \"{}\"", path),
        StatusCode::OK,
    )
}

pub fn string_filter(
    limit: u64,
) -> impl Filter<Extract = (String,), Error = warp::Rejection> + Clone {
    warp::body::content_length_limit(limit)
        .and(warp::filters::body::bytes())
        .and_then(convert_to_string)
}

async fn convert_to_string(bytes: Bytes) -> Result<String, warp::Rejection> {
    String::from_utf8(bytes.to_vec()).map_err(|_| warp::reject())
}

fn handle_end(path: String) -> impl warp::Reply {
    let contents = read_to_string("html/index.html").unwrap();
    //let modified_html_content = contents.replace("__PATH_PARAM__", &path);
    warp::reply::html(contents)
}

async fn handle_metadata() -> Result<impl warp::Reply, warp::Rejection> {
    let root = "files/";
    let entries = std::fs::read_dir(root).map_err(|_| warp::reject())?;
    let mut pairs: Vec<_> = entries
        .filter_map(|entry| {
            entry.ok().and_then(|e| {
                e.metadata()
                    .ok()
                    .map(|m| (e.file_name().into_string().unwrap(), m))
            })
        })
        .collect();
    pairs.sort_by(|a, b| b.1.modified().unwrap().cmp(&a.1.modified().unwrap()));
    let names: Vec<String> = pairs
        .into_iter()
        .filter_map(|(s, _)| {
            if s.ends_with(".md") {
                Some(s[..s.len() - 3].to_string())
            } else {
                None
            }
        })
        .collect();
    Ok(warp::reply::json(&names))
}

fn render_markdown(markdown: &str) -> String {
    let parser = Parser::new_ext(markdown, Options::all());
    let mut html_output = String::new();
    html::push_html(&mut html_output, parser);
    html_output
}
