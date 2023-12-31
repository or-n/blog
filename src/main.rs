use std::fs::*;
use warp::Filter;

pub mod post;
pub mod util;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    warp::serve(
        warp::fs::dir("html")
            .or(post::api())
            .or(warp::get().map(handle_end)),
    )
    .run(([127, 0, 0, 1], 3030))
    .await;
    Ok(())
}

fn handle_end() -> impl warp::Reply {
    let contents = read_to_string("html/index.html").unwrap();
    //let modified_html_content = contents.replace("__PATH_PARAM__", &path);
    warp::reply::html(contents)
}
